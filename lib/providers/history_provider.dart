import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';

class HistoryNotifier extends StateNotifier<List<ShoppingItem>> {
  HistoryNotifier() : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final box = Hive.box<ShoppingItem>('item_history');
    state = box.values.toList();
  }

  Future<void> addOrUpdate(ShoppingItem item) async {
    final box = Hive.box<ShoppingItem>('item_history');
    // Use normalized name as key to ensure uniqueness per item name
    final key = item.name.trim().toLowerCase();
    
    // We want to save the item details (category, image, etc.)
    // We don't necessarily care about the ID or checked state for history purposes,
    // but saving the whole object is fine.
    await box.put(key, item);
    
    // Update state
    state = box.values.toList();
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, List<ShoppingItem>>((ref) {
  return HistoryNotifier();
});
