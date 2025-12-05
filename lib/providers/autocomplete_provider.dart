import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/data/models/product_suggestion.dart';
import 'package:smart_market_list/data/static/product_catalog.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';

final itemSuggestionsProvider = Provider<List<ProductSuggestion>>((ref) {
  final listsAsync = ref.watch(shoppingListsProvider);
  
  // Start with catalog items
  final suggestions = [...ProductCatalog.items];
  final catalogNames = suggestions.map((s) => s.name.toLowerCase()).toSet();

  // Add items from history that are not in catalog
  listsAsync.whenData((lists) {
    final historyItems = lists.expand((list) => list.items);
    for (var item in historyItems) {
      if (!catalogNames.contains(item.name.toLowerCase())) {
        suggestions.add(ProductSuggestion(
          name: item.name,
          category: item.category,
          defaultQuantity: item.quantity,
          imageUrl: item.imageUrl,
        ));
        catalogNames.add(item.name.toLowerCase());
      }
    }
  });

  // Sort by name
  suggestions.sort((a, b) => a.name.compareTo(b.name));
  
  return suggestions;
});
