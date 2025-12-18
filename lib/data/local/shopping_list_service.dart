import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import '../../core/services/firestore_service.dart';

class ShoppingListService {
  final Box<ShoppingList> _box;
  final FirestoreService? _firestoreService;
  
  // Track current family ID for sync
  // Track current family ID for sync
  String? _currentFamilyId;
  String? _currentUid;
  StreamSubscription? _familySubscription;
  StreamSubscription? _sharedSubscription;

  ShoppingListService(this._box, [this._firestoreService]);

  // Track if initial sync (first cloud snapshot) has arrived
  final ValueNotifier<bool> listsSyncedNotifier = ValueNotifier(false);

  // Start syncing with a specific family and user
  Future<void> startSync(String familyId, String uid) async {
    if (_currentFamilyId == familyId && _currentUid == uid) return;
    _currentFamilyId = familyId;
    _currentUid = uid;
    
    _familySubscription?.cancel();
    _sharedSubscription?.cancel();

    // 1. Upload Local Lists to Cloud (Ensure existing data is saved)
    if (_firestoreService != null) {
      listsSyncedNotifier.value = false; // Reset sync status

      final localLists = getAllLists();
      for (var list in localLists) {
        await _syncToCloud(list);
      }
    }

      // 2. Listen for Cloud Updates (Family Lists)
    if (_firestoreService != null) {
      _familySubscription = _firestoreService!.getFamilyLists(familyId).listen((cloudLists) async {
        // Sync Updates
        for (var list in cloudLists) {
          await _box.put(list.id, list); 
        }

        // Handle Deletions (Local lists in this family that are NOT in cloud)
        final cloudIds = cloudLists.map((l) => l.id).toSet();
        final localLists = _box.values.toList();
        
        for (var local in localLists) {
          // Check if it belongs to the current family (Primary)
          // Treats null familyId as current/primary for backward compatibility if needed, 
          // or strictly checks match if familyId is set.
          final isAndShouldBeInFamily = local.familyId == familyId;
          
          if (isAndShouldBeInFamily && !cloudIds.contains(local.id)) {
             await _box.delete(local.id);
          }
        }
        
        // Mark as Synced (at least family lists)
        listsSyncedNotifier.value = true;
        
      }, onError: (e) {
        debugPrint('❌ Error syncing family lists: $e');
        // If error, we might still want to say "done" so we don't hang? 
        // Or keep loading? Default to true so user sees local data at least.
        listsSyncedNotifier.value = true; 
      });
      
      // 3. Listen for Cloud Updates (Shared Lists)
      _sharedSubscription = _firestoreService!.getSharedLists(uid).listen((sharedLists) async {
        // Sync Updates
        for (var list in sharedLists) {
             // Shared lists come with familyId populated from FirestoreService
             await _box.put(list.id, list);
        }

        // Handle Deletions (Local lists that are SHARED but NOT in cloud)
        final cloudSharedIds = sharedLists.map((l) => l.id).toSet();
        final localLists = _box.values.toList();

        for (var local in localLists) {
           // It is a shared list if its familyId is DIFFERENT from the current User's familyId
           // (and isn't null, assuming null defaults to primary)
           final isSharedList = local.familyId != null && local.familyId != familyId;
           
           if (isSharedList && !cloudSharedIds.contains(local.id)) {
              await _box.delete(local.id);
           }
        }
      }, onError: (e) {
        debugPrint('❌ Error syncing shared lists: $e');
      });
    }
  }

  void stopSync() {
    _familySubscription?.cancel();
    _sharedSubscription?.cancel();
    _currentFamilyId = null;
    _currentUid = null;
  }

  List<ShoppingList> getAllLists() {
    return _box.values.toList();
  }

  Future<void> createList(ShoppingList list) async {
    // New lists default to current family
    final listWithFamily = list.copyWith(
      familyId: list.familyId ?? _currentFamilyId,
      ownerId: list.ownerId ?? _currentUid,
      members: (list.members.isEmpty && _currentUid != null) 
          ? [_currentUid!] 
          : list.members,
    );
        
    await _box.put(listWithFamily.id, listWithFamily);
    await _syncToCloud(listWithFamily);
  }

  Future<void> updateList(ShoppingList list) async {
    await _box.put(list.id, list);
    await _syncToCloud(list);
  }

  Future<void> deleteList(String id) async {
    final list = _box.get(id);
    final targetFamilyId = list?.familyId ?? _currentFamilyId;
    
    // Always remove from local box instantly
    await _box.delete(id);
    
    if (targetFamilyId != null && _firestoreService != null) {
      // Check ownership to decide: Delete vs Leave
      final isOwner = targetFamilyId == _currentFamilyId;
      
      if (isOwner) {
        // Owner: Hard delete
        await _firestoreService!.deleteList(targetFamilyId, id);
      } else {
        // Guest: Just leave the list (remove from members)
        if (_currentUid != null) {
           await _firestoreService!.removeMemberFromList(targetFamilyId, id, _currentUid!);
        }
      }
    }
  }

  Future<void> addItem(String listId, ShoppingItem item) async {
    final list = _box.get(listId);
    if (list != null) {
      final newItems = List<ShoppingItem>.from(list.items)..add(item);
      final newList = list.copyWith(items: newItems);
      await _box.put(listId, newList);
      await _syncToCloud(newList);
    }
  }

  Future<void> updateItem(String listId, ShoppingItem item) async {
    final list = _box.get(listId);
    if (list != null) {
      final newItems = List<ShoppingItem>.from(list.items);
      final index = newItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        newItems[index] = item;
        final newList = list.copyWith(items: newItems);
        await _box.put(listId, newList);
        await _syncToCloud(newList);
      }
    }
  }

  Future<void> removeItem(String listId, String itemId) async {
    final list = _box.get(listId);
    if (list != null) {
      final newItems = List<ShoppingItem>.from(list.items)..removeWhere((i) => i.id == itemId);
      final newList = list.copyWith(items: newItems);
      await _box.put(listId, newList);
      await _syncToCloud(newList);
    }
  }

  Future<void> restoreCompletedItems(String listId) async {
    final list = _box.get(listId);
    if (list != null) {
      final newItems = list.items.map((item) {
        if (item.checked) {
          return item.copyWith(
            checked: false,
            statusChangedAt: DateTime.now(),
          );
        }
        return item;
      }).toList();
      final newList = list.copyWith(items: newItems);
      await _box.put(listId, newList);
      await _syncToCloud(newList);
    }
  }

  Future<void> removeCompletedItems(String listId) async {
    final list = _box.get(listId);
    if (list != null) {
      final newItems = List<ShoppingItem>.from(list.items)..removeWhere((i) => i.checked);
      final newList = list.copyWith(items: newItems);
      await _box.put(listId, newList);
      await _syncToCloud(newList);
    }
  }

  Future<void> deleteAllData() async {
    // Clear Shopping Lists
    try {
      await _box.clear();
    } catch (e) {
      debugPrint('Error clearing shopping lists: $e');
    }

    // Clear Item History
    try {
      if (Hive.isBoxOpen('item_history')) {
        final historyBox = Hive.box<ShoppingItem>('item_history');
        await historyBox.clear();
      }
    } catch (e) {
      debugPrint('Error clearing item history: $e');
    }
    
    // Clear Hidden Suggestions
    try {
      if (Hive.isBoxOpen('hidden_suggestions')) {
        final hiddenBox = Hive.box<String>('hidden_suggestions');
        await hiddenBox.clear();
      }
    } catch (e) {
      debugPrint('Error clearing hidden suggestions: $e');
    }
  }

  Future<void> _syncToCloud(ShoppingList list) async {
    final targetFamilyId = list.familyId ?? _currentFamilyId;
    if (targetFamilyId != null && _firestoreService != null) {
      // Ensure local list has familyId if not present (implicit ownership)
      final listToSync = list.familyId == null ? list.copyWith(familyId: targetFamilyId) : list;
      
      await _firestoreService!.syncList(targetFamilyId, listToSync);
    }
  }
}
