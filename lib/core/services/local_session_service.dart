import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_market_list/data/models/recipe.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:smart_market_list/data/models/shopping_note.dart';

/// Removes account-scoped data from the shared local boxes.
///
/// The app historically used global Hive boxes, so retaining them after an
/// account change could expose one account's data to the next account on the
/// same device. Cloud data is downloaded again after the next authenticated
/// session starts.
class LocalSessionService {
  static const _activeAccountKey = 'active_account_uid';

  /// Clears data left by another account before syncing the current one.
  ///
  /// On an upgrade from older app versions there is no stored UID yet, so the
  /// existing local data is preserved and associated with the current user.
  static Future<void> activateUser(String uid) async {
    final settings = await _settingsBox();
    final activeUid = settings.get(_activeAccountKey) as String?;
    if (activeUid != null && activeUid != uid) {
      await clearAccountData(createDefaultList: false);
    }
    await settings.put(_activeAccountKey, uid);
  }

  static Future<void> clearAccountData({bool createDefaultList = true}) async {
    await _clearBox<ShoppingList>('shopping_lists');
    await _clearBox<ShoppingNote>('shopping_notes');
    await _clearBox<Recipe>('recipes');
    await _clearBox<ShoppingItem>('item_history');
    await _clearBox<String>('hidden_suggestions');
    await _clearBox<List<String>>('categories');
    await _clearBox<double>('expense_goals');
    await _clearBox<List<String>>('list_shared_users');

    final settings = await _settingsBox();
    await settings.deleteAll([
      _activeAccountKey,
      'default_list_id',
      'paywall_item_counter',
      'app_open_counter',
    ]);
    await _clearIdentityPreferences();

    if (createDefaultList && Hive.isBoxOpen('shopping_lists')) {
      final lists = Hive.box<ShoppingList>('shopping_lists');
      final defaultList = ShoppingList(
        name: 'Compras do Mês',
        emoji: '🛒',
        budget: 500,
      );
      await lists.put(defaultList.id, defaultList);
      await settings.put('default_list_id', defaultList.id);
    }
  }

  static Future<Box<dynamic>> _settingsBox() async {
    if (Hive.isBoxOpen('settings')) return Hive.box('settings');
    return Hive.openBox('settings');
  }

  static Future<void> _clearIdentityPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final imagePath = preferences.getString('profile_image_path');
    if (imagePath != null && !imagePath.startsWith('http')) {
      try {
        final image = File(imagePath);
        if (await image.exists()) await image.delete();
      } on FileSystemException {
        // Preference removal below is sufficient if the old file is gone or
        // cannot be accessed anymore.
      }
    }
    for (final key in const [
      'is_logged_in',
      'user_email',
      'user_name',
      'profile_image_path',
      'premium_since',
    ]) {
      await preferences.remove(key);
    }
  }

  static Future<void> _clearBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      await Hive.box<T>(name).clear();
    }
  }
}
