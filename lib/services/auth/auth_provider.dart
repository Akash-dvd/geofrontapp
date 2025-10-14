/// Abstract authentication provider interface
/// All implementations must use Firebase Authentication
abstract class AuthProvider {
  /// Get the current user's Firebase ID token
  /// This token is used for authenticating requests to backends
  Future<String?> getIdToken({bool forceRefresh = false});

  /// Get the current user ID
  String? get currentUserId;

  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password);

  /// Sign out the current user
  Future<void> signOut();

  /// Listen to authentication state changes
  Stream<String?> get authStateChanges;
}
