import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/backend_service.dart';
import '../../core/utils/item_name_formatter.dart';

typedef ItemHistoryWriter = Future<void> Function(ShoppingItem item);

class ShoppingListService {
  final Box<ShoppingList> _box;
  final FirestoreService? _firestoreService;
  final BackendService? _backendService;
  final ItemHistoryWriter? _historyWriter;

  // Track current family ID for sync
  String? _currentFamilyId;
  String? _currentUid;
  bool _syncFamilyLists = false;
  int _syncGeneration = 0;
  StreamSubscription? _familySubscription;
  StreamSubscription? _sharedSubscription;

  ShoppingListService(
    this._box, [
    this._firestoreService,
    this._backendService,
    this._historyWriter,
  ]);

  // Track if initial sync (first cloud snapshot) has arrived
  final ValueNotifier<bool> listsSyncedNotifier = ValueNotifier(false);

  // Start syncing with a specific family and user
  Future<void> startSync(
    String familyId,
    String uid, {
    required bool syncFamilyLists,
    bool clearWorkspaceCache = false,
  }) async {
    if (_currentFamilyId == familyId &&
        _currentUid == uid &&
        _syncFamilyLists == syncFamilyLists) {
      return;
    }
    _currentFamilyId = familyId;
    _currentUid = uid;
    _syncFamilyLists = syncFamilyLists;
    final generation = ++_syncGeneration;

    _familySubscription?.cancel();
    _sharedSubscription?.cancel();

    // Once the personal subscription expires, detach the cached workspace
    // from its former cloud path. It remains fully usable on this device and
    // can be uploaded again if Premium is reactivated later.
    if (!syncFamilyLists && !clearWorkspaceCache) {
      final personalLists = _box.values
          .where(
            (list) =>
                list.familyId == familyId &&
                (list.ownerId == null || list.ownerId == uid),
          )
          .toList();
      for (final list in personalLists) {
        await _box.put(
          list.id,
          list.copyWith(clearFamilyId: true, members: [uid]),
        );
      }
    }

    // An expired Family guest must not retain a readable local copy of the
    // complete shared workspace while waiting for webhook/scheduler cleanup.
    // Explicitly shared lists are re-added below from the membership index.
    if (clearWorkspaceCache) {
      final workspaceListIds = _box.values
          .where((list) => list.familyId == familyId)
          .map((list) => list.id)
          .toList();
      await _box.deleteAll(workspaceListIds);
    }
    if (generation != _syncGeneration) return;

    // Reset sync status. Cloud is read before any local-only list is migrated.
    // IMPORTANT: Do NOT sync local→cloud here! Cloud is the source of truth.
    // Syncing local data before receiving cloud updates would overwrite
    // items added by other family members while this app was closed.
    if (_firestoreService != null) {
      listsSyncedNotifier.value = false; // Reset sync status
    }

    // 2. Listen for personal/family workspace lists only while Premium.
    if (_firestoreService != null && syncFamilyLists) {
      _familySubscription = _firestoreService
          .getFamilyLists(familyId)
          .listen(
            (cloudLists) async {
              final localBeforeCloud = _box.values.toList();
              final localOnlyById = {
                for (final list in localBeforeCloud.where(
                  (list) =>
                      list.familyId == null &&
                      (list.ownerId == null || list.ownerId == uid),
                ))
                  list.id: list,
              };
              final cloudIds = cloudLists.map((l) => l.id).toSet();

              // A list detached after Premium expired is the authoritative
              // device copy. This also protects edits made during the cleanup
              // grace period from being overwritten by stale cloud data.
              for (final cloudList in cloudLists) {
                final preservedLocal = localOnlyById[cloudList.id];
                if (preservedLocal != null) {
                  final migrated = preservedLocal.copyWith(
                    familyId: familyId,
                    ownerId: preservedLocal.ownerId ?? uid,
                  );
                  await _box.put(migrated.id, migrated);
                  await _firestoreService.syncList(familyId, migrated);
                } else {
                  await _box.put(cloudList.id, cloudList);
                }
              }

              // Lists created while Free have no cloud counterpart yet.
              for (final local in localOnlyById.values) {
                if (cloudIds.contains(local.id)) continue;
                final migrated = local.copyWith(
                  familyId: familyId,
                  ownerId: local.ownerId ?? uid,
                );
                await _box.put(migrated.id, migrated);
                await _firestoreService.syncList(familyId, migrated);
              }

              // Handle deletions for cloud-backed lists only. Detached local
              // lists are intentionally retained and migrated above.
              final localLists = _box.values.toList();
              for (var local in localLists) {
                // Check if it belongs to the current family (Primary)
                // Treats null familyId as current/primary for backward compatibility if needed,
                // or strictly checks match if familyId is set.
                final isAndShouldBeInFamily = local.familyId == familyId;

                if (isAndShouldBeInFamily && !cloudIds.contains(local.id)) {
                  await _box.delete(local.id);
                }
              }

              // Mark as Synced (at least family lists)
              listsSyncedNotifier.value = true;
            },
            onError: (e) {
              debugPrint('❌ Error syncing family lists: $e');
              // If error, we might still want to say "done" so we don't hang?
              // Or keep loading? Default to true so user sees local data at least.
              listsSyncedNotifier.value = true;
            },
          );
    } else {
      listsSyncedNotifier.value = true;
    }

    // 3. Shared-list sync remains available to authenticated Free guests.
    if (_firestoreService != null) {
      _sharedSubscription = _firestoreService
          .getSharedLists(uid)
          .listen(
            (sharedLists) async {
              // Sync Updates
              for (var list in sharedLists) {
                // Shared lists come with familyId populated from FirestoreService
                await _box.put(list.id, list);
              }

              // Handle Deletions (Local lists that are SHARED but NOT in cloud)
              final cloudSharedIds = sharedLists.map((l) => l.id).toSet();
              final localLists = _box.values.toList();

              for (var local in localLists) {
                // It is a shared list if its familyId is DIFFERENT from the current User's familyId
                // (and isn't null, assuming null defaults to primary)
                final isSharedList =
                    local.familyId != null && local.familyId != familyId;

                if (isSharedList && !cloudSharedIds.contains(local.id)) {
                  await _box.delete(local.id);
                }
              }
            },
            onError: (e) {
              debugPrint('❌ Error syncing shared lists: $e');
            },
          );
    }
  }

  void stopSync() {
    _syncGeneration++;
    _familySubscription?.cancel();
    _sharedSubscription?.cancel();
    _currentFamilyId = null;
    _currentUid = null;
    _syncFamilyLists = false;
    listsSyncedNotifier.value = false;
  }

  List<ShoppingList> getAllLists() {
    return _box.values.toList();
  }

  Future<void> createList(ShoppingList list) async {
    // New lists default to current family
    final listWithFamily = list.copyWith(
      familyId: list.familyId ?? (_syncFamilyLists ? _currentFamilyId : null),
      ownerId: list.ownerId ?? _currentUid,
      members: (list.members.isEmpty && _currentUid != null)
          ? [_currentUid!]
          : list.members,
    );

    await _box.put(listWithFamily.id, listWithFamily);
    await _syncToCloud(listWithFamily);
  }

  Future<void> updateList(ShoppingList list) async {
    await _box.put(list.id, list);
    final targetFamilyId = _cloudFamilyFor(list);
    if (targetFamilyId != null && _firestoreService != null) {
      await _firestoreService.updateListMetadata(targetFamilyId, list);
    }
  }

  Future<void> deleteList(String id) async {
    final list = _box.get(id);
    final targetFamilyId = list == null ? null : _cloudFamilyFor(list);

    if (list != null) {
      for (final item in list.items) {
        await _rememberItem(item);
      }
    }

    // Always remove from local box instantly
    await _box.delete(id);

    if (targetFamilyId != null && _firestoreService != null) {
      // Check ownership: current user is owner if their UID matches the list's ownerId
      // OR if the list has no ownerId (legacy/personal lists)
      final isOwner = list?.ownerId == null || list?.ownerId == _currentUid;

      if (isOwner) {
        // Owner: Hard delete
        await _firestoreService.deleteList(targetFamilyId, id);
      } else {
        // Guest: Just leave the list (remove from members)
        if (_currentUid != null && _backendService != null) {
          await _backendService.removeListMember(
            familyId: targetFamilyId,
            listId: id,
          );
        }
      }
    }
  }

  Future<void> addItem(String listId, ShoppingItem item) async {
    final list = _box.get(listId);
    if (list != null) {
      final normalizedItem = _normalizeItem(item);
      final newItems = List<ShoppingItem>.from(list.items)..add(normalizedItem);
      final newList = list.copyWith(items: newItems);
      await _box.put(listId, newList);
      await _rememberItem(normalizedItem);
      final targetFamilyId = _cloudFamilyFor(newList);
      if (targetFamilyId != null && _firestoreService != null) {
        await _firestoreService.addItemsToList(targetFamilyId, listId, [
          normalizedItem,
        ]);
      }
    }
  }

  Future<void> addItems(String listId, List<ShoppingItem> items) async {
    final list = _box.get(listId);
    if (list == null || items.isEmpty) return;
    final normalizedItems = items.map(_normalizeItem).toList();
    final newList = list.copyWith(items: [...list.items, ...normalizedItems]);
    await _box.put(listId, newList);
    for (final item in normalizedItems) {
      await _rememberItem(item);
    }
    final targetFamilyId = _cloudFamilyFor(newList);
    if (targetFamilyId != null && _firestoreService != null) {
      await _firestoreService.addItemsToList(
        targetFamilyId,
        listId,
        normalizedItems,
      );
    }
  }

  Future<void> updateItem(String listId, ShoppingItem item) async {
    final list = _box.get(listId);
    if (list != null) {
      final normalizedItem = _normalizeItem(item);
      final newItems = List<ShoppingItem>.from(list.items);
      final index = newItems.indexWhere((i) => i.id == normalizedItem.id);
      if (index != -1) {
        newItems[index] = normalizedItem;
        final newList = list.copyWith(items: newItems);
        await _box.put(listId, newList);
        await _rememberItem(normalizedItem);
        final targetFamilyId = _cloudFamilyFor(newList);
        if (targetFamilyId != null && _firestoreService != null) {
          await _firestoreService.updateListItem(
            targetFamilyId,
            listId,
            normalizedItem,
          );
        }
      }
    }
  }

  Future<void> removeItem(String listId, String itemId) async {
    final list = _box.get(listId);
    if (list != null) {
      final removedItem = list.items
          .where((item) => item.id == itemId)
          .firstOrNull;
      if (removedItem != null) {
        await _rememberItem(removedItem);
      }
      final newItems = List<ShoppingItem>.from(list.items)
        ..removeWhere((i) => i.id == itemId);
      final newList = list.copyWith(items: newItems);
      await _box.put(listId, newList);
      final targetFamilyId = _cloudFamilyFor(newList);
      if (targetFamilyId != null && _firestoreService != null) {
        await _firestoreService.removeListItem(targetFamilyId, listId, itemId);
      }
    }
  }

  Future<void> restoreCompletedItems(String listId) async {
    final list = _box.get(listId);
    if (list != null) {
      final newItems = list.items.map((item) {
        if (item.checked) {
          return item.copyWith(checked: false, statusChangedAt: DateTime.now());
        }
        return item;
      }).toList();
      final newList = list.copyWith(items: newItems);
      await _box.put(listId, newList);
      final targetFamilyId = _cloudFamilyFor(newList);
      if (targetFamilyId != null && _firestoreService != null) {
        await _firestoreService.restoreCompletedListItems(
          targetFamilyId,
          listId,
        );
      }
    }
  }

  Future<void> removeCompletedItems(String listId) async {
    final list = _box.get(listId);
    if (list != null) {
      for (final item in list.items.where((item) => item.checked)) {
        await _rememberItem(item);
      }
      final newItems = List<ShoppingItem>.from(list.items)
        ..removeWhere((i) => i.checked);
      final newList = list.copyWith(items: newItems);
      await _box.put(listId, newList);
      final targetFamilyId = _cloudFamilyFor(newList);
      if (targetFamilyId != null && _firestoreService != null) {
        await _firestoreService.removeCompletedListItems(
          targetFamilyId,
          listId,
        );
      }
    }
  }

  Future<void> deleteAllData() async {
    // Clear Shopping Lists
    try {
      await _box.clear();
    } catch (e) {
      debugPrint('Error clearing shopping lists: $e');
    }

    // Clear Item History
    try {
      if (Hive.isBoxOpen('item_history')) {
        final historyBox = Hive.box<ShoppingItem>('item_history');
        await historyBox.clear();
      }
    } catch (e) {
      debugPrint('Error clearing item history: $e');
    }

    // Clear Hidden Suggestions
    try {
      if (Hive.isBoxOpen('hidden_suggestions')) {
        final hiddenBox = Hive.box<String>('hidden_suggestions');
        await hiddenBox.clear();
      }
    } catch (e) {
      debugPrint('Error clearing hidden suggestions: $e');
    }
  }

  Future<void> _syncToCloud(ShoppingList list) async {
    final targetFamilyId = _cloudFamilyFor(list);
    if (targetFamilyId != null && _firestoreService != null) {
      final listToSync = list.familyId == null
          ? list.copyWith(familyId: targetFamilyId)
          : list;
      await _firestoreService.syncList(targetFamilyId, listToSync);
    }
  }

  String? _cloudFamilyFor(ShoppingList list) {
    final targetFamilyId = list.familyId ?? _currentFamilyId;
    final isSharedList =
        list.familyId != null && list.familyId != _currentFamilyId;
    if (targetFamilyId == null || (!_syncFamilyLists && !isSharedList)) {
      return null;
    }
    return targetFamilyId;
  }

  ShoppingItem _normalizeItem(ShoppingItem item) {
    return item.copyWith(name: formatItemName(item.name));
  }

  Future<void> _rememberItem(ShoppingItem item) async {
    if (_historyWriter == null) return;
    try {
      await _historyWriter(_normalizeItem(item));
    } catch (error) {
      debugPrint('Error saving item price history: $error');
    }
  }
}
