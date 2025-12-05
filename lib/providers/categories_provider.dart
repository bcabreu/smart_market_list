import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';

class CategoriesNotifier extends StateNotifier<List<String>> {
  CategoriesNotifier() : super([]) {
    _loadCategories();
  }

  void _loadCategories() {
    final box = Hive.box<List<String>>('categories');
    final savedCategories = box.get('custom_categories') ?? [];
    
    // Combine defaults with saved custom categories
    final defaultCategories = AppColors.categoryGradients.keys.toList();
    state = [...defaultCategories, ...savedCategories];
  }

  void addCategory(String category) {
    if (!state.contains(category.toLowerCase())) {
      final box = Hive.box<List<String>>('categories');
      final savedCategories = box.get('custom_categories') ?? [];
      
      final newCustomCategories = [...savedCategories, category.toLowerCase()];
      box.put('custom_categories', newCustomCategories);
      
      state = [...state, category.toLowerCase()];
    }
  }

  void removeCategory(String category) {
    final box = Hive.box<List<String>>('categories');
    final savedCategories = box.get('custom_categories') ?? [];
    
    final newCustomCategories = savedCategories.where((c) => c != category.toLowerCase()).toList();
    box.put('custom_categories', newCustomCategories);
    
    state = state.where((c) => c != category.toLowerCase()).toList();
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<String>>((ref) {
  return CategoriesNotifier();
});
