import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/data/models/product_suggestion.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/data/static/product_catalog.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';

import 'package:smart_market_list/providers/hidden_suggestions_provider.dart';

import 'package:smart_market_list/providers/history_provider.dart';

final itemSuggestionsProvider = Provider<List<ProductSuggestion>>((ref) {
  final listsAsync = ref.watch(shoppingListsProvider);
  final hiddenSuggestions = ref.watch(hiddenSuggestionsProvider);
  final historyItems = ref.watch(historyProvider);
  
  // 1. Build a map of history items (Name -> Item) to get user preferences
  final Map<String, ShoppingItem> historyMap = {};

  // Add items from active lists
  listsAsync.whenData((lists) {
    for (final list in lists) {
      for (final item in list.items) {
        historyMap[item.name.toLowerCase()] = item;
      }
    }
  });

  // Add items from persistent history (overwrites active lists if same name, which is desired as history is updated on save)
  for (final item in historyItems) {
    historyMap[item.name.toLowerCase()] = item;
  }

  final List<ProductSuggestion> suggestions = [];
  final Set<String> processedNames = {};
  final hiddenSet = hiddenSuggestions.map((e) => e.toLowerCase()).toSet();

  // 2. Process Catalog Items (with overrides from history)
  for (final catalogItem in ProductCatalog.items) {
    final normalizedName = catalogItem.name.toLowerCase();
    
    // Skip if hidden
    if (hiddenSet.contains(normalizedName)) continue;
    
    if (historyMap.containsKey(normalizedName)) {
      // Found in history: Override category, quantity, and image (if custom)
      final historyItem = historyMap[normalizedName]!;
      suggestions.add(ProductSuggestion(
        name: catalogItem.name, // Keep catalog casing
        category: historyItem.category, // User's preferred category
        defaultQuantity: historyItem.quantity, // User's preferred quantity
        // Use user's image if it's different/custom, otherwise fallback to catalog
        imageUrl: historyItem.imageUrl.isNotEmpty ? historyItem.imageUrl : catalogItem.imageUrl,
      ));
    } else {
      // Not in history: Use catalog default
      suggestions.add(catalogItem);
    }
    processedNames.add(normalizedName);
  }

  // 3. Add remaining History Items (that are not in catalog)
  if (historyMap.isNotEmpty) {
     for (final entry in historyMap.entries) {
       if (!processedNames.contains(entry.key) && !hiddenSet.contains(entry.key)) {
         final item = entry.value;
         suggestions.add(ProductSuggestion(
           name: item.name,
           category: item.category,
           defaultQuantity: item.quantity,
           imageUrl: item.imageUrl,
         ));
         processedNames.add(entry.key);
       }
     }
  }

  // 4. Sort by name
  suggestions.sort((a, b) => a.name.compareTo(b.name));
  
  return suggestions;
});
