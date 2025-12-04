import 'package:hive_flutter/hive_flutter.dart';
import '../models/recipe.dart';

class RecipesService {
  final Box<Recipe> _box;

  RecipesService(this._box);

  List<Recipe> getAllRecipes() {
    return _box.values.toList();
  }

  Future<void> createRecipe(Recipe recipe) async {
    await _box.put(recipe.id, recipe);
  }

  Future<void> toggleFavorite(String id) async {
    final recipe = _box.get(id);
    if (recipe != null) {
      recipe.isFavorite = !recipe.isFavorite;
      await recipe.save();
    }
  }

  // Populate initial recipes if empty
  Future<void> populateInitialRecipes() async {
    if (_box.isEmpty) {
      final initialRecipes = [
        Recipe(
          name: 'Lasanha à Bolonhesa',
          imageUrl: 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=600',
          ingredients: ['Massa de lasanha', 'Carne moída', 'Molho de tomate', 'Queijo', 'Presunto'],
          instructions: ['Cozinhe a massa', 'Prepare o molho', 'Monte as camadas', 'Asse por 40 min'],
          prepTime: 60,
          difficulty: 'Médio',
          likes: 156,
        ),
        Recipe(
          name: 'Bolo de Chocolate',
          imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600',
          ingredients: ['Farinha', 'Açúcar', 'Chocolate em pó', 'Ovos', 'Leite'],
          instructions: ['Misture tudo', 'Asse por 40 min', 'Faça a cobertura'],
          prepTime: 50,
          difficulty: 'Fácil',
          likes: 234,
        ),
        Recipe(
          name: 'Salada Caesar',
          imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',
          ingredients: ['Alface', 'Croutons', 'Queijo Parmesão', 'Molho Caesar', 'Frango'],
          instructions: ['Lave a alface', 'Grelhe o frango', 'Misture tudo'],
          prepTime: 20,
          difficulty: 'Fácil',
          likes: 89,
        ),
        Recipe(
          name: 'Sopa de Legumes',
          imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600',
          ingredients: ['Batata', 'Cenoura', 'Cebola', 'Caldo de legumes'],
          instructions: ['Corte os legumes', 'Cozinhe no caldo', 'Tempere a gosto'],
          prepTime: 40,
          difficulty: 'Fácil',
          likes: 112,
        ),
      ];
      
      for (var recipe in initialRecipes) {
        await _box.put(recipe.id, recipe);
      }
    }
  }
}
