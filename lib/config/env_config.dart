import 'package:geoapp/config/env_config.dart' as core;

/// App-level wrapper around the shared geoapp environment configuration.
class EnvConfig {
  EnvConfig._();

  static String get appMode => core.EnvConfig.appMode;
  static bool get isLocal => core.EnvConfig.isLocal;
  static bool get isCloud => core.EnvConfig.isCloud;

  static String get supabaseUrl => core.EnvConfig.supabaseUrl;
  static String get supabaseAnonKey => core.EnvConfig.supabaseAnonKey;
  static String? get supabaseServiceRoleKey => core.EnvConfig.supabaseServiceRoleKey;
  static String? get supabaseJwtSecret => core.EnvConfig.supabaseJwtSecret;
  static String get supabaseOauthRedirectUri => core.EnvConfig.supabaseOauthRedirectUri;
  static String get supabaseGoogleOAuthScopes => core.EnvConfig.supabaseGoogleOAuthScopes;
  static String get supabaseGithubOAuthScopes => core.EnvConfig.supabaseGithubOAuthScopes;
  static String get supabaseAuthCallbackHostname => core.EnvConfig.supabaseAuthCallbackHostname;

  static String get googleClientId => core.EnvConfig.googleClientId;
  static String get googleClientSecret => core.EnvConfig.googleClientSecret;
  static String get githubClientId => core.EnvConfig.githubClientId;
  static String get githubClientSecret => core.EnvConfig.githubClientSecret;

  static String get edgeGatewayUrl => core.EnvConfig.edgeGatewayBaseUrl;
  static String get edgeGraphqlEndpoint => core.EnvConfig.edgeGraphqlEndpoint;
  static String get edgeLlmEndpoint => core.EnvConfig.edgeLlmEndpoint;
  static String get edgeSolverEndpoint => core.EnvConfig.edgeSolverEndpoint;

  static String get directusUrl => core.EnvConfig.directusUrl;
  static String? get directusToken => core.EnvConfig.directusToken;

  static bool get keepTestData => _keepTestData;
  static const bool _keepTestData = false;

  static void validate() => core.EnvConfig.validate();

  static void printConfig() => core.EnvConfig.printConfig();
}
