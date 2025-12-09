import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';

class CategoriesNotifier extends StateNotifier<List<String>> {
  final Ref ref;

  CategoriesNotifier(this.ref) : super([]) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final box = Hive.box<List<String>>('categories');
    final savedCategories = box.get('custom_categories') ?? [];
    
    // Combine defaults with saved custom categories
    final defaultCategories = AppColors.categoryGradients.keys.toList();
    state = [...defaultCategories, ...savedCategories];

    // Cloud Sync
    _syncFromCloud(); 
    _syncAllLocalToCloud();
  }

  Future<void> _syncAllLocalToCloud() async {
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      final userProfile = await ref.read(userProfileProvider.future);
      final isPremium = userProfile?.isPremium ?? false;

      if (!isPremium) return;

      final box = Hive.box<List<String>>('categories');
      final localCategories = box.get('custom_categories') ?? [];
      
      if (localCategories.isEmpty) return;

      for (final cat in localCategories) {
        await ref.read(firestoreServiceProvider).syncCustomCategory(user.uid, cat);
      }
      print('Synced ${localCategories.length} local categories to cloud');
    } catch (e) {
      print('Error syncing local categories to cloud: $e');
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      final userProfile = await ref.read(userProfileProvider.future);
      final isPremium = userProfile?.isPremium ?? false;
      
      if (!isPremium) return;

      final cloudCategories = await ref.read(firestoreServiceProvider).getCustomCategories(user.uid);
      if (cloudCategories.isEmpty) return;

      final box = Hive.box<List<String>>('categories');
      final localCategories = box.get('custom_categories') ?? [];
      bool changed = false;
      
      final newLocalList = [...localCategories];

      for (final cat in cloudCategories) {
        if (!newLocalList.contains(cat.toLowerCase())) {
          newLocalList.add(cat.toLowerCase());
          changed = true;
        }
      }

      if (changed) {
        await box.put('custom_categories', newLocalList);
        final defaultCategories = AppColors.categoryGradients.keys.toList();
        state = [...defaultCategories, ...newLocalList];
      }
    } catch (e) {
      print('Error syncing categories from cloud: $e');
    }
  }

  Future<void> addCategory(String category) async {
    if (!state.contains(category.toLowerCase())) {
      final box = Hive.box<List<String>>('categories');
      final savedCategories = box.get('custom_categories') ?? [];
      
      final newCustomCategories = [...savedCategories, category.toLowerCase()];
      box.put('custom_categories', newCustomCategories);
      
      state = [...state, category.toLowerCase()];

      // Cloud Sync
      try {
        final user = ref.read(authServiceProvider).currentUser;
        final userProfile = await ref.read(userProfileProvider.future);
        final isPremium = userProfile?.isPremium ?? false;
        
        if (user != null && isPremium) {
           await ref.read(firestoreServiceProvider).syncCustomCategory(user.uid, category);
        }
      } catch (e) {
        print('Cloud sync error for category: $e');
      }
    }
  }

  Future<void> removeCategory(String category) async {
    final box = Hive.box<List<String>>('categories');
    final savedCategories = box.get('custom_categories') ?? [];
    
    final newCustomCategories = savedCategories.where((c) => c != category.toLowerCase()).toList();
    box.put('custom_categories', newCustomCategories);
    
    state = state.where((c) => c != category.toLowerCase()).toList();

    // Cloud Sync (Delete)
    try {
      final user = ref.read(authServiceProvider).currentUser;
      final userProfile = await ref.read(userProfileProvider.future);
      final isPremium = userProfile?.isPremium ?? false;
      
      if (user != null && isPremium) {
         await ref.read(firestoreServiceProvider).deleteCustomCategory(user.uid, category);
      }
    } catch (e) {
      print('Cloud sync error (delete) for category: $e');
    }
  }

  Future<void> clear() async {
    final box = Hive.box<List<String>>('categories');
    await box.put('custom_categories', []);
    final defaultCategories = AppColors.categoryGradients.keys.toList();
    state = defaultCategories;
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<String>>((ref) {
  final notifier = CategoriesNotifier(ref);

  ref.listen(authStateProvider, (previous, next) {
    next.whenData((user) {
      if (user == null) {
        notifier.clear();
      }
    });
  });

  return notifier;
});
