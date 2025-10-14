import 'auth_provider.dart';

/// Firebase Authentication Provider
/// Single source of truth for authentication in both local and cloud modes
class FirebaseAuthProvider implements AuthProvider {
  // TODO: Initialize Firebase Auth SDK
  // import 'package:firebase_auth/firebase_auth.dart';
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    // TODO: Implement Firebase ID token retrieval
    // final user = _auth.currentUser;
    // if (user == null) return null;
    // return await user.getIdToken(forceRefresh);
    throw UnimplementedError('Firebase Auth SDK integration pending');
  }

  @override
  String? get currentUserId {
    // TODO: Return current user ID
    // return _auth.currentUser?.uid;
    throw UnimplementedError('Firebase Auth SDK integration pending');
  }

  @override
  bool get isAuthenticated {
    // TODO: Check if user is signed in
    // return _auth.currentUser != null;
    throw UnimplementedError('Firebase Auth SDK integration pending');
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    // TODO: Implement Firebase sign-in
    // await _auth.signInWithEmailAndPassword(email: email, password: password);
    throw UnimplementedError('Firebase Auth SDK integration pending');
  }

  @override
  Future<void> signOut() async {
    // TODO: Implement sign-out
    // await _auth.signOut();
    throw UnimplementedError('Firebase Auth SDK integration pending');
  }

  @override
  Stream<String?> get authStateChanges {
    // TODO: Stream user ID changes
    // return _auth.authStateChanges().map((user) => user?.uid);
    throw UnimplementedError('Firebase Auth SDK integration pending');
  }
}

/// Factory function to create the auth provider
/// Always returns Firebase auth provider (single source of truth)
AuthProvider createAuthProvider() {
  return FirebaseAuthProvider();
}
