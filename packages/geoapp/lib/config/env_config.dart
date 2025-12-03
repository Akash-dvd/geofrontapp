import 'package:flutter/foundation.dart';

import 'build_flags.dart';

/// Compile-time environment configuration.
/// Values can be overridden with --dart-define at build time.
class EnvConfig {
  EnvConfig._();

  // ==================== Supabase Auth / Database ====================

  static const String _supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String _supabaseAnonKey =
    'REDACTED'; // replace before production
  static const String? _supabaseServiceRoleKey = null;
  static const String? _supabaseJwtSecret = null;
  static const String _supabaseOauthRedirectUri =
    'https://YOUR_PROJECT.supabase.co/auth/v1/callback';
  static const String _supabaseGoogleScopes = 'email profile';
  static const String _supabaseGithubScopes = 'read:user user:email';
  static const String _supabaseAuthCallbackHostname = 'login-callback';
  static const String _googleClientId =
    'REDACTED';
  static const String _googleClientSecret =
    'REDACTED';
  static const String _githubClientId = 'REDACTED';
  static const String _githubClientSecret =
    'REDACTED';

  // ==================== Edge Gateway / Cloudflare Worker ====================

  static const String _edgeGatewayUrl =
    'https://edge-gateway-production.akshara-intelligence.workers.dev';
  static const String _edgeGraphqlPath = '/graphql';
  static const String _edgeLlmPath = '/llm';
  static const String _edgeSolverDefault =
      'https://solver.aksharaintelligence.com/graphql';

  // ==================== Local Directus Backend ====================

  static const String _directusUrl = 'http://192.168.1.3:8055';
  static const String? _directusToken = null;

  // ==================== Public Getters ====================

  static String get supabaseUrl =>
      const String.fromEnvironment('SUPABASE_URL', defaultValue: _supabaseUrl);

  static String get supabaseAnonKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: _supabaseAnonKey);

  static String? get supabaseServiceRoleKey {
    const value = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: '');
    if (value.isEmpty) return _supabaseServiceRoleKey;
    return value;
  }

  static String? get supabaseJwtSecret {
    const value = String.fromEnvironment('SUPABASE_JWT_SECRET', defaultValue: '');
    if (value.isEmpty) return _supabaseJwtSecret;
    return value;
  }

  static String get supabaseOauthRedirectUri => const String.fromEnvironment(
    'SUPABASE_OAUTH_REDIRECT_URI',
    defaultValue: _supabaseOauthRedirectUri);

  static String get supabaseGoogleOAuthScopes => const String.fromEnvironment(
      'SUPABASE_GOOGLE_OAUTH_SCOPES',
      defaultValue: _supabaseGoogleScopes);

  static String get supabaseGithubOAuthScopes => const String.fromEnvironment(
    'SUPABASE_GITHUB_OAUTH_SCOPES',
    defaultValue: _supabaseGithubScopes);

  static String get googleClientId => const String.fromEnvironment(
        'GOOGLE_CLIENT_ID',
        defaultValue: _googleClientId,
      );

  static String get googleClientSecret => const String.fromEnvironment(
        'GOOGLE_CLIENT_SECRET',
        defaultValue: _googleClientSecret,
      );

  static String get githubClientId => const String.fromEnvironment(
        'GITHUB_CLIENT_ID',
        defaultValue: _githubClientId,
      );

  static String get githubClientSecret => const String.fromEnvironment(
        'GITHUB_CLIENT_SECRET',
        defaultValue: _githubClientSecret,
      );

  static String get supabaseAuthCallbackHostname => const String.fromEnvironment(
    'SUPABASE_AUTH_CALLBACK_HOSTNAME',
    defaultValue: _supabaseAuthCallbackHostname);

  static String get edgeGatewayBaseUrl => const String.fromEnvironment(
      'EDGE_GATEWAY_URL',
      defaultValue: _edgeGatewayUrl);

  static String get edgeGraphqlEndpoint => const String.fromEnvironment(
      'EDGE_GRAPHQL_ENDPOINT',
    defaultValue: '$_edgeGatewayUrl$_edgeGraphqlPath');

  static String get edgeLlmEndpoint => const String.fromEnvironment(
    'EDGE_LLM_ENDPOINT',
    defaultValue: '$_edgeGatewayUrl$_edgeLlmPath');

  static String get edgeSolverEndpoint => const String.fromEnvironment(
    'EDGE_SOLVER_ENDPOINT',
    defaultValue: _edgeSolverDefault,
  );

  static String get directusUrl =>
      const String.fromEnvironment('DIRECTUS_URL', defaultValue: _directusUrl);

  static String? get directusToken {
    const value = String.fromEnvironment('DIRECTUS_TOKEN', defaultValue: '');
    if (value.isEmpty) return _directusToken;
    return value;
  }

  // ==================== App Mode ====================

  static String get appMode => BuildFlags.useDirectus ? 'local' : 'cloud';
  static bool get isLocal => BuildFlags.useDirectus;
  static bool get isCloud => !BuildFlags.useDirectus;

  // ==================== Validation ====================

  static void validate() {
    _requireNotEmpty(supabaseUrl, 'SUPABASE_URL');
    _requireNotEmpty(supabaseAnonKey, 'SUPABASE_ANON_KEY');

    if (isLocal) {
      _requireNotEmpty(directusUrl, 'DIRECTUS_URL');
    } else if (isCloud) {
      _requireNotEmpty(edgeGraphqlEndpoint, 'EDGE_GRAPHQL_ENDPOINT');
    }
  }

  static void _requireNotEmpty(String value, String name) {
    if (value.isEmpty || value.contains('PLACEHOLDER')) {
      throw Exception(
        'Configuration error: $name not set!\n'
        'Update env_config.dart or supply a --dart-define override.',
      );
    }
  }


  // ==================== Debug Info ====================

  static void printConfig() {
    debugPrint('═════════════════════════════════════════');
    debugPrint('Environment Configuration');
    debugPrint('═════════════════════════════════════════');
    debugPrint('Mode: $appMode');
    debugPrint('Supabase URL: $supabaseUrl');
    if (isLocal) {
      debugPrint('Directus URL: $directusUrl');
      debugPrint(
          'Directus Token: ${directusToken != null ? '***set***' : 'not set'}');
    } else {
      debugPrint('Edge GraphQL Endpoint: $edgeGraphqlEndpoint');
    }
    debugPrint('═════════════════════════════════════════');
  }
}
