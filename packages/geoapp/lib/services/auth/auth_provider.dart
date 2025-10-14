/// Abstract authentication provider interface
/// All implementations must use Firebase Authentication
/// Supports: Email/Password, Google Sign-In, and Anonymous authentication
abstract class AuthProvider {
  /// Get the current user's Firebase ID token
  /// This token is used for authenticating requests to backends
  Future<String?> getIdToken({bool forceRefresh = false});

  /// Get the current user ID
  String? get currentUserId;

  /// Get the current user's email (null for anonymous)
  String? get currentUserEmail;

  /// Get the current user's display name
  String? get currentUserDisplayName;

  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Check if user is signed in anonymously
  bool get isAnonymous;

  // ==================== Email/Password Authentication ====================

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password);

  /// Create a new account with email and password
  Future<void> createUserWithEmailAndPassword(String email, String password);

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Update user's email
  Future<void> updateEmail(String newEmail);

  /// Update user's password
  Future<void> updatePassword(String newPassword);

  // ==================== Google Sign-In ====================

  /// Sign in with Google account
  /// Opens Google Sign-In flow in browser/native UI
  Future<void> signInWithGoogle();

  // ==================== Anonymous Authentication ====================

  /// Sign in anonymously (no credentials required)
  /// Useful for guest access or temporary users
  Future<void> signInAnonymously();

  /// Link anonymous account to email/password credentials
  /// Converts anonymous user to permanent account
  Future<void> linkAnonymousToEmailPassword(String email, String password);

  /// Link anonymous account to Google account
  /// Converts anonymous user to Google-authenticated account
  Future<void> linkAnonymousToGoogle();

  // ==================== Sign Out ====================

  /// Sign out the current user
  Future<void> signOut();

  // ==================== State Management ====================

  /// Listen to authentication state changes
  /// Emits user ID when signed in, null when signed out
  Stream<String?> get authStateChanges;

  /// Get current user's metadata (creation time, last sign-in, etc.)
  Future<Map<String, dynamic>?> getUserMetadata();
}
