import 'build_flags.dart';

/// Compile-time environment configuration
/// All values are hardcoded constants - works on ALL platforms
/// No .env files needed - everything compiled into the app binary
///
/// To switch between local/cloud, change BuildFlags.useDirectus
/// For multiple environments, use --dart-define overrides
class EnvConfig {
  EnvConfig._();

  // ==================== Configuration Constants ====================
  // TODO: Replace these with your actual values

  // ==================== Firebase Authentication ====================
  // Get these from: Firebase Console → Project Settings → General
  // Same Firebase project used for both local and cloud modes

  static const String _firebaseApiKey =
      'AIzaSyBJY_qpHKvCZerJrXAuZ9kFWWJKzHqDq3c';
  static const String _firebaseAuthDomain =
      'aksharaintelligence-41f4a.firebaseapp.com';
  static const String _firebaseProjectId = 'aksharaintelligence-41f4a';
  static const String _firebaseStorageBucket =
      'aksharaintelligence-41f4a.firebasestorage.app';
  static const String _firebaseMessagingSenderId = '275958509983';
  static const String _firebaseAppId =
      '1:275958509983:web:dbb754249faa6e42b0cdaa';

  // ==================== Local Directus Backend ====================
  // Used when BuildFlags.useDirectus == true

  static const String _directusUrl = 'http://192.168.1.3:8055';
  static const String? _directusToken =
      null; // Optional: for local dev without auth

  // ==================== Cloud Hasura Backend ====================
  // Get these from: Hasura Cloud Console → Your Project
  // Used when BuildFlags.useDirectus == false

  static const String _hasuraEndpoint =
      'https://premium-turkey-36.hasura.app/v1/graphql';
  static const String? _hasuraAdminSecret =
      null; // Optional: for server-side operations

  // ==================== Cloud Supabase Storage ====================
  // Get these from: Supabase Dashboard → Project Settings → API
  // Used when BuildFlags.useDirectus == false

  static const String _supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String _supabaseAnonKey =
      'REDACTED'; // TODO: Add your Supabase anon key
  static const String? _supabaseServiceRoleKey =
      null; // Optional: server-side only

  // ==================== Public Getters ====================
  // These support --dart-define overrides for CI/CD flexibility

  static String get firebaseApiKey =>
      const String.fromEnvironment('FIREBASE_API_KEY',
          defaultValue: _firebaseApiKey);

  static String get firebaseAuthDomain =>
      const String.fromEnvironment('FIREBASE_AUTH_DOMAIN',
          defaultValue: _firebaseAuthDomain);

  static String get firebaseProjectId =>
      const String.fromEnvironment('FIREBASE_PROJECT_ID',
          defaultValue: _firebaseProjectId);

  static String get firebaseStorageBucket =>
      const String.fromEnvironment('FIREBASE_STORAGE_BUCKET',
          defaultValue: _firebaseStorageBucket);

  static String get firebaseMessagingSenderId =>
      const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID',
          defaultValue: _firebaseMessagingSenderId);

  static String get firebaseAppId =>
      const String.fromEnvironment('FIREBASE_APP_ID',
          defaultValue: _firebaseAppId);

  static String get directusUrl =>
      const String.fromEnvironment('DIRECTUS_URL', defaultValue: _directusUrl);

  static String? get directusToken => const String.fromEnvironment(
              'DIRECTUS_TOKEN',
              defaultValue: _directusToken ?? '')
          .isEmpty
      ? null
      : const String.fromEnvironment('DIRECTUS_TOKEN',
          defaultValue: _directusToken ?? '');

  static String get hasuraEndpoint =>
      const String.fromEnvironment('HASURA_GRAPHQL_ENDPOINT',
          defaultValue: _hasuraEndpoint);

  static String? get hasuraAdminSecret =>
      const String.fromEnvironment('HASURA_ADMIN_SECRET',
                  defaultValue: _hasuraAdminSecret ?? '')
              .isEmpty
          ? null
          : const String.fromEnvironment('HASURA_ADMIN_SECRET',
              defaultValue: _hasuraAdminSecret ?? '');

  static String get supabaseUrl =>
      const String.fromEnvironment('SUPABASE_URL', defaultValue: _supabaseUrl);

  static String get supabaseAnonKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: _supabaseAnonKey);

  static String? get supabaseServiceRoleKey =>
      const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY',
                  defaultValue: _supabaseServiceRoleKey ?? '')
              .isEmpty
          ? null
          : const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY',
              defaultValue: _supabaseServiceRoleKey ?? '');

  // ==================== App Mode ====================
  // Determined by BuildFlags.useDirectus

  static String get appMode => BuildFlags.useDirectus ? 'local' : 'cloud';
  static bool get isLocal => BuildFlags.useDirectus;
  static bool get isCloud => !BuildFlags.useDirectus;

  // ==================== Validation ====================

  /// Validate that required configuration is present
  /// Call this at app startup to fail fast if config is missing
  static void validate() {
    // Always require Firebase config
    _requireNotEmpty(firebaseApiKey, 'FIREBASE_API_KEY');
    _requireNotEmpty(firebaseAuthDomain, 'FIREBASE_AUTH_DOMAIN');
    _requireNotEmpty(firebaseProjectId, 'FIREBASE_PROJECT_ID');

    if (isLocal) {
      // Local mode: require Directus
      _requireNotEmpty(directusUrl, 'DIRECTUS_URL');
    } else if (isCloud) {
      // Cloud mode: require Hasura + Supabase
      _requireNotEmpty(hasuraEndpoint, 'HASURA_GRAPHQL_ENDPOINT');
      _requireNotEmpty(supabaseUrl, 'SUPABASE_URL');
      _requireNotEmpty(supabaseAnonKey, 'SUPABASE_ANON_KEY');
    }
  }

  static void _requireNotEmpty(String value, String name) {
    if (value.isEmpty || value.contains('YOUR_') || value.contains('your-')) {
      throw Exception(
        'Configuration error: $name not set!\n'
        'Update the constants in env_config.dart with your actual values.',
      );
    }
  }

  // ==================== Debug Info ====================

  /// Print current configuration (without secrets)
  /// Useful for debugging environment issues
  static void printConfig() {
    print('═════════════════════════════════════════');
    print('Environment Configuration');
    print('═════════════════════════════════════════');
    print('Mode: $appMode');
    print('Firebase Project: $firebaseProjectId');
    if (isLocal) {
      print('Directus URL: $directusUrl');
      print(
          'Directus Token: ${directusToken != null ? '***set***' : 'not set'}');
    } else {
      print('Hasura Endpoint: $hasuraEndpoint');
      print('Supabase URL: $supabaseUrl');
    }
    print('═════════════════════════════════════════');
  }
}
