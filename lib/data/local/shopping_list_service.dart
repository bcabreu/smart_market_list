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
  String? _currentFamilyId;
  StreamSubscription? _cloudSubscription;

  ShoppingListService(this._box, [this._firestoreService]);

  // Start syncing with a specific family
  void startSync(String familyId) {
    if (_currentFamilyId == familyId) return;
    _currentFamilyId = familyId;
    _cloudSubscription?.cancel();

    if (_firestoreService != null) {
      _cloudSubscription = _firestoreService!.getFamilyLists(familyId).listen((cloudLists) async {
        for (var list in cloudLists) {
          // Merge logic: Simple "Cloud overwrites Local" for now to ensure consistency
          // Ideally: Check timestamps
          await _box.put(list.id, list); 
        }
        // Identify deleted lists? 
        // If a list exists locally but not in cloud list, and it WAS synced... 
        // For MVP, valid lists are what come from cloud.
      });
    }
  }

  void stopSync() {
    _cloudSubscription?.cancel();
    _currentFamilyId = null;
  }

  List<ShoppingList> getAllLists() {
    return _box.values.toList();
  }

  Future<void> createList(ShoppingList list) async {
    await _box.put(list.id, list);
    await _syncToCloud(list);
  }

  Future<void> updateList(ShoppingList list) async {
    await _box.put(list.id, list);
    await _syncToCloud(list);
  }

  Future<void> deleteList(String id) async {
    await _box.delete(id);
    // If we are in family mode, we should also delete from Cloud IF we are Owner?
    // User requirement: Guest cannot delete.
    // We assume the variable check happens in UI, but safe to check here if we had user role.
    // For now, if ability to delete is triggered, we execute. 
    // NOTE: FirestoreService needs a delete capability.
    // await _firestoreService?.deleteList(_currentFamilyId, id);
    // We haven't implemented deleteList in FirestoreService yet.
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
    if (_currentFamilyId != null && _firestoreService != null) {
      await _firestoreService!.syncList(_currentFamilyId!, list);
    }
  }
}
