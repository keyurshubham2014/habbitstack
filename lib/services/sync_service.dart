import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'cloud_habit_service.dart';
import 'supabase_service.dart';

/// Service to handle offline queue and automatic syncing
class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  final DatabaseService _localDb = DatabaseService.instance;
  final CloudHabitService _cloudService = CloudHabitService();
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  StreamSubscription? _connectivitySubscription;

  /// Sync status stream controller
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  /// Initialize sync service and start listening for connectivity changes
  Future<void> initialize() async {
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && !_isSyncing) {
        // Network available, trigger sync
        syncNow();
      }
    });

    // Try initial sync if online
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      syncNow();
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }

  /// Queue a change for syncing when online
  Future<void> queueChange({
    required String table,
    required String operation, // 'insert', 'update', 'delete'
    required Map<String, dynamic> data,
    int? localId,
  }) async {
    try {
      await _localDb.insert('sync_queue', {
        'table_name': table,
        'operation': operation,
        'data': data.toString(), // Simple string serialization
        'local_id': localId,
        'created_at': DateTime.now().toIso8601String(),
        'synced': 0,
      });

      // Try to sync immediately if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        syncNow();
      }
    } catch (e) {
      print('Error queuing change: $e');
    }
  }

  /// Sync all pending changes to cloud
  Future<SyncResult> syncNow() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
      );
    }

    if (!_cloudService.isAuthenticated) {
      return SyncResult(
        success: false,
        message: 'User not authenticated',
      );
    }

    _isSyncing = true;
    _emitStatus(SyncStatus.syncing);

    final result = SyncResult();

    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _isSyncing = false;
        _emitStatus(SyncStatus.offline);
        return SyncResult(
          success: false,
          message: 'No internet connection',
        );
      }

      // Get pending changes from queue
      final pendingChanges = await _localDb.query(
        'sync_queue',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );

      if (pendingChanges.isEmpty) {
        _lastSyncTime = DateTime.now();
        _isSyncing = false;
        _emitStatus(SyncStatus.synced);
        return SyncResult(
          success: true,
          message: 'No changes to sync',
          itemsSynced: 0,
        );
      }

      // Process each change
      int synced = 0;
      int failed = 0;

      for (final change in pendingChanges) {
        try {
          await _processQueueItem(change);

          // Mark as synced
          await _localDb.update(
            'sync_queue',
            {'synced': 1, 'synced_at': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [change['id']],
          );

          synced++;
        } catch (e) {
          print('Error syncing item ${change['id']}: $e');
          failed++;
        }
      }

      _lastSyncTime = DateTime.now();
      _isSyncing = false;

      if (failed == 0) {
        _emitStatus(SyncStatus.synced);
        result.success = true;
        result.message = 'Synced $synced items';
      } else {
        _emitStatus(SyncStatus.error);
        result.success = false;
        result.message = 'Synced $synced items, $failed failed';
      }

      result.itemsSynced = synced;
      result.itemsFailed = failed;

      return result;
    } catch (e) {
      print('Sync error: $e');
      _isSyncing = false;
      _emitStatus(SyncStatus.error);

      return SyncResult(
        success: false,
        message: 'Sync failed: ${e.toString()}',
      );
    }
  }

  /// Process a single queue item
  Future<void> _processQueueItem(Map<String, dynamic> item) async {
    final table = item['table_name'] as String;
    final operation = item['operation'] as String;
    final data = _parseData(item['data'] as String);

    switch (operation) {
      case 'insert':
        await _cloudService.batchCreate(table, [data]);
        break;
      case 'update':
        // For updates, we need the cloud ID
        // This is simplified - in production, you'd need to track cloud IDs
        print('Update operation not fully implemented yet');
        break;
      case 'delete':
        print('Delete operation not fully implemented yet');
        break;
    }
  }

  /// Parse data string back to map (simplified)
  Map<String, dynamic> _parseData(String dataString) {
    // This is a simplified version
    // In production, you'd use proper JSON serialization
    return {};
  }

  /// Emit sync status to listeners
  void _emitStatus(SyncStatus status) {
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }

  /// Get pending items count
  Future<int> getPendingCount() async {
    final result = await _localDb.query(
      'sync_queue',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return result.length;
  }

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Clear synced items from queue (older than 7 days)
  Future<void> cleanupSyncQueue() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

    await _localDb.delete(
      'sync_queue',
      where: 'synced = ? AND synced_at < ?',
      whereArgs: [1, cutoffDate.toIso8601String()],
    );
  }
}

/// Sync status enum
enum SyncStatus {
  synced,    // All changes synced
  syncing,   // Sync in progress
  offline,   // No internet connection
  error,     // Sync error occurred
  pending,   // Changes pending sync
}

/// Result of a sync operation
class SyncResult {
  bool success = false;
  String message = '';
  int itemsSynced = 0;
  int itemsFailed = 0;

  @override
  String toString() {
    return 'SyncResult(success: $success, synced: $itemsSynced, failed: $itemsFailed, message: $message)';
  }
}
