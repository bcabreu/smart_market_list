import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/recipes_service.dart';
import '../data/models/recipe.dart';

final recipesBoxProvider = Provider<Box<Recipe>>((ref) {
  return Hive.box<Recipe>('recipes');
});

final recipesServiceProvider = Provider<RecipesService>((ref) {
  final box = ref.watch(recipesBoxProvider);
  return RecipesService(box);
});

final recipesProvider = StreamProvider<List<Recipe>>((ref) {
  final box = ref.watch(recipesBoxProvider);
  final service = ref.watch(recipesServiceProvider);
  
  // Ensure data is refreshed from API


  return box.watch().map((event) => box.values.toList()).startWith(box.values.toList());
});
