import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_market_list/core/utils/item_name_formatter.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';

import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';

class HistoryNotifier extends StateNotifier<List<ShoppingItem>> {
  final Ref ref;
  bool _cloudSyncInProgress = false;

  HistoryNotifier(this.ref) : super([]) {
    unawaited(_loadHistory());
  }

  Future<void> _loadHistory() async {
    final box = Hive.box<ShoppingItem>('item_history');
    state = box.values.toList();
    await synchronizeCloud();
  }

  Future<void> synchronizeCloud() async {
    if (_cloudSyncInProgress) return;
    _cloudSyncInProgress = true;

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      final userProfile = await ref.read(userProfileProvider.future);
      final isPremium = userProfile?.isPremium ?? false;
      if (!isPremium) return;

      final box = Hive.box<ShoppingItem>('item_history');
      final cloudItems = await ref
          .read(firestoreServiceProvider)
          .getCustomItems(user.uid);
      final cloudItemsByName = <String, ShoppingItem>{
        for (final item in cloudItems) item.name.trim().toLowerCase(): item,
      };
      bool changed = false;

      for (final item in cloudItems) {
        final key = item.name.trim().toLowerCase();
        final localItem = box.get(key);
        if (localItem == null ||
            item.historyTimestamp.isAfter(localItem.historyTimestamp)) {
          await box.put(key, item);
          changed = true;
        }
      }

      if (changed) {
        state = box.values.toList();
      }

      // Upload only after merging the cloud copy so an older local value never
      // overwrites a newer price from another device.
      for (final item in box.values) {
        final cloudItem = cloudItemsByName[item.name.trim().toLowerCase()];
        if (cloudItem == null ||
            item.historyTimestamp.isAfter(cloudItem.historyTimestamp)) {
          await ref
              .read(firestoreServiceProvider)
              .syncCustomItem(user.uid, item);
        }
      }
    } catch (e) {
      print('Error synchronizing item history: $e');
    } finally {
      _cloudSyncInProgress = false;
    }
  }

  Future<void> addOrUpdate(ShoppingItem item) async {
    final box = Hive.box<ShoppingItem>('item_history');
    final historyItem = item.copyWith(
      name: formatItemName(item.name),
      historyUpdatedAt: DateTime.now(),
    );
    final key = historyItem.name.trim().toLowerCase();

    await box.put(key, historyItem);
    state = box.values.toList();

    // Cloud Sync (Premium)
    try {
      final user = ref.read(authServiceProvider).currentUser;

      // Await the profile to be sure we aren't in Loading state
      final userProfile = await ref.read(userProfileProvider.future);
      final isPremium = userProfile?.isPremium ?? false;

      if (user != null && isPremium) {
        await ref
            .read(firestoreServiceProvider)
            .syncCustomItem(user.uid, historyItem);
      }
    } catch (e) {
      // Silent fail for cloud sync (offline, etc)
      print('Cloud sync error for item: $e');
    }
  }

  Future<void> remove(String itemName) async {
    final box = Hive.box<ShoppingItem>('item_history');
    final key = itemName.trim().toLowerCase();

    if (box.containsKey(key)) {
      await box.delete(key);
      state = box.values.toList();
    }

    // Cloud Sync (Premium) - Delete
    try {
      final user = ref.read(authServiceProvider).currentUser;
      final userProfile = await ref.read(userProfileProvider.future);
      final isPremium = userProfile?.isPremium ?? false;

      if (user != null && isPremium) {
        // No need to check system item here, as removing it from cloud is fine (if it ended up there by mistake, we want to delete it)
        await ref
            .read(firestoreServiceProvider)
            .deleteCustomItem(user.uid, itemName);
      }
    } catch (e) {
      print('Cloud sync error (delete) for item: $e');
    }
  }

  Future<void> clear() async {
    final box = Hive.box<ShoppingItem>('item_history');
    await box.clear();
    state = [];
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<ShoppingItem>>((ref) {
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

      // A Free user's history remains local. When Premium becomes active again,
      // synchronize that retained history (including the latest saved prices).
      ref.listen(userProfileProvider, (previous, next) {
        next.whenData((profile) {
          if (profile?.isPremium == true) {
            unawaited(notifier.synchronizeCloud());
          }
        });
      });

      return notifier;
    });
