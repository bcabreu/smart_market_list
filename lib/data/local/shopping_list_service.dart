import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';

class ShoppingListService {
  final Box<ShoppingList> _box;

  ShoppingListService(this._box);

  List<ShoppingList> getAllLists() {
    return _box.values.toList();
  }

  Future<void> createList(ShoppingList list) async {
    await _box.put(list.id, list);
  }

  Future<void> updateList(ShoppingList list) async {
    await _box.put(list.id, list);
  }

  Future<void> deleteList(String id) async {
    await _box.delete(id);
  }

  Future<void> addItem(String listId, ShoppingItem item) async {
    final list = _box.get(listId);
    if (list != null) {
      final newItems = List<ShoppingItem>.from(list.items)..add(item);
      final newList = list.copyWith(items: newItems);
      await _box.put(listId, newList);
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
      }
    }
  }

  Future<void> removeItem(String listId, String itemId) async {
    final list = _box.get(listId);
    if (list != null) {
      final newItems = List<ShoppingItem>.from(list.items)..removeWhere((i) => i.id == itemId);
      final newList = list.copyWith(items: newItems);
      await _box.put(listId, newList);
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
    }
  }

  Future<void> removeCompletedItems(String listId) async {
    final list = _box.get(listId);
    if (list != null) {
      final newItems = List<ShoppingItem>.from(list.items)..removeWhere((i) => i.checked);
      final newList = list.copyWith(items: newItems);
      await _box.put(listId, newList);
    }
  }
}
