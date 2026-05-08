import 'package:firebase_auth/firebase_auth.dart';

/// Handles all Firebase Auth operations.
/// Role is stored in Firestore under /users/{uid}/role  ('client' | 'admin')
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email & password
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) => _auth.signInWithEmailAndPassword(email: email, password: password);

  /// Create new client account
  static Future<UserCredential> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    return cred;
  }

  static Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Sign out
  static Future<void> signOut() => _auth.signOut();
}
