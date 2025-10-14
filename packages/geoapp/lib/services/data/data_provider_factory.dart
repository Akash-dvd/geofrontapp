import '../../config/build_flags.dart';
import 'data_provider.dart';
import 'directus_data_provider.dart';
import 'hasura_data_provider.dart';

/// Factory function to create the appropriate data provider
/// based on compile-time flags (USE_DIRECTUS)
/// 
/// In local mode: returns DirectusDataProvider
/// In cloud mode: returns HasuraDataProvider
/// 
/// The idToken parameter is the Firebase ID token from FirebaseAuthProvider
DataProvider createDataProvider({required String idToken}) {
  if (BuildFlags.useDirectus) {
    // Local development with Directus
    // This branch will be tree-shaken in production builds
    return DirectusDataProvider(idToken: idToken);
  } else {
    // Cloud/production with Hasura + Supabase
    return HasuraDataProvider(idToken: idToken);
  }
}
