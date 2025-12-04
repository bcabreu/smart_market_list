import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/shopping_list_service.dart';
import '../data/models/shopping_list.dart';

final shoppingListBoxProvider = Provider<Box<ShoppingList>>((ref) {
  return Hive.box<ShoppingList>('shopping_lists');
});

final shoppingListServiceProvider = Provider<ShoppingListService>((ref) {
  final box = ref.watch(shoppingListBoxProvider);
  return ShoppingListService(box);
});

final shoppingListsProvider = StreamProvider<List<ShoppingList>>((ref) {
  final box = ref.watch(shoppingListBoxProvider);
  // Return initial values and listen to changes
  return box.watch().map((event) => box.values.toList()).startWith(box.values.toList());
});

final currentListIdProvider = StateProvider<String?>((ref) => null);

final currentListProvider = Provider<ShoppingList?>((ref) {
  final listsAsync = ref.watch(shoppingListsProvider);
  final currentId = ref.watch(currentListIdProvider);
  
  return listsAsync.when(
    data: (lists) {
      if (lists.isEmpty) return null;
      if (currentId == null) return lists.first;
      return lists.firstWhere((l) => l.id == currentId, orElse: () => lists.first);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
