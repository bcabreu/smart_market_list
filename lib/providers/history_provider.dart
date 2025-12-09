import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';

import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';

class HistoryNotifier extends StateNotifier<List<ShoppingItem>> {
  final Ref ref;

  HistoryNotifier(this.ref) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final box = Hive.box<ShoppingItem>('item_history');
    state = box.values.toList();
    
    // Attempt cloud sync on load if user is logged in
    _syncFromCloud(); // Cloud -> Local (Fire and forget)
    _syncAllLocalToCloud(); // Local -> Cloud (Fire and forget - Catch up)
  }

  Future<void> _syncAllLocalToCloud() async {
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      final userProfile = await ref.read(userProfileProvider.future);
      final isPremium = userProfile?.isPremium ?? false;

      if (!isPremium) return;

      final box = Hive.box<ShoppingItem>('item_history');
      final localItems = box.values.toList();
      
      if (localItems.isEmpty) return;

      // Sync all items to cloud. 
      // FirestoreService.syncCustomItem is efficient enough (set merge).
      // Ideally we would only sync dirty items, but for "catch up" this is safe.
      for (final item in localItems) {
        // We can optionally check if it exists in cloud to save writes, 
        // but set() is idempotent.
        await ref.read(firestoreServiceProvider).syncCustomItem(user.uid, item);
      }
      print('Synced ${localItems.length} local items to cloud');
    } catch (e) {
      print('Error syncing local history to cloud: $e');
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      // Ensure we have the latest profile data (await future handles AsyncLoading)
      final userProfile = await ref.read(userProfileProvider.future);
      final isPremium = userProfile?.isPremium ?? false;
      
      if (!isPremium) return;

      // Fetch from Cloud
      final cloudItems = await ref.read(firestoreServiceProvider).getCustomItems(user.uid);
      if (cloudItems.isEmpty) return;

      final box = Hive.box<ShoppingItem>('item_history');
      bool changed = false;

      for (final item in cloudItems) {
        final key = item.name.trim().toLowerCase();
        // Only update if not exists (or could implement timestamp check later)
        if (!box.containsKey(key)) {
           await box.put(key, item);
           changed = true;
        }
      }

      if (changed) {
        state = box.values.toList();
      }
    } catch (e) {
      print('Error syncing history from cloud: $e');
    }
  }

  Future<void> addOrUpdate(ShoppingItem item) async {
    final box = Hive.box<ShoppingItem>('item_history');
    final key = item.name.trim().toLowerCase();
    
    await box.put(key, item);
    state = box.values.toList();

    // Cloud Sync (Premium)
    try {
      final user = ref.read(authServiceProvider).currentUser;
      
      // Await the profile to be sure we aren't in Loading state
      final userProfile = await ref.read(userProfileProvider.future);
      final isPremium = userProfile?.isPremium ?? false;
      
      if (user != null && isPremium) {
         await ref.read(firestoreServiceProvider).syncCustomItem(user.uid, item);
      }
    } catch (e) {
      // Silent fail for cloud sync (offline, etc)
      print('Cloud sync error for item: $e');
    }
  }
  Future<void> clear() async {
    final box = Hive.box<ShoppingItem>('item_history');
    await box.clear();
    state = [];
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, List<ShoppingItem>>((ref) {
  final notifier = HistoryNotifier(ref);
  
  // Listen to Auth State to handle Logout
  ref.listen(authStateProvider, (previous, next) {
    // If user Logs Out (next.value is null), clear history
    next.whenData((user) {
      if (user == null) {
        notifier.clear();
      }
    });
  });

  return notifier;
});
