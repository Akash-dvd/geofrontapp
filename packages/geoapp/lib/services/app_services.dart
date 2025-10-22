import 'auth/auth_provider.dart';
import 'auth/supabase_auth_provider.dart';
import 'data/data_provider.dart';
import 'data/data_provider_factory.dart';

/// Global service locator for app-wide singletons
/// Initialized at app startup after Firebase and env config
class AppServices {
  AppServices._();

  static AuthProvider? _authProvider;
  static DataProvider? _dataProvider;

  /// Initialize app services
  /// Must be called after Supabase initialization and .env loading
  static Future<void> initialize() async {
    // 1. Create auth provider (Supabase across all modes)
    _authProvider = createAuthProvider();

    // 2. Get Supabase access token (or empty string if not authenticated yet)
  final accessToken = await _authProvider!.getIdToken() ?? '';

  // 3. Create data provider (Directus or edge gateway based on build flag)
  _dataProvider = createDataProvider(accessToken: accessToken);
  }

  /// Get the authentication provider instance
  static AuthProvider get auth {
    if (_authProvider == null) {
      throw StateError('AppServices not initialized. Call AppServices.initialize() first.');
    }
    return _authProvider!;
  }

  /// Get the data provider instance
  static DataProvider get data {
    if (_dataProvider == null) {
      throw StateError('AppServices not initialized. Call AppServices.initialize() first.');
    }
    return _dataProvider!;
  }

  /// Refresh data provider when auth state changes
  /// Call this when user signs in/out to update the data provider with new token
  static Future<void> refreshDataProvider() async {
    final accessToken = await _authProvider!.getIdToken() ?? '';
    _dataProvider = createDataProvider(accessToken: accessToken);
  }
}
