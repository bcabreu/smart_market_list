import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Key: List ID, Value: List of emails
final sharedUsersBoxProvider = Provider<Box<List<String>>>((ref) {
  return Hive.box<List<String>>('list_shared_users');
});

final sharedUsersProvider = StateNotifierProvider<SharedUsersNotifier, Map<String, List<String>>>((ref) {
  final box = ref.watch(sharedUsersBoxProvider);
  return SharedUsersNotifier(box);
});

class SharedUsersNotifier extends StateNotifier<Map<String, List<String>>> {
  final Box<List<String>> _box;

  SharedUsersNotifier(this._box) : super({}) {
    _loadInitialData();
  }

  void _loadInitialData() {
    final Map<String, List<String>> initialData = {};
    for (var key in _box.keys) {
      initialData[key.toString()] = _box.get(key) ?? [];
    }
    state = initialData;
  }

  Future<void> addUser(String listId, String email) async {
    final currentUsers = List<String>.from(state[listId] ?? []);
    if (!currentUsers.contains(email)) {
      currentUsers.add(email);
      // Update state
      state = {...state, listId: currentUsers};
      // Persist
      await _box.put(listId, currentUsers);
    }
  }

  Future<void> removeUser(String listId, String email) async {
    final currentUsers = List<String>.from(state[listId] ?? []);
    if (currentUsers.contains(email)) {
      currentUsers.remove(email);
      // Update state
      state = {...state, listId: currentUsers};
      // Persist
      await _box.put(listId, currentUsers);
    }
  }

  List<String> getUsers(String listId) {
    return state[listId] ?? [];
  }
}
