import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'build_flags.dart';
import 'env_config.dart';

/// GraphQL client configuration for both Directus and Hasura backends
/// Uses Firebase ID token for authentication in both cases
/// Backend selection based on BuildFlags.useDirectus
class GraphQLConfig {
  /// Get the appropriate GraphQL endpoint based on build flag
  static String get _graphqlEndpoint {
    if (BuildFlags.useDirectus) {
      // Local Directus backend
      return '${EnvConfig.directusUrl}/graphql';
    } else {
      // Cloud Hasura backend
      return EnvConfig.hasuraEndpoint;
    }
  }

  /// Create and configure GraphQL client with Firebase authentication
  /// Both Directus and Hasura use Firebase ID token via Authorization header
  static GraphQLClient createClient() {
    final HttpLink httpLink = HttpLink(_graphqlEndpoint);

    // Add Firebase authentication link
    // Both backends expect: Authorization: Bearer <firebase_id_token>
    final AuthLink authLink = AuthLink(
      getToken: () async {
        try {
          // Get Firebase ID token directly from FirebaseAuth
          // (AppServices might not be initialized yet)
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            debugPrint('⚠️ GraphQL AuthLink: No user signed in');
            return null;
          }

          final idToken = await user.getIdToken();
          debugPrint('✅ GraphQL AuthLink: Got token for user ${user.uid}');
          return idToken != null ? 'Bearer $idToken' : null;
        } catch (e) {
          debugPrint('❌ GraphQL AuthLink error: $e');
          return null;
        }
      },
    );

    // Combine links
    final Link link = authLink.concat(httpLink);

    return GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
      defaultPolicies: DefaultPolicies(
        watchQuery: Policies(
          fetch: FetchPolicy.cacheAndNetwork,
          error: ErrorPolicy.all,
        ),
        query: Policies(fetch: FetchPolicy.networkOnly, error: ErrorPolicy.all),
        mutate: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
        ),
      ),
    );
  }

  /// Create GraphQL provider widget
  /// Automatically uses correct backend based on build flag
  static GraphQLProvider createProvider({required Widget child}) {
    return GraphQLProvider(client: ValueNotifier(createClient()), child: child);
  }
}
