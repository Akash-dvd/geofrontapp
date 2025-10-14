import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime environment configuration loaded from .env files
/// This provides access to secrets and URLs that vary between local/cloud
class EnvConfig {
  EnvConfig._();

  // App mode
  static String get appMode => dotenv.get('APP_MODE', fallback: 'local');
  static bool get isLocal => appMode == 'local';
  static bool get isCloud => appMode == 'cloud';

  // Firebase Authentication (required for both modes)
  static String get firebaseApiKey => dotenv.get('FIREBASE_API_KEY');
  static String get firebaseAuthDomain => dotenv.get('FIREBASE_AUTH_DOMAIN');
  static String get firebaseProjectId => dotenv.get('FIREBASE_PROJECT_ID');
  static String get firebaseStorageBucket =>
      dotenv.get('FIREBASE_STORAGE_BUCKET');
  static String get firebaseMessagingSenderId =>
      dotenv.get('FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseAppId => dotenv.get('FIREBASE_APP_ID');

  // Local Directus (only used in local mode)
  static String get directusUrl =>
      dotenv.get('DIRECTUS_URL', fallback: 'http://localhost:8055');
  static String? get directusToken => dotenv.maybeGet('DIRECTUS_TOKEN');

  // Cloud Hasura + Supabase (only used in cloud mode)
  static String get hasuraEndpoint =>
      dotenv.get('HASURA_GRAPHQL_ENDPOINT', fallback: '');
  static String? get hasuraAdminSecret =>
      dotenv.maybeGet('HASURA_ADMIN_SECRET');
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  static String? get supabaseServiceRoleKey =>
      dotenv.maybeGet('SUPABASE_SERVICE_ROLE_KEY');

  // Development flags
  static bool get keepTestData =>
      dotenv.get('KEEP_TEST_DATA', fallback: 'false').toLowerCase() == 'true';

  /// Validate that required environment variables are present
  static void validate() {
    // Always require Firebase config
    _require('FIREBASE_API_KEY');
    _require('FIREBASE_AUTH_DOMAIN');
    _require('FIREBASE_PROJECT_ID');

    if (isLocal) {
      _require('DIRECTUS_URL');
    } else if (isCloud) {
      _require('HASURA_GRAPHQL_ENDPOINT');
      _require('SUPABASE_URL');
      _require('SUPABASE_ANON_KEY');
    }
  }

  static void _require(String key) {
    if (!dotenv.isInitialized || dotenv.maybeGet(key) == null) {
      throw Exception('Missing required environment variable: $key');
    }
  }
}
