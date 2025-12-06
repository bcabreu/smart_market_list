import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiddenSuggestionsNotifier extends StateNotifier<List<String>> {
  HiddenSuggestionsNotifier() : super([]) {
    _loadHiddenSuggestions();
  }

  Future<void> _loadHiddenSuggestions() async {
    final box = Hive.box<String>('hidden_suggestions');
    state = box.values.toList();
  }

  Future<void> add(String name) async {
    final box = Hive.box<String>('hidden_suggestions');
    if (!box.values.contains(name)) {
      await box.add(name);
      state = [...state, name];
    }
  }

  Future<void> unhide(String name) async {
    final box = Hive.box<String>('hidden_suggestions');
    final Map<dynamic, String> deletions = {};
    
    // Find keys to delete (box.values doesn't give keys directly, need to iterate)
    for (var key in box.keys) {
      if (box.get(key) == name) {
        deletions[key] = name;
      }
    }

    if (deletions.isNotEmpty) {
      await box.deleteAll(deletions.keys);
      state = box.values.toList();
    }
  }
}

final hiddenSuggestionsProvider = StateNotifierProvider<HiddenSuggestionsNotifier, List<String>>((ref) {
  return HiddenSuggestionsNotifier();
});
