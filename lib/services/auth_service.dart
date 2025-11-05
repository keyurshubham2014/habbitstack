import 'package:flutter/material.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'cloud_user_service.dart';
import '../models/user.dart' as models;

class AuthService {
  final SupabaseClient _supabase = SupabaseService.instance.client;
  final CloudUserService _cloudUserService = CloudUserService();

  /// Check if user is logged in
  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      if (response.user == null) {
        throw Exception('Failed to create account. Please try again.');
      }

      // Create user profile in Supabase users table
      if (response.user != null) {
        await _ensureUserProfile(response.user!, name);
      }

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Login with email and password
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed. Please check your credentials.');
      }

      // Ensure user profile exists in Supabase users table
      if (response.user != null) {
        final name = response.user!.userMetadata?['name'] as String? ?? 'User';
        await _ensureUserProfile(response.user!, name);
      }

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      return await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.stackhabit://login-callback/',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Sign in with Apple (iOS only)
  Future<bool> signInWithApple() async {
    try {
      return await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.stackhabit://login-callback/',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Apple sign-in failed: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  /// Delete account (requires user to be logged in)
  Future<void> deleteAccount() async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('No user logged in');
    }

    try {
      // Delete all user data from Supabase
      // Due to CASCADE delete constraints, this will delete all related data
      await _supabase.from('users').delete().eq('id', userId);

      // Sign out
      await logout();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (metadata != null) updates.addAll(metadata);

      await _supabase.auth.updateUser(
        UserAttributes(data: updates),
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Check if email is verified
  bool get isEmailVerified {
    final user = currentUser;
    if (user == null) return false;
    return user.emailConfirmedAt != null;
  }

  /// Resend verification email
  Future<void> resendVerificationEmail() async {
    final email = currentUser?.email;
    if (email == null) {
      throw Exception('No email found for current user');
    }

    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to resend verification email: $e');
    }
  }

  /// Ensure user profile exists in Supabase users table
  /// This creates or updates the user profile after signup/login
  Future<void> _ensureUserProfile(User user, String name) async {
    try {
      // Check if user profile already exists
      final exists = await _cloudUserService.userExists(user.id);

      if (!exists) {
        // Create user profile
        await _cloudUserService.upsertUser(
          models.User(
            name: name,
            email: user.email ?? '',
            createdAt: DateTime.now(),
            premiumStatus: false,
          ),
          user.id,
        );
      }
    } catch (e) {
      // Log error but don't throw - user can still use the app
      // The profile will be created on next sync attempt
      debugPrint('Warning: Could not create user profile: $e');
    }
  }

  /// Handle Supabase auth exceptions with user-friendly messages
  Exception _handleAuthException(AuthException e) {
    switch (e.statusCode) {
      case '400':
        if (e.message.contains('User already registered')) {
          return Exception('This email is already registered. Please login instead.');
        }
        return Exception('Invalid request. Please check your input.');
      case '401':
        return Exception('Invalid email or password.');
      case '422':
        return Exception('Invalid email format or password too weak.');
      case '429':
        return Exception('Too many requests. Please try again later.');
      case '500':
        return Exception('Server error. Please try again later.');
      default:
        return Exception(e.message);
    }
  }
}
