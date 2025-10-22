import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    }
    // Cloud/edge gateway
    return EnvConfig.edgeGraphqlEndpoint;
  }

  /// Create and configure GraphQL client with Supabase authentication
  /// Both Directus (optional) and the edge gateway use Bearer tokens
  static GraphQLClient createClient() {
    final HttpLink httpLink = HttpLink(_graphqlEndpoint);

    // Add Supabase authentication link
    final AuthLink authLink = AuthLink(
      getToken: () async {
        try {
          if (BuildFlags.useDirectus) {
            final directusToken = EnvConfig.directusToken;
            if (directusToken != null && directusToken.isNotEmpty) {
              return 'Bearer $directusToken';
            }
          }

          final auth = Supabase.instance.client.auth;
          var session = auth.currentSession;
          if (session == null) {
            debugPrint('⚠️ GraphQL AuthLink: No Supabase session available');
            return null;
          }

          final expiresAt = session.expiresAt;
          if (expiresAt != null) {
            final expiry =
                DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
            if (expiry.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
              try {
                final refreshResponse = await auth.refreshSession();
                session = refreshResponse.session ?? auth.currentSession;
                if (session == null) {
                  debugPrint('⚠️ GraphQL AuthLink: Session refresh failed');
                  return null;
                }
                debugPrint(
                    '♻️ GraphQL AuthLink: Refreshed Supabase access token');
              } catch (refreshError) {
                debugPrint(
                    '❌ GraphQL AuthLink: Failed to refresh session: $refreshError');
                return null;
              }
            }
          }

          debugPrint(
              '✅ GraphQL AuthLink: Using Supabase access token for ${session.user.id}');
          return 'Bearer ${session.accessToken}';
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
