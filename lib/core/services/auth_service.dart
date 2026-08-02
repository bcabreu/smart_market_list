import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_market_list/core/services/backend_service.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/core/services/local_session_service.dart';
import 'package:smart_market_list/core/services/revenue_cat_service.dart';
// Note: sign_in_with_apple package might be needed for advanced flows,
// but FirebaseAuth.instance.signInWithProvider(AppleAuthProvider()) is the modern native way.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService;
  final BackendService _backendService;

  AuthService(this._firestoreService, this._backendService);

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  // Validate Session (Check if user still exists on server)
  Future<void> validateSession() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.reload();
        await _syncUserData(_auth.currentUser);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'user-disabled') {
          await signOut();
        }
        // Don't rethrow network errors, keep session if just offline
        if (e.code == 'user-not-found' || e.code == 'user-disabled') {
          rethrow;
        }
      }
    }
  }

  // Sign In with Email & Password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _syncUserData(credential.user);
    return credential;
  }

  // Sign Up with Email & Password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _syncUserData(credential.user);
    return credential;
  }

  // Sign In with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Aborted by user

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
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

  // Update Photo URL
  Future<void> updatePhotoURL(String photoUrl) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePhotoURL(photoUrl);
      await user.reload();
      await _syncUserData(user); // Will pick up new photoURL from user object
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // The callable validates recent authentication and deletes Firestore
      // subcollections, Storage objects, RevenueCat data and Firebase Auth as
      // one server-controlled operation.
      await _backendService.deleteAccount();
      await RevenueCatService().logOut();
      await _googleSignIn.signOut();
      await _auth.signOut();
      await LocalSessionService.clearAccountData();
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await RevenueCatService().logOut();
    await _googleSignIn.signOut();
    await _auth.signOut();
    await LocalSessionService.clearAccountData();
  }

  // Helper to sync user data to Firestore
  Future<void> _syncUserData(User? user, {String? name}) async {
    if (user == null) return;

    await LocalSessionService.activateUser(user.uid);
    await _firestoreService.createOrUpdateUser(
      user.uid,
      user.email ?? '',
      name: name ?? user.displayName,
      photoUrl: user.photoURL,
    );
    await _backendService.ensureUserWorkspace();

    // RevenueCat identifies the receipt locally, but only the backend may
    // persist or revoke Premium access.
    await RevenueCatService().logIn(user.uid);
    try {
      await _backendService.syncRevenueCatStatus();
    } catch (e) {
      // Keep the last server-known status when offline. Firestore/Storage rules
      // still enforce any known expiration timestamp.
      print('⚠️ Server subscription sync failed: $e');
    }
  }
}
