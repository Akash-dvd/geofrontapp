/// Build-time configuration flags for conditional compilation
/// These flags are set via --dart-define during build/run
class BuildFlags {
  BuildFlags._();

  /// Whether to use Directus as the data backend (local development)
  /// When false, uses Hasura+Supabase (cloud/production)
  ///
  /// Set via: flutter run --dart-define=USE_DIRECTUS=false (for cloud)
  /// Development default is true (local Directus)
  /// For production: explicitly set --dart-define=USE_DIRECTUS=false
  static const bool useDirectus = bool.fromEnvironment(
    'USE_DIRECTUS',
    defaultValue: true, // Default to local Directus for development
  );

  /// Helper to check if running in cloud mode
  static bool get isCloudMode => !useDirectus;

  /// Helper to check if running in local mode
  static bool get isLocalMode => useDirectus;
}
