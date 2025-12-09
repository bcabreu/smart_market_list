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
    _syncFromCloud(); // Fire and forget
  }

  Future<void> _syncFromCloud() async {
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      final isPremium = ref.read(userProfileProvider).value?.isPremium ?? false;
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
      final isPremium = ref.read(userProfileProvider).value?.isPremium ?? false;
      
      if (user != null && isPremium) {
         ref.read(firestoreServiceProvider).syncCustomItem(user.uid, item);
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
