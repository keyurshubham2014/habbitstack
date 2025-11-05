import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/sync_service.dart';

/// Widget to show sync status in the app
class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({super.key});

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  final SyncService _syncService = SyncService.instance;
  SyncStatus _currentStatus = SyncStatus.synced;

  @override
  void initState() {
    super.initState();
    _listenToSyncStatus();
  }

  void _listenToSyncStatus() {
    _syncService.syncStatus.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Manual sync trigger
        if (_currentStatus != SyncStatus.syncing) {
          _syncService.syncNow();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getStatusColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getStatusIcon(),
            const SizedBox(width: 6),
            Text(
              _getStatusText(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getStatusColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusIcon() {
    switch (_currentStatus) {
      case SyncStatus.synced:
        return Icon(
          Icons.cloud_done,
          size: 16,
          color: _getStatusColor(),
        );
      case SyncStatus.syncing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
          ),
        );
      case SyncStatus.offline:
        return Icon(
          Icons.cloud_off,
          size: 16,
          color: _getStatusColor(),
        );
      case SyncStatus.error:
        return Icon(
          Icons.error_outline,
          size: 16,
          color: _getStatusColor(),
        );
      case SyncStatus.pending:
        return Icon(
          Icons.cloud_upload,
          size: 16,
          color: _getStatusColor(),
        );
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.error:
        return 'Sync Error';
      case SyncStatus.pending:
        return 'Pending';
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.offline:
        return Colors.grey;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.pending:
        return Colors.orange;
    }
  }
}

/// Compact version for app bar
class SyncStatusBadge extends StatefulWidget {
  const SyncStatusBadge({super.key});

  @override
  State<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends State<SyncStatusBadge> {
  final SyncService _syncService = SyncService.instance;
  SyncStatus _currentStatus = SyncStatus.synced;

  @override
  void initState() {
    super.initState();
    _listenToSyncStatus();
  }

  void _listenToSyncStatus() {
    _syncService.syncStatus.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show if not synced
    if (_currentStatus == SyncStatus.synced) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: _getStatusIcon(),
        onPressed: () {
          if (_currentStatus != SyncStatus.syncing) {
            _syncService.syncNow();
          }
        },
        tooltip: _getStatusText(),
      ),
    );
  }

  Widget _getStatusIcon() {
    switch (_currentStatus) {
      case SyncStatus.synced:
        return const Icon(Icons.cloud_done, size: 20);
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.offline:
        return const Icon(Icons.cloud_off, size: 20, color: Colors.grey);
      case SyncStatus.error:
        return const Icon(Icons.error_outline, size: 20, color: Colors.red);
      case SyncStatus.pending:
        return const Icon(Icons.cloud_upload, size: 20, color: Colors.orange);
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case SyncStatus.synced:
        return 'All synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.offline:
        return 'Offline - changes will sync when online';
      case SyncStatus.error:
        return 'Sync error - tap to retry';
      case SyncStatus.pending:
        return 'Pending changes - tap to sync';
    }
  }
}
