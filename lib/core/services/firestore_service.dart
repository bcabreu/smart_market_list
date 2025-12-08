import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _families => _firestore.collection('families');

  // --- User Management ---

  Future<void> createOrUpdateUser(String uid, String email, {String? name, String? photoUrl}) async {
    await _users.doc(uid).set({
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  Stream<Map<String, dynamic>?> getUserStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) => doc.data() as Map<String, dynamic>?);
  }

  Future<void> updateUserPremiumStatus(String uid, bool isPremium) async {
    await _users.doc(uid).set({
      'isPremium': isPremium,
      'premiumSince': isPremium ? FieldValue.serverTimestamp() : FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  // --- Family & Invitations ---

  Future<void> sendInvitation(String ownerUid, String guestEmail) async {
    // 1. Check if guest user exists (optional, depends on flow)
    // 2. Create an invitation record or update the owner's 'pendingInvite' field
    // For simplicity V1: We'll store the pending invite on the Owner's user doc
    // and/or a separate 'invitations' collection.
    
    // Using a dedicated invitations collection allows querying by email
    await _firestore.collection('invitations').add({
      'fromUid': ownerUid,
      'toEmail': guestEmail,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<QuerySnapshot> checkPendingInvitations(String email) async {
    return _firestore
        .collection('invitations')
        .where('toEmail', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .get();
  }

  Stream<QuerySnapshot> getSentInvitations(String ownerUid) {
    return _firestore
        .collection('invitations')
        .where('fromUid', isEqualTo: ownerUid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> acceptInvitation(String inviteId, String guestUid, String ownerUid) async {
    final batch = _firestore.batch();

    // 1. Create Family Document
    final familyRef = _families.doc();
    batch.set(familyRef, {
      'ownerId': ownerUid,
      'guestId': guestUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Update Owner User Doc
    batch.update(_users.doc(ownerUid), {
      'familyId': familyRef.id,
      'role': 'owner',
    });

    // 3. Update Guest User Doc
    batch.update(_users.doc(guestUid), {
      'familyId': familyRef.id,
      'role': 'guest',
      'connectedTo': ownerUid,
       // Guest inherits premium implied by being in a family with an owner
    });

    // 4. Update Invite Status
    batch.update(_firestore.collection('invitations').doc(inviteId), {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> cancelInvitation(String inviteId) async {
    await _firestore.collection('invitations').doc(inviteId).delete();
  }

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
       });
       
       // Reset Guest User Doc
       batch.update(_users.doc(memberUid), {
         'familyId': FieldValue.delete(),
         'role': FieldValue.delete(),
         'connectedTo': FieldValue.delete(),
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
        final data = doc.data();
        // We need a fromMap method in ShoppingList that handles JSON -> Object
        // For now, let's assume standard Hive structure + key
        return ShoppingList.fromMap(data..['id'] = doc.id);
      }).toList();
    });
  }

  Future<void> syncList(String familyId, ShoppingList list) async {
    await _families
        .doc(familyId)
        .collection('shopping_lists')
        .doc(list.id)
        .set(list.toMap());
  }
}
