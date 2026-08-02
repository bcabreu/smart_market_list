import 'dart:convert';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_market_list/data/models/recipe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';

class RecipesService {
  final Box<Recipe> _box;
  final FirestoreService? _firestoreService;

  String? _currentFamilyId;
  StreamSubscription? _cloudSubscription;

  RecipesService(this._box, [this._firestoreService]);

  List<Recipe> getAllRecipes() {
    return _box.values.toList();
  }

  Future<void> createRecipe(Recipe recipe) async {
    await _box.put(recipe.id, recipe);
  }

  // --- Cloud Sync ---

  Future<void> startSync(String familyId) async {
    print('🔄 RECIPES SYNC: Starting for family $familyId');
    if (_currentFamilyId == familyId) return;
    _currentFamilyId = familyId;
    _cloudSubscription?.cancel();

    if (_firestoreService == null) {
      print('❌ RECIPES SYNC: FirestoreService is null');
      return;
    }

    // Cloud is the initial source of truth so a remote unfavorite is not
    // recreated by stale local cache on startup.
    print('🎧 RECIPES SYNC: Listening for cloud updates...');
    _cloudSubscription = _firestoreService.getFavoriteRecipes(familyId).listen((
      cloudRecipesData,
    ) async {
      print(
        '⬇️ RECIPES SYNC: Received ${cloudRecipesData.length} recipes from cloud',
      );

      // Create set of cloud favorite IDs for efficient lookup
      final cloudFavIds = cloudRecipesData.map((d) => d['id']).toSet();

      // Handle incoming favorites
      for (var data in cloudRecipesData) {
        try {
          final cloudRecipe = Recipe.fromMap(data);
          final localRecipe = _box.get(cloudRecipe.id);

          if (localRecipe != null) {
            // Update local if different or just mark as favorite
            if (!localRecipe.isFavorite) {
              print('   -> Marking local "${localRecipe.name}" as favorite');
              localRecipe.isFavorite = true;
              await localRecipe.save();
            }
          } else {
            // New recipe from cloud (favorite on another device)
            print('   -> Saving new "${cloudRecipe.name}" from cloud');
            await _box.put(cloudRecipe.id, cloudRecipe);
          }
        } catch (e) {
          print('❌ RECIPES SYNC ERROR: $e');
        }
      }

      for (final localRecipe in _box.values) {
        if (localRecipe.isFavorite && !cloudFavIds.contains(localRecipe.id)) {
          localRecipe.isFavorite = false;
          await localRecipe.save();
        }
      }
    });
  }

  Future<void> stopSync({bool clearFamilyFavorites = false}) async {
    await _cloudSubscription?.cancel();
    _currentFamilyId = null;
    if (clearFamilyFavorites) {
      for (final recipe in _box.values) {
        if (recipe.isFavorite) {
          recipe.isFavorite = false;
          await recipe.save();
        }
      }
    }
  }

  // --- Actions ---

  Future<void> toggleFavorite(String id) async {
    final recipe = _box.get(id);
    if (recipe != null) {
      recipe.isFavorite = !recipe.isFavorite;
      await recipe.save();

      // Cloud Sync
      if (_currentFamilyId != null && _firestoreService != null) {
        if (recipe.isFavorite) {
          await _firestoreService.syncFavoriteRecipe(
            _currentFamilyId!,
            recipe.toMap(),
          );
        } else {
          await _firestoreService.removeFavoriteRecipe(_currentFamilyId!, id);
        }
      }
    }
  }

  Future<void> deleteAllData() async {
    await stopSync();
    await _box.clear();
    print('🧹 Receitas locais apagadas.');
  }

  // Alias for backward compatibility
  Future<void> clearRecipes() => deleteAllData();

  static const String _baseUrl = 'https://api-receitas.kepoweb.com';
  static const Duration _requestTimeout = Duration(seconds: 15);

  Future<String?> getLastFetchedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('recipes_last_lang');
  }

  Future<void> _saveFetchedLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recipes_last_lang', lang);
  }

  /// Fetches a specific page of recipes.
  Future<List<Recipe>> fetchRecipesPage({
    int page = 1,
    int limit = 10,
    String languageCode = 'pt',
  }) async {
    print(
      '🚀 Buscando página $page (limit: $limit) na nova API (lang: $languageCode)...',
    );
    try {
      final url = Uri.parse('$_baseUrl/recipes').replace(
        queryParameters: {
          'page': '$page',
          'limit': '$limit',
          if (languageCode == 'pt') 'lang': 'pt',
        },
      );
      print('🌐 Requesting: $url');

      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        await _saveFetchedLanguage(languageCode);

        final body = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(body);
        final List<dynamic> data = jsonResponse['data'] ?? [];

        print('📦 Recebidos ${data.length} itens da API.');

        final List<Recipe> recipes = [];

        for (var item in data) {
          try {
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

            // Check if existing local version has favorite status
            final existing = _box.get(recipe.id);
            if (existing != null && existing.isFavorite) {
              recipe.isFavorite = true;
            }

            recipes.add(recipe);
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
  Future<List<Recipe>> searchRecipes(
    String query, {
    String languageCode = 'pt',
  }) async {
    if (query.length < 2) return [];
    print('🔎 Buscando por "$query" (lang: $languageCode)...');
    try {
      final url = Uri.parse('$_baseUrl/recipes/search').replace(
        queryParameters: {'q': query, if (languageCode == 'pt') 'lang': 'pt'},
      );
      print('🌐 Searching: $url');
      final response = await http.get(url).timeout(_requestTimeout);

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

          final existing = _box.get(recipe.id);
          if (existing != null && existing.isFavorite) {
            recipe.isFavorite = true;
          }

          recipes.add(recipe);
        }
        return recipes;
      }
    } catch (e) {
      print('Erro na busca: $e');
    }
    return [];
  } // End searchRecipes

  /// Fetches a single recipe by ID.
  Future<Recipe?> getRecipeById(String id, {String languageCode = 'pt'}) async {
    print('🚀 Buscando receita ID $id (lang: $languageCode)...');
    try {
      // Assuming the API supports fetching by ID directly or we use search.
      // Based on usual REST patterns: /recipes/:id
      // If not, we can try searching by ID if the search endpoint supports it, but direct ID is standard.
      // Since I don't have the API docs, I'll assume /recipes/:id works based on existing patterns.

      final url = Uri.parse(
        '$_baseUrl/recipes/${Uri.encodeComponent(id)}',
      ).replace(queryParameters: {if (languageCode == 'pt') 'lang': 'pt'});
      print('🌐 Requesting: $url');

      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final dynamic item = json.decode(body);

        // Handle if wrapped in 'data'
        final data = (item is Map && item.containsKey('data'))
            ? item['data']
            : item;

        String imageUrl = data['imageUrl'] ?? '';
        if (imageUrl.startsWith('/')) {
          imageUrl = '$_baseUrl$imageUrl';
        }

        final recipe = Recipe(
          id: data['id'],
          name: data['name'] ?? 'Sem nome',
          imageUrl: imageUrl,
          ingredients: List<String>.from(data['ingredients'] ?? []),
          instructions: List<String>.from(data['instructions'] ?? []),
          prepTime: data['prepTime'] ?? 30,
          difficulty: data['difficulty'] ?? 'Médio',
          servings: data['servings'] ?? 2,
          likes: data['likes'] ?? 0,
        );

        // Check local favorite status
        final existing = _box.get(recipe.id);
        if (existing != null && existing.isFavorite) {
          recipe.isFavorite = true;
        }

        // Save/Update local cache
        await _box.put(recipe.id, recipe);
        return recipe;
      } else {
        print('❌ Erro API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('🔥 Erro ao buscar receita por ID: $e');
      return null;
    }
  }
}
