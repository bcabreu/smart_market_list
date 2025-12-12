import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/core/services/revenue_cat_service.dart';
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

  // Validate Session (Check if user still exists on server)
  Future<void> validateSession() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.reload();
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
      // 1. Delete User Data from Firestore
      try {
        await _firestoreService.deleteUser(user.uid);
      } catch (e) {
        print('Error deleting user Firestore data: $e');
        // Continue to delete Auth
      }

      // 2. Delete Auth Account
      // Note: This requires recent login. If it fails, it will throw, and ProfileScreen catches it.
      await user.delete();

      // 3. Sign Out (Clean up local state/tokens)
      await _googleSignIn.signOut();
      await _auth.signOut();
      await RevenueCatService().logOut();
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await RevenueCatService().logOut();
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

    // 1. Identify User in RevenueCat (Strict Mode)
    // This prevents "Anonymous" device entitlements from leaking to new users
    // unless the device receipt literally explicitly belongs to them (which RC handles)
    await RevenueCatService().logIn(user.uid);

    // Check & Sync Subscription Status (Anonymous -> Authenticated)
    try {
      final subDetails = await RevenueCatService().getActiveSubscriptionDetails();
      if (subDetails != null && subDetails['isPremium'] == true) {
         print("🔄 Syncing existing subscription for ${user.uid}");
         await _firestoreService.updateUserPremiumStatus(
           user.uid,
           isPremium: true,
           planType: subDetails['planType']
         );
      } else {
         // Auto-Downgrade (Anti-Farming Logic)
         // If RevenueCat says "Not Premium" (expired, transferred, or never existed),
         // we MUST update Firestore to reflect this.
         // This ensures that if a user transfers their subscription to another account,
         // the old account loses access immediately upon next sync.
         print("📉 Syncing downgrade/removal for ${user.uid}");
         await _firestoreService.updateUserPremiumStatus(
           user.uid,
           isPremium: false
         );
      }
    } catch (e) {
      print("⚠️ Auto-sync subscription failed: $e");
    }
  }
}
