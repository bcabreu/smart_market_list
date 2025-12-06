import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_market_list/data/models/recipe.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

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

  Future<void> clearRecipes() async {
    await _box.clear();
    print('🧹 Banco de dados limpo manualmente.');
  }

  static const String _baseUrl = 'https://api-receitas.kepoweb.com';

  /// Fetches a specific page of recipes.
  Future<List<Recipe>> fetchRecipesPage({int page = 1, int limit = 10}) async {
    print('🚀 Buscando página $page (limit: $limit) na nova API...');
    try {
      final url = Uri.parse('$_baseUrl/recipes?page=$page&limit=$limit&lang=pt');
      
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        
        print('📦 Recebidos ${data.length} itens da API.');
        
        final List<Recipe> recipes = [];

        for (var item in data) {
          try {
            // Handle Image URL (Relative vs Absolute)
            String imageUrl = item['imageUrl'] ?? '';
            if (imageUrl.startsWith('/')) {
              imageUrl = '$_baseUrl$imageUrl';
            }

            final recipe = Recipe(
              id: item['id'],
              name: item['name'] ?? 'Sem nome',
              imageUrl: imageUrl,
              ingredients: List<String>.from(item['ingredients'] ?? []),
              instructions: List<String>.from(item['instructions'] ?? []),
              prepTime: item['prepTime'] ?? 30,
              difficulty: item['difficulty'] ?? 'Médio',
              servings: item['servings'] ?? 2,
              likes: item['likes'] ?? 0,
            );
            
            recipes.add(recipe);
            // Cache immediately to Hive
            await _box.put(recipe.id, recipe);
            
          } catch (e) {
            print('⚠️ Erro ao processar item: $e');
          }
        }
        return recipes;
      } else {
        print('❌ Erro API: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('🔥 Erro de conexão: $e');
      return [];
    }
  }

  /// Searches recipes by query.
  Future<List<Recipe>> searchRecipes(String query) async {
    if (query.length < 2) return [];
    print('🔎 Buscando por "$query"...');
    try {
      final url = Uri.parse('$_baseUrl/recipes/search?q=$query&lang=pt');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final dynamic decoded = json.decode(body);
        
        List<dynamic> items = [];
        if (decoded is Map && decoded.containsKey('data')) {
           items = decoded['data'] ?? [];
        } else if (decoded is List) {
           items = decoded;
        }

        final List<Recipe> recipes = [];
         for (var item in items) {
            String imageUrl = item['imageUrl'] ?? '';
            if (imageUrl.startsWith('/')) {
              imageUrl = '$_baseUrl$imageUrl';
            }
            recipes.add(Recipe(
              id: item['id'],
              name: item['name'] ?? 'Sem nome',
              imageUrl: imageUrl,
              ingredients: List<String>.from(item['ingredients'] ?? []),
              instructions: List<String>.from(item['instructions'] ?? []),
              prepTime: item['prepTime'] ?? 30,
              difficulty: item['difficulty'] ?? 'Médio',
              servings: item['servings'] ?? 2,
              likes: item['likes'] ?? 0,
            ));
         }
         return recipes;
      }
    } catch (e) {
      print('Erro na busca: $e');
    }
    return [];
  } 

  // Legacy method removed/replaced by above.
  /*
  Future<List<Recipe>> fetchRecipeBatch...
  */
}

