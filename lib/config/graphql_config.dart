import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

/// GraphQL client configuration for Strapi backend
/// Follows constitutional requirement for API communication
class GraphQLConfig {
  static const String _strapiEndpoint = 'http://localhost:1337/graphql';

  /// Create and configure GraphQL client
  static GraphQLClient createClient() {
    final HttpLink httpLink = HttpLink(_strapiEndpoint);

    // Add authentication link if needed
    final AuthLink authLink = AuthLink(
      getToken: () async {
        // TODO: Implement authentication token retrieval
        // This would typically get JWT token from secure storage
        return null;
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
        query: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
        ),
        mutate: Policies(
          fetch: FetchPolicy.networkOnly,
          error: ErrorPolicy.all,
        ),
      ),
    );
  }

  /// Create GraphQL provider widget
  static GraphQLProvider createProvider({
    required Widget child,
  }) {
    return GraphQLProvider(
      client: ValueNotifier(createClient()),
      child: child,
    );
  }
}