import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Note: sign_in_with_apple package might be needed for advanced flows, 
// but FirebaseAuth.instance.signInWithProvider(AppleAuthProvider()) is the modern native way.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  // Sign In with Email & Password
  Future<UserCredential> signIn({required String email, required String password}) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(), 
      password: password
    );
  }

  // Sign Up with Email & Password
  Future<UserCredential> signUp({required String email, required String password}) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(), 
      password: password
    );
  }

  // Sign In with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Aborted by user

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google Sign In Failed: $e');
    }
  }

  // Sign In with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');
      return await _auth.signInWithProvider(appleProvider);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' || e.code == 'unknown') {
         // 'unknown' is sometimes returned by the simulator for cancellation, or specific error texts.
         // Checking message text as fallback if needed, but usually code is enough.
         if (e.code == 'canceled') return null;
         if (e.message?.contains('canceled') == true) return null;
      }
      rethrow;
    } catch (e) {
       throw Exception('Apple Sign In Failed: $e');
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Update Display Name
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
      await user.reload(); // Ensure local user object is updated
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Note: This requires recent login. If it fails, we should handle re-auth.
      // For now, we assume the user session is valid.
      await _googleSignIn.signOut(); // Disconnect Google Sign In if used
      await user.delete();
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
