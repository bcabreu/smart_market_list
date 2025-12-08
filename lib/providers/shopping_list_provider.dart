import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/shopping_list_service.dart';
import '../data/models/shopping_list.dart';
import '../core/services/firestore_service.dart';
import 'user_profile_provider.dart';
import 'shopping_notes_provider.dart';
import 'recipes_provider.dart';

final shoppingListBoxProvider = Provider<Box<ShoppingList>>((ref) {
  return Hive.box<ShoppingList>('shopping_lists');
});

final shoppingListServiceProvider = Provider<ShoppingListService>((ref) {
  final box = ref.watch(shoppingListBoxProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ShoppingListService(box, firestoreService);
});

final shoppingListsProvider = StreamProvider<List<ShoppingList>>((ref) {
  final box = ref.watch(shoppingListBoxProvider);
  // Return initial values and listen to changes
  return box.watch().map((event) => box.values.toList()).startWith(box.values.toList());
});

final currentListIdProvider = StateProvider<String?>((ref) => null);

final currentListProvider = Provider<ShoppingList?>((ref) {
  final listsAsync = ref.watch(shoppingListsProvider);
  final currentId = ref.watch(currentListIdProvider);
  
  return listsAsync.when(
    data: (lists) {
      if (lists.isEmpty) return null;
      if (currentId == null) return lists.first;
      return lists.firstWhere((l) => l.id == currentId, orElse: () => lists.first);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});



final syncManagerProvider = Provider<void>((ref) {
  final userProfileAsync = ref.watch(userProfileProvider);
  final shoppingListService = ref.watch(shoppingListServiceProvider);
  final notesService = ref.watch(shoppingNotesServiceProvider);
  final recipesService = ref.watch(recipesServiceProvider);
  
  userProfileAsync.whenData((profile) {
    if (profile?.familyId != null && profile?.isPremium == true) {
      shoppingListService.startSync(profile!.familyId!);
      notesService.startSync(profile!.familyId!);
      recipesService.startSync(profile!.familyId!);
    } else {
      shoppingListService.stopSync();
      notesService.stopSync();
      recipesService.stopSync();
    }
  });
});
