import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/app_services.dart';
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
      return EnvConfig.directusUrl + '/graphql';
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
          // Get Firebase ID token from auth provider
          final idToken = await AppServices.auth.getIdToken();
          return idToken != null ? 'Bearer $idToken' : null;
        } catch (e) {
          // If not authenticated yet, return null
          // Directus can fall back to DIRECTUS_TOKEN in data provider
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
