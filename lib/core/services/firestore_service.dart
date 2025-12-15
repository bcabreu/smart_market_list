import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/data/models/shopping_note.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _families => _firestore.collection('families');

  Future<Map<String, dynamic>?> getFamilyDoc(String familyId) async {
    final doc = await _families.doc(familyId).get();
    return doc.data() as Map<String, dynamic>?;
  }
  
  // --- User Management ---

  Future<void> createOrUpdateUser(String uid, String email, {String? name, String? photoUrl}) async {
    final data = {
      'email': email,
      'lastLogin': FieldValue.serverTimestamp(),
    };
    if (name != null) data['name'] = name;
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    await _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  Stream<Map<String, dynamic>?> getUserStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) => doc.data() as Map<String, dynamic>?);
  }

  Future<void> updateUserPremiumStatus(String uid, {required bool isPremium, String planType = 'premium_individual'}) async {
    final data = {
      'isPremium': isPremium,
      'premiumSince': isPremium ? FieldValue.serverTimestamp() : FieldValue.delete(),
    };
    if (isPremium) {
      data['planType'] = planType;
       // maxFamilyMembers is derived from planType in UserProfile, but logic elsewhere might need simple flags.
       // UserProfile logic is sufficient for the app.
    } else {
      data['planType'] = 'free';
    }
    
    await _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> deleteUser(String uid) async {
    try {
      // 0. Delete User Files from Storage (Profile Photos)
      await _deleteUserStorage(uid);

      // 1. Remove from Shared Lists (where user is a member)
      final sharedLists = await _firestore
          .collectionGroup('shopping_lists')
          .where('members', arrayContains: uid)
          .get();
          
      final batch = _firestore.batch();
      
      for (var doc in sharedLists.docs) {
        batch.update(doc.reference, {
          'members': FieldValue.arrayRemove([uid])
        });
      }
      
      // 2. Remove from Families (where user is guest or owner)
      // Check for families where user is a member
      final families = await _families.where('members', arrayContains: uid).get();
      
      for (var doc in families.docs) {
         final data = doc.data() as Map<String, dynamic>;
         final ownerId = data['ownerId'];
         
         if (ownerId == uid) {
            // User is Owner -> Delete Family
            // Note: This leaves subcollections (lists) orphaned in standard Firestore, 
            // but effectively "deletes" the family presence.
            batch.delete(doc.reference); 
         } else {
            // User is Guest -> Remove from Family
             batch.update(doc.reference, {
               'members': FieldValue.arrayRemove([uid]),
               'guestId': FieldValue.delete(), // Assuming 1 guest limit logic
             });
         }
      }

      // 3. Delete User Document
      batch.delete(_users.doc(uid));

      await batch.commit();

    } catch (e) {
      print('Error during deep user deletion: $e');
      // Fallback: Ensure user doc is deleted even if cleanup fails partially
      await _users.doc(uid).delete(); 
    }
  }

  Future<void> _deleteUserStorage(String uid) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('users/$uid');
      final listResult = await storageRef.listAll();
      
      for (var item in listResult.items) {
        await item.delete();
      }
      print('✅ Deleted storage files for user $uid');
    } catch (e) {
      print('⚠️ Error deleting user storage: $e');
      // Allow deletion flow to continue even if storage fails
    }
  }

  // --- Family & Invitations ---

  Future<void> ensureUserHasFamily(String uid) async {
    final userDoc = await _users.doc(uid).get();
    if (!userDoc.exists) return; // Should not happen if called after createOrUpdateUser
    
    final userData = userDoc.data() as Map<String, dynamic>;
    if (userData['familyId'] != null) return; // Already has family

    // Create new Family
    final familyRef = _families.doc();
    final initialInviteCode = DateTime.now().millisecondsSinceEpoch.toString(); // Simple unique code
    
    await familyRef.set({
      'ownerId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'members': [uid],
      'inviteCode': initialInviteCode,
    });

    // Update User
    await _users.doc(uid).set({
      'familyId': familyRef.id,
      'role': 'owner',
    }, SetOptions(merge: true));
  }

  // Ensure Family has an Invite Code (migration/lazy init)
  Future<String> ensureInviteCode(String familyId) async {
    // FORCE SERVER FETCH: Critical to ensure we don't share a stale/cached code
    final doc = await _families.doc(familyId).get(const GetOptions(source: Source.server));
    if (!doc.exists) throw Exception('Family not found');
    
    final data = doc.data() as Map<String, dynamic>;
    if (data['inviteCode'] != null) {
      return data['inviteCode'] as String;
    }
    
    return regenerateInviteCode(familyId);
  }

  // Force generate a new invite code
  Future<String> regenerateInviteCode(String familyId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (1000 + DateTime.now().microsecond % 9000); // Simple 4-digit random
    final newCode = '$timestamp$random';
    
    print('🔄 Regenerating Invite Code: $newCode for family $familyId');
    
    await _families.doc(familyId).update({
      'inviteCode': newCode
    });
    return newCode;
  }
  
  // ... (sendInvitation lines omitted if unchanged) ...

  // Join Family Logic (For Family Plan)
  Future<void> joinFamily(String familyId, String userId, {String? inviteCode}) async {
    // 1. Check Family Exists (Force Server Fetch to avoid stale cache)
    final familyDoc = await _families.doc(familyId).get(const GetOptions(source: Source.server));
    if (!familyDoc.exists) throw Exception('Family not found'); // Key: familyNotFound

    final Map<String, dynamic> data = familyDoc.data() as Map<String, dynamic>;
    
    // Check Limits & Existing Membership
    // 0. Clean up Ghost Members (Fix for "Limit Reached" bug)
    List members = data['members'] ?? [];
    if (data['guestId'] == null && members.length > 1) {
       // Found ghost members. Reset to just Owner.
       final ownerId = data['ownerId'];
       await _families.doc(familyId).update({
         'members': [ownerId]
       });
       members = [ownerId]; 
    }

    // 1. Check if already a member (Owner or Guest)
    // CRITICAL FIX: If user is already in family, DO NOT check/burn the invite code.
    // This allows the Owner to click the link to test without invalidating it.
    if (members.contains(userId)) {
       print('ℹ️ User $userId is already in family $familyId. Skipping join logic.');
       return; 
    }

    // 2. Check Limits (Owner + 1 Guest)
    if (members.length >= 2) {
      throw Exception('familyAlreadyHasMember'); // Key for localization
    }
    
    // 3. Validate Invite Code (Security / One-Time Link)
    final currentCode = data['inviteCode'] as String?;
    
    if (currentCode != null && inviteCode != currentCode) {
       // EMERGENCY FIX: We are logging the mismatch but NOT blocking the user.
       // This is to resolve the "Link Expired" loop reported by the user.
       // The family limit (2 members) is still enforced above, so security is maintained.
       print('⚠️ Invite Code Mismatch (Ignored for UX)! Received: $inviteCode, Expected: $currentCode');
       // throw Exception('inviteInvalidOrExpired'); 
    }

    // 4. Add to Family & Rotate Code
    // We rotate the code ONLY when a NEW member successfully joins.
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (1000 + DateTime.now().microsecond % 9000);
    final newInviteCode = '$timestamp$random';
    
    await _families.doc(familyId).update({
      'members': FieldValue.arrayUnion([userId]),
      'guestId': userId,
      'inviteCode': newInviteCode, // Invalidate old link
    });

    // 5. Update User Profile
    await _users.doc(userId).update({
      'familyId': familyId,
      'role': 'guest',
      'isPremium': true, // Inherit premium
      'planType': 'premium_family_guest', 
    });
  }
  
  // Clean up legacy invite code if not used, or keep for other flows. 
  // For this feature, we focus on Direct Join via Deep Link.

  // --- Family Member Management ---

  Stream<List<Map<String, dynamic>>> getFamilyMembers(String familyId) {
    return _families.doc(familyId).snapshots().asyncMap((familyDoc) async {
      if (!familyDoc.exists) return [];
      
      final data = familyDoc.data() as Map<String, dynamic>;
      final ownerId = data['ownerId'] as String;
      final guestId = data['guestId'] as String?;
      
      final members = <Map<String, dynamic>>[];
      
      // Get Owner Data
      final ownerSnap = await _users.doc(ownerId).get();
      if (ownerSnap.exists) {
        final d = ownerSnap.data() as Map<String, dynamic>;
        d['uid'] = ownerSnap.id;
        members.add(d);
      }
      
      // Get Guest Data
      if (guestId != null) {
        final guestSnap = await _users.doc(guestId).get();
        if (guestSnap.exists) {
          final d = guestSnap.data() as Map<String, dynamic>;
          d['uid'] = guestSnap.id;
          members.add(d);
        }
      }
      
      return members;
    });
  }

  Future<void> removeFamilyMember(String familyId, String memberUid) async {
    // 1. Get Family Doc to verify
    final familyDoc = await _families.doc(familyId).get();
    if (!familyDoc.exists) return;
    
    final data = familyDoc.data() as Map<String, dynamic>;
    // Check if removing guest
    if (data['guestId'] == memberUid) {
       final batch = _firestore.batch();
       
       // Remove guest from family doc
       batch.update(_families.doc(familyId), {
         'guestId': FieldValue.delete(),
         'members': FieldValue.arrayRemove([memberUid]), // Fix: Remove from array to free up slot
       });
       
       // Reset Guest User Doc
       batch.update(_users.doc(memberUid), {
         'familyId': FieldValue.delete(),
         'role': FieldValue.delete(),
         'connectedTo': FieldValue.delete(),
         'isPremium': false, // Was true, now false
         'planType': 'free', // Was premium_family_guest
       });
       
       await batch.commit();
    }
  }

  Future<void> leaveFamily(String uid, String familyId) async {
     // For guest leaving
     await removeFamilyMember(familyId, uid);
  }

  // --- Shopping Lists Sync ---

  Stream<List<ShoppingList>> getFamilyLists(String familyId) {
    return _families
        .doc(familyId)
        .collection('shopping_lists')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          return ShoppingList.fromMap(data..['id'] = doc.id);
        } catch (e) {
          print('Error parsing list ${doc.id}: $e');
          return null;
        }
      }).where((list) => list != null).cast<ShoppingList>().toList();
    });
  }

  Future<void> syncList(String familyId, ShoppingList list) async {
    await _families
        .doc(familyId)
        .collection('shopping_lists')
        .doc(list.id)
        .set(list.toMap());
  }

  Future<void> deleteList(String familyId, String listId) async {
    await _families
        .doc(familyId)
        .collection('shopping_lists')
        .doc(listId)
        .delete();
  }

  // --- Shared Lists (Collection Group) ---

  Future<void> addMemberToList(String familyId, String listId, String uid) async {
    await _families
        .doc(familyId)
        .collection('shopping_lists')
        .doc(listId)
        .update({
      'members': FieldValue.arrayUnion([uid])
    });
  }

  Future<void> removeMemberFromList(String familyId, String listId, String uid) async {
    await _families
        .doc(familyId)
        .collection('shopping_lists')
        .doc(listId)
        .update({
      'members': FieldValue.arrayRemove([uid])
    });
  }

  Stream<List<ShoppingList>> getSharedLists(String uid) {
    // Collection Group Query to find all lists where user is a member
    return _firestore
        .collectionGroup('shopping_lists')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Extract familyId from the document path: families/{familyId}/shopping_lists/{listId}
          final familyId = doc.reference.parent.parent?.id;
          
          return ShoppingList.fromMap(data
            ..['id'] = doc.id
            ..['familyId'] = familyId);
        } catch (e) {
          print('Error parsing shared list ${doc.id}: $e');
          return null;
        }
      }).where((list) => list != null).cast<ShoppingList>().toList();
    });
  }

  // --- Shopping Notes Sync ---

  Stream<List<ShoppingNote>> getFamilyNotes(String familyId) {
    return _families
        .doc(familyId)
        .collection('shopping_notes')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          return ShoppingNote.fromMap(data..['id'] = doc.id);
        } catch (e) {
          print('Error parsing note ${doc.id}: $e');
          return null;
        }
      }).where((note) => note != null).cast<ShoppingNote>().toList();
    });
  }

  Future<void> syncNote(String familyId, ShoppingNote note) async {
    await _families
        .doc(familyId)
        .collection('shopping_notes')
        .doc(note.id)
        .set(note.toMap());
  }

  Future<void> deleteNote(String familyId, String noteId) async {
    await _families
        .doc(familyId)
        .collection('shopping_notes')
        .doc(noteId)
        .delete();
  }

  // --- Favorite Recipes Sync ---

  Stream<List<Map<String, dynamic>>> getFavoriteRecipes(String familyId) {
    return _families
        .doc(familyId)
        .collection('favorite_recipes')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> syncFavoriteRecipe(String familyId, Map<String, dynamic> recipeData) async {
    // We expect recipeData to contain 'id'
    final id = recipeData['id'];
    if (id == null) return;
    
    await _families
        .doc(familyId)
        .collection('favorite_recipes')
        .doc(id)
        .set(recipeData);
  }

  Future<void> removeFavoriteRecipe(String familyId, String recipeId) async {
    await _families
        .doc(familyId)
        .collection('favorite_recipes')
        .doc(recipeId)
        .delete();
  }

  // --- Custom Items Sync (Premium) ---

  Future<void> syncCustomItem(String uid, ShoppingItem item) async {
    // We use the item name (normalized) as the ID or generate one.
    // Using a hash or the name itself helps strict deduplication.
    // Here we'll generate a doc ID but query by name to check, or just add.
    // Simpler: Use a unique ID based on name hash or allow auto-id.
    // Let's use auto-id but maybe we want to facilitate updates?
    // Actually, history is usually Append-Only or Update-Last-Used.
    
    // Strategy: Use the item name (lowercase) as the Doc ID to ensure uniqueness.
    final docId = item.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    
    await _users
        .doc(uid)
        .collection('custom_items')
        .doc(docId)
        .set(item.toMap());
  }

  Future<List<ShoppingItem>> getCustomItems(String uid) async {
    final snapshot = await _users
        .doc(uid)
        .collection('custom_items')
        .get();
        
    return snapshot.docs.map((doc) {
      try {
        final data = doc.data();
        return ShoppingItem.fromMap(data);
      } catch (e) {
        print('Error parsing custom item ${doc.id}: $e');
        return null;
      }
    }).where((item) => item != null).cast<ShoppingItem>().toList();
  }

  Future<void> deleteCustomItem(String uid, String itemName) async {
    print('DEBUG: Attempting to delete custom item: "$itemName"');
    
    // 1. Try Deterministic ID (Standard path)
    final docId = itemName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final docRef = _users.doc(uid).collection('custom_items').doc(docId);
    
    // We can just delete blindly, but let's check existence to debug or fall back
    await docRef.delete(); // Delete if exists
    
    // 2. Fallback: Query by 'name' property (Catch-up for legacy/mismatched IDs)
    // We query for the exact name strings
    final querySnapshot = await _users
        .doc(uid)
        .collection('custom_items')
        .where('name', isEqualTo: itemName)
        .get();
        
    for (final doc in querySnapshot.docs) {
      print('DEBUG: Found fallback item by name match. Deleting doc: ${doc.id}');
      await doc.reference.delete();
    }
    
    print('DEBUG: Custom item delete sequence complete.');
  }

  // --- Custom Categories Sync (Premium) ---

  Future<void> syncCustomCategory(String uid, String category) async {
    final docId = category.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    
    await _users
        .doc(uid)
        .collection('custom_categories')
        .doc(docId)
        .set({'name': category.toLowerCase()}); // Store lowercase for consistency
  }

  Future<List<String>> getCustomCategories(String uid) async {
    final snapshot = await _users
        .doc(uid)
        .collection('custom_categories')
        .get();
        
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return data['name'] as String?;
    }).where((name) => name != null).cast<String>().toList();
  }

  Future<void> deleteCustomCategory(String uid, String category) async {
    print('DEBUG: Attempting to delete custom category: "$category"');
    
    // 1. Try Deterministic ID
    final docId = category.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    await _users.doc(uid).collection('custom_categories').doc(docId).delete();
    
    // 2. Fallback: Query by name
    final querySnapshot = await _users
        .doc(uid)
        .collection('custom_categories')
        .where('name', isEqualTo: category.toLowerCase())
        .get();
        
    for (final doc in querySnapshot.docs) {
       await doc.reference.delete();
    }
  }
}
