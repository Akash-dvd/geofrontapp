import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'auth_provider.dart';

/// Firebase Authentication Provider
/// Single source of truth for authentication in both local and cloud modes
/// Supports: Email/Password, Google Sign-In, and Anonymous authentication
class FirebaseAuthProvider implements AuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn(); // TODO: Add when needed

  // ==================== Token & User Info ====================

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken(forceRefresh);
  }

  @override
  String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  @override
  String? get currentUserEmail {
    return _auth.currentUser?.email;
  }

  @override
  String? get currentUserDisplayName {
    return _auth.currentUser?.displayName;
  }

  @override
  bool get isAuthenticated {
    return _auth.currentUser != null;
  }

  @override
  bool get isAnonymous {
    return _auth.currentUser?.isAnonymous ?? false;
  }

  // ==================== Email/Password Authentication ====================

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    try {
      await user.updateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ==================== Google Sign-In ====================

  @override
  Future<void> signInWithGoogle() async {
    // TODO: Implement Google Sign-In when needed
    // Requires google_sign_in package
    throw UnimplementedError(
        'Google Sign-In not yet implemented - requires google_sign_in package');
  }

  // ==================== Anonymous Authentication ====================

  @override
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> linkAnonymousToEmailPassword(
      String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    if (!user.isAnonymous) {
      throw Exception('User is not anonymous');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> linkAnonymousToGoogle() async {
    // TODO: Implement Google linking when needed
    throw UnimplementedError(
        'Google linking not yet implemented - requires google_sign_in package');
  }

  // ==================== Sign Out ====================

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Note: Add _googleSignIn.signOut() when Google Sign-In is implemented
  }

  // ==================== State Management ====================

  @override
  Stream<String?> get authStateChanges {
    return _auth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Future<Map<String, dynamic>?> getUserMetadata() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'isAnonymous': user.isAnonymous,
      'isEmailVerified': user.emailVerified,
      'creationTime': user.metadata.creationTime?.toIso8601String(),
      'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
      'providers': user.providerData.map((p) => p.providerId).toList(),
    };
  }

  // ==================== Error Handling ====================

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}

/// Factory function to create the auth provider
/// Always returns Firebase auth provider (single source of truth)
AuthProvider createAuthProvider() {
  return FirebaseAuthProvider();
}
