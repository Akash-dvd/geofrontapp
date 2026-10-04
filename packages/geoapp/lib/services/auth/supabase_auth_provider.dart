import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/env_config.dart';
import 'auth_provider.dart';

/// Supabase Authentication Provider
/// Single source of truth for authentication across all app modes.
/// Supports email/password and OAuth providers (e.g. Google) via Supabase Auth.
class SupabaseAuthProvider implements AuthProvider {
  SupabaseAuthProvider({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ==================== Token & User Info ====================

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        if (!forceRefresh) return null;
        return null;
      }
      if (forceRefresh) {
        final response = await _client.auth.refreshSession();
        return response.session?.accessToken ??
            _client.auth.currentSession?.accessToken;
      }
      return session.accessToken;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  String? get currentUserEmail => _client.auth.currentUser?.email;

  @override
  String? get currentUserDisplayName =>
      _client.auth.currentUser?.userMetadata?['full_name'] as String?;

  @override
  bool get isAuthenticated => _client.auth.currentSession != null;

  // ==================== Email/Password Authentication ====================

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: _resolveRedirectUri(),
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      await _client.auth.updateUser(UserAttributes(email: newEmail));
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  // ==================== Google Sign-In ====================

  @override
  Future<void> signInWithGoogle() async {
    final redirect = _resolveRedirectUri();
    final scopes = EnvConfig.supabaseGoogleOAuthScopes.trim();
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirect,
        scopes: scopes.isEmpty ? null : scopes,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> signInWithGithub() async {
    final redirect = _resolveRedirectUri();
    final scopes = EnvConfig.supabaseGithubOAuthScopes.trim();
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: redirect,
        scopes: scopes.isEmpty ? null : scopes,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  // ==================== Sign Out ====================

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ==================== State Management ====================

  @override
  Stream<String?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      return event.session?.user.id;
    });
  }

  @override
  Future<Map<String, dynamic>?> getUserMetadata() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final Object createdAt = user.createdAt;
    final Object? lastSignInAt = user.lastSignInAt;

    return {
      'id': user.id,
      'email': user.email,
      'createdAt': createdAt is DateTime
          ? createdAt.toIso8601String()
          : createdAt,
      'lastSignInAt': lastSignInAt is DateTime
          ? lastSignInAt.toIso8601String()
          : lastSignInAt,
      'appMetadata': user.appMetadata,
      'userMetadata': user.userMetadata,
    };
  }

  // ==================== Error Handling ====================

  String _mapAuthException(AuthException e) {
    final message = e.message.trim();
    if (message.isEmpty) {
      return 'Authentication error: ${e.statusCode ?? 'unknown'}';
    }
    return message;
  }

  String? _resolveRedirectUri() {
    if (kIsWeb) {
      final base = Uri.base;
      if (base.scheme.startsWith('http')) {
        // Always return to the app origin (not a nested path) so OAuth /
        // magic-link callbacks land on a host that owns the Flutter shell.
        return base.origin;
      }
    }
    final uri = EnvConfig.supabaseOauthRedirectUri;
    return uri.isEmpty ? null : uri;
  }
}

/// Factory function to create the auth provider
AuthProvider createAuthProvider() {
  return SupabaseAuthProvider();
}
