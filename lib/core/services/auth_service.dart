import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
// Note: sign_in_with_apple package might be needed for advanced flows, 
// but FirebaseAuth.instance.signInWithProvider(AppleAuthProvider()) is the modern native way.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService;

  AuthService(this._firestoreService);

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  // Sign In with Email & Password
  Future<UserCredential> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(), 
      password: password
    );
    await _syncUserData(credential.user);
    return credential;
  }

  // Sign Up with Email & Password
  Future<UserCredential> signUp({required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(), 
      password: password
    );
    await _syncUserData(credential.user);
    return credential;
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

      final userCredential = await _auth.signInWithCredential(credential);
      await _syncUserData(userCredential.user);
      return userCredential;
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
      final userCredential = await _auth.signInWithProvider(appleProvider);
      await _syncUserData(userCredential.user);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' || e.code == 'unknown') {
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
      await _syncUserData(user, name: name);
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Note: This requires recent login. If it fails, we should handle re-auth.
      await _googleSignIn.signOut();
      await user.delete();
      // Note: We might want to remove the Firestore doc too, or mark deleted.
      // FirestoreService logic for delete could be added here.
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Helper to sync user data to Firestore
  Future<void> _syncUserData(User? user, {String? name}) async {
    if (user == null) return;
    await _firestoreService.createOrUpdateUser(
      user.uid, 
      user.email ?? '',
      name: name ?? user.displayName,
      photoUrl: user.photoURL
    );
    await _firestoreService.ensureUserHasFamily(user.uid);
  }
}
