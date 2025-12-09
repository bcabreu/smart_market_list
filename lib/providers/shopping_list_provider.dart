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
    if (profile?.familyId != null) {
      // Logic: Sync is enabled for Premium users (or everyone? User said Premium shares, but Free joins).
      // If I am Free, I can still have lists synced if they are shared with me?
      // `startSync` logic inside `ShoppingListService` handles both Family (Personal) and Shared.
      // If I am Free, maybe I don't get Family Sync but I GET Shared Sync?
      // For now, enable sync for Valid Users (Guest or Auth).
      
      // Pass UID to startSync
      shoppingListService.startSync(profile!.familyId!, profile.uid);
      
      // Notes/Recipes might still check premium inside their services or here?
      // Assuming Notes/Recipes are premium features or restricted.
      // Keeping original check if desired, but user wants "Free user to see the list".
      // So sync MUST be active for Free users too regarding SHARED lists.
      
      // Re-evaluating logic:
      // Old logic: if (premium) startSync.
      // New logic: ALWAYS startSync to get Shared Lists.
      // BUT `getFamilyLists` might be restricted on server side or client side if we want.
      // The user prompt implies: "Free user ... sees the list".
      // So we should enable sync for all users who have a familyId (which guests do).
      
      if (profile.isPremium) {
         notesService.startSync(profile.familyId!);
         recipesService.startSync(profile.familyId!);
      } else {
         notesService.stopSync();
         recipesService.stopSync();
      }
    } else {
      shoppingListService.stopSync();
      notesService.stopSync();
      recipesService.stopSync();
    }
  });
});
