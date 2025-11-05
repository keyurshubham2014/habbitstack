import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import 'supabase_service.dart';

/// Cloud-based user service using Supabase
/// Handles CRUD operations for user profiles in the cloud database
class CloudUserService {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Get current authenticated user's ID
  String? get _userId => _supabase.auth.currentUser?.id;

  /// Create or update user profile in Supabase
  /// This is typically called after successful signup/login
  Future<Map<String, dynamic>> upsertUser(models.User user, String authUserId) async {
    final data = {
      'id': authUserId, // Use Supabase auth user ID
      'name': user.name,
      'email': user.email ?? _supabase.auth.currentUser?.email,
      'premium_status': user.premiumStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      // Use upsert to handle both insert and update
      final result = await _supabase
          .from('users')
          .upsert(data)
          .select()
          .single();
      return result;
    } catch (e) {
      throw Exception('Failed to upsert user: $e');
    }
  }

  /// Get user profile from Supabase
  Future<Map<String, dynamic>?> getUser(String? userId) async {
    final id = userId ?? _userId;
    if (id == null) {
      throw Exception('User not authenticated');
    }

    try {
      final result = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();
      return result;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Get current authenticated user's profile
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return getUser(_userId);
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      // Add updated_at timestamp
      updates['updated_at'] = DateTime.now().toIso8601String();

      final result = await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return result;
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Update premium status
  Future<Map<String, dynamic>> updatePremiumStatus(
    String userId,
    bool isPremium, {
    DateTime? expiresAt,
  }) async {
    final updates = {
      'premium_status': isPremium,
      'premium_expires_at': expiresAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      final result = await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return result;
    } catch (e) {
      throw Exception('Failed to update premium status: $e');
    }
  }

  /// Delete user profile (should be called after auth deletion)
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .delete()
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Check if user profile exists in Supabase
  Future<bool> userExists(String userId) async {
    try {
      final result = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return result != null;
    } catch (e) {
      return false;
    }
  }
}
