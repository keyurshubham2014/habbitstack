import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();

  late final SupabaseClient client;
  bool _isInitialized = false;

  SupabaseService._init();

  /// Initialize Supabase with credentials from .env file
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load environment variables
      await dotenv.load(fileName: '.env');

      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (url == null || url.isEmpty || url == 'https://your-project-id.supabase.co') {
        throw Exception(
          'SUPABASE_URL not found in .env file.\n'
          'Please create a .env file in the project root with your Supabase credentials.\n'
          'See .env.example for template.',
        );
      }

      if (anonKey == null || anonKey.isEmpty || anonKey == 'your-anon-key-here') {
        throw Exception(
          'SUPABASE_ANON_KEY not found in .env file.\n'
          'Please add your Supabase anon key to the .env file.\n'
          'Get it from: https://supabase.com/dashboard/project/_/settings/api',
        );
      }

      // Initialize Supabase
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce, // More secure flow
        ),
        debug: true, // Enable debug mode for development
      );

      client = Supabase.instance.client;
      _isInitialized = true;

      print('✅ Supabase initialized successfully');
      print('📍 URL: $url');
    } catch (e) {
      print('❌ Error initializing Supabase: $e');
      rethrow;
    }
  }

  /// Check if Supabase is initialized
  bool get isInitialized => _isInitialized;

  /// Get current authenticated user
  User? get currentUser => client.auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;
}
