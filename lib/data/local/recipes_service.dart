import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_market_list/data/models/recipe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<String?> getLastFetchedLanguage() async {
    // We can't easily inject SharedPreferences here without major refactor,
    // but we can use Hive since we already depend on it.
    // Let's assume there's a 'settings' box or we use the recipes box metadata if Hive supports it.
    // Actually, Hive boxes can store random key-values if they are not strictly typed or if we use a separate box.
    // Simpler: Just rely on the caller to handle logic? No, caller relies on Service.
    
    // Let's use a separate Hive box for settings if not existent, or just a static variable for session?
    // Session static variable is not enough for app restarts.
    
    // I'll use SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('recipes_last_lang');
  }

  Future<void> _saveFetchedLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recipes_last_lang', lang);
  }

  /// Fetches a specific page of recipes.
  Future<List<Recipe>> fetchRecipesPage({int page = 1, int limit = 10, String languageCode = 'pt'}) async {
    print('🚀 Buscando página $page (limit: $limit) na nova API (lang: $languageCode)...');
    try {
      // User requested: 
      // English -> https://api-receitas.kepoweb.com/recipes
      // Portuguese -> https://api-receitas.kepoweb.com/recipes?lang=pt
      
      String urlString = '$_baseUrl/recipes?page=$page&limit=$limit';
      if (languageCode == 'pt') {
        urlString += '&lang=pt';
      }
      
      final url = Uri.parse(urlString);
      print('🌐 Requesting: $url');
      
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Save the language we successfully fetched
        await _saveFetchedLanguage(languageCode);

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
  Future<List<Recipe>> searchRecipes(String query, {String languageCode = 'pt'}) async {
    if (query.length < 2) return [];
    print('🔎 Buscando por "$query" (lang: $languageCode)...');
    try {
      String urlString = '$_baseUrl/recipes/search?q=$query';
      if (languageCode == 'pt') {
        urlString += '&lang=pt';
      }
      final url = Uri.parse(urlString);
      print('🌐 Searching: $url');
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

