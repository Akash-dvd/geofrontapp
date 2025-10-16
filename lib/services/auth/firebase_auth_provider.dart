import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'auth_provider.dart';

/// Firebase Authentication Provider
/// Single source of truth for authentication in both local and cloud modes
class FirebaseAuthProvider implements AuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  bool get isAuthenticated {
    return _auth.currentUser != null;
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Stream<String?> get authStateChanges {
    return _auth.authStateChanges().map((user) => user?.uid);
    throw UnimplementedError('Firebase Auth SDK integration pending');
  }
}

/// Factory function to create the auth provider
/// Always returns Firebase auth provider (single source of truth)
AuthProvider createAuthProvider() {
  return FirebaseAuthProvider();
}
