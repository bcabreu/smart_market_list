import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';

final itemSuggestionsProvider = Provider<List<String>>((ref) {
  final listsAsync = ref.watch(shoppingListsProvider);
  
  return listsAsync.when(
    data: (lists) {
      final allItems = lists.expand((list) => list.items).map((item) => item.name).toSet();
      return allItems.toList()..sort();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
