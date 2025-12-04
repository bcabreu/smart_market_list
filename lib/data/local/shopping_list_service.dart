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
    await list.save();
  }

  Future<void> deleteList(String id) async {
    await _box.delete(id);
  }

  Future<void> addItem(String listId, ShoppingItem item) async {
    final list = _box.get(listId);
    if (list != null) {
      list.items.add(item);
      await list.save();
    }
  }

  Future<void> updateItem(String listId, ShoppingItem item) async {
    final list = _box.get(listId);
    if (list != null) {
      final index = list.items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        list.items[index] = item;
        await list.save();
      }
    }
  }

  Future<void> removeItem(String listId, String itemId) async {
    final list = _box.get(listId);
    if (list != null) {
      list.items.removeWhere((i) => i.id == itemId);
      await list.save();
    }
  }
}
