import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
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

  // --- User Management ---

  Future<void> createOrUpdateUser(
    String uid,
    String email, {
    String? name,
    String? photoUrl,
  }) async {
    final data = {'email': email, 'lastLogin': FieldValue.serverTimestamp()};
    if (name != null) data['name'] = name;
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    await _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  Stream<Map<String, dynamic>?> getUserStream(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data() as Map<String, dynamic>?);
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

  // --- Shopping Lists Sync ---

  Stream<List<ShoppingList>> getFamilyLists(String familyId) {
    return _families.doc(familyId).collection('shopping_lists').snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                return ShoppingList.fromMap(data..['id'] = doc.id);
              } catch (e) {
                print('Error parsing list ${doc.id}: $e');
                return null;
              }
            })
            .where((list) => list != null)
            .cast<ShoppingList>()
            .toList();
      },
    );
  }

  Future<void> syncList(String familyId, ShoppingList list) async {
    await _families
        .doc(familyId)
        .collection('shopping_lists')
        .doc(list.id)
        .set(list.toMap());
  }

  Future<void> updateListMetadata(String familyId, ShoppingList list) async {
    await _families
        .doc(familyId)
        .collection('shopping_lists')
        .doc(list.id)
        .update({
          'name': list.name,
          'emoji': list.emoji,
          'budget': list.budget,
        });
  }

  Future<void> addItemsToList(
    String familyId,
    String listId,
    List<ShoppingItem> items,
  ) {
    return _mutateListItems(familyId, listId, (current) {
      final existingIds = current.map((item) => item.id).toSet();
      return [
        ...current,
        ...items.where((item) => !existingIds.contains(item.id)),
      ];
    });
  }

  Future<void> updateListItem(
    String familyId,
    String listId,
    ShoppingItem item,
  ) {
    return _mutateListItems(familyId, listId, (current) {
      return current
          .map((existing) => existing.id == item.id ? item : existing)
          .toList();
    });
  }

  Future<void> removeListItem(String familyId, String listId, String itemId) {
    return _mutateListItems(
      familyId,
      listId,
      (current) => current.where((item) => item.id != itemId).toList(),
    );
  }

  Future<void> restoreCompletedListItems(String familyId, String listId) {
    return _mutateListItems(familyId, listId, (current) {
      return current.map((item) {
        if (!item.checked) return item;
        return item.copyWith(checked: false, statusChangedAt: DateTime.now());
      }).toList();
    });
  }

  Future<void> removeCompletedListItems(String familyId, String listId) {
    return _mutateListItems(
      familyId,
      listId,
      (current) => current.where((item) => !item.checked).toList(),
    );
  }

  Future<void> _mutateListItems(
    String familyId,
    String listId,
    List<ShoppingItem> Function(List<ShoppingItem>) mutate,
  ) async {
    final listRef = _families
        .doc(familyId)
        .collection('shopping_lists')
        .doc(listId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(listRef);
      if (!snapshot.exists) {
        throw StateError('Shopping list not found.');
      }
      final data = snapshot.data() as Map<String, dynamic>;
      final rawItems = data['items'] as List<dynamic>? ?? const [];
      final current = rawItems
          .whereType<Map<String, dynamic>>()
          .map(ShoppingItem.fromMap)
          .toList();
      final updated = mutate(current);
      transaction.update(listRef, {
        'items': updated.map((item) => item.toMap()).toList(),
      });
    });
  }

  Future<void> deleteList(String familyId, String listId) async {
    await _families
        .doc(familyId)
        .collection('shopping_lists')
        .doc(listId)
        .delete();
  }

  // --- Shared Lists (Collection Group) ---

  Stream<List<ShoppingList>> getSharedLists(String uid) {
    return _users.doc(uid).collection('shared_lists').snapshots().switchMap((
      memberships,
    ) {
      if (memberships.docs.isEmpty) {
        return Stream.value(<ShoppingList>[]);
      }

      final streams = memberships.docs.map((membership) {
        final data = membership.data();
        final familyId = data['familyId'] as String?;
        final listId = data['listId'] as String?;
        if (familyId == null || listId == null) {
          return Stream.value(null);
        }
        return _families
            .doc(familyId)
            .collection('shopping_lists')
            .doc(listId)
            .snapshots()
            .map<ShoppingList?>((snapshot) {
              if (!snapshot.exists) return null;
              final listData = snapshot.data() as Map<String, dynamic>;
              return ShoppingList.fromMap(
                listData
                  ..['id'] = snapshot.id
                  ..['familyId'] = familyId,
              );
            })
            .onErrorReturn(null);
      });

      return Rx.combineLatestList(
        streams,
      ).map((lists) => lists.whereType<ShoppingList>().toList());
    });
  }

  // --- Shopping Notes Sync ---

  Stream<List<ShoppingNote>> getFamilyNotes(String familyId) {
    return _families.doc(familyId).collection('shopping_notes').snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                return ShoppingNote.fromMap(data..['id'] = doc.id);
              } catch (e) {
                print('Error parsing note ${doc.id}: $e');
                return null;
              }
            })
            .where((note) => note != null)
            .cast<ShoppingNote>()
            .toList();
      },
    );
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

  Future<void> syncFavoriteRecipe(
    String familyId,
    Map<String, dynamic> recipeData,
  ) async {
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
    final docId = item.name.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '_',
    );

    await _users
        .doc(uid)
        .collection('custom_items')
        .doc(docId)
        .set(item.toMap());
  }

  Future<List<ShoppingItem>> getCustomItems(String uid) async {
    final snapshot = await _users.doc(uid).collection('custom_items').get();

    return snapshot.docs
        .map((doc) {
          try {
            final data = doc.data();
            return ShoppingItem.fromMap(data);
          } catch (e) {
            print('Error parsing custom item ${doc.id}: $e');
            return null;
          }
        })
        .where((item) => item != null)
        .cast<ShoppingItem>()
        .toList();
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
      print(
        'DEBUG: Found fallback item by name match. Deleting doc: ${doc.id}',
      );
      await doc.reference.delete();
    }

    print('DEBUG: Custom item delete sequence complete.');
  }

  // --- Custom Categories Sync (Premium) ---

  Future<void> syncCustomCategory(String uid, String category) async {
    final docId = category.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

    await _users.doc(uid).collection('custom_categories').doc(docId).set({
      'name': category.toLowerCase(),
    }); // Store lowercase for consistency
  }

  Future<List<String>> getCustomCategories(String uid) async {
    final snapshot = await _users
        .doc(uid)
        .collection('custom_categories')
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return data['name'] as String?;
        })
        .where((name) => name != null)
        .cast<String>()
        .toList();
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
