import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:smart_market_list/providers/recipes_provider.dart';
import 'package:smart_market_list/ui/screens/recipes/widgets/recipe_card.dart';
import 'package:smart_market_list/ui/screens/recipes/modals/recipe_detail_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_market_list/data/models/recipe.dart';
import 'package:smart_market_list/ui/common/animations/staggered_entry.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/providers/locale_provider.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentPage = 0;
  int _sessionSeed = 0;

  @override
  void initState() {
    super.initState();
    _sessionSeed = Random().nextInt(100000); // Generate random seed for this session
    
    _scrollController.addListener(_onScroll);
    
    // Initial fetch if empty (post-frame to avoid build errors)
    // Initial fetch validation
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final recipes = ref.read(recipesProvider).value ?? [];
      final service = ref.read(recipesServiceProvider);
      final currentLocale = ref.read(localeProvider);
      // Fix: If provider is null (system), use the actual resolved locale from context
      final resolvedLang = currentLocale?.languageCode ?? Localizations.localeOf(context).languageCode;
      // Enforce: Anything not 'pt' becomes 'en'
      final targetLang = resolvedLang == 'pt' ? 'pt' : 'en';
      
      final lastFetchedLang = await service.getLastFetchedLanguage();
      
      if (recipes.isEmpty || lastFetchedLang != targetLang) {
        print('🔄 Language mismatch or empty list (Last: $lastFetchedLang, Target: $targetLang). Reloading...');
        // Clear if mismatch
        if (lastFetchedLang != targetLang) {
           await service.clearRecipes();
           setState(() {
             _currentPage = 0;
           });
        }
        _loadMoreRecipes();
      } else {
        // Assume we have at least 1 page if we have data and language matches
         _currentPage = 1;
      }
    });
  }

  // Monitor locale changes
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We can't easily listen to riverpod provider changes in didChangeDependencies without context,
    // but we can do it in build via ref.listen
  }



  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      _loadMoreRecipes();
    }
  }

  Future<void> _loadMoreRecipes() async {
    if (_isLoadingMore) return;
    // Removed legacy ID limit. API has its own limits but we can keep fetching until empty.

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final service = ref.read(recipesServiceProvider);
      final nextPage = _currentPage + 1;
      final currentLocale = ref.read(localeProvider);
      
      final newRecipes = await service.fetchRecipesPage(
        page: nextPage, 
        limit: 10,
        languageCode: (currentLocale?.languageCode ?? Localizations.localeOf(context).languageCode) == 'pt' ? 'pt' : 'en',
      );
      
      if (newRecipes.isNotEmpty) {
        setState(() {
          _currentPage = nextPage;
        });
        

      } else {
         // No more recipes found
      }
    } catch (e) {
      print('Erro no lazy load: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for locale changes to refresh recipes
    ref.listen(localeProvider, (previous, next) async {
      if (previous != next) {
        // Language changed, clear cache and reload
        try {
          setState(() {
             _currentPage = 0;
             // Do NOT set _isLoadingMore = true here, let the method handle it
          });

          // Clear local cache (Hive)
          await ref.read(recipesServiceProvider).clearRecipes();
          
          // Re-fetch page 1 with new locale
          await _loadMoreRecipes();
        } catch (e) {
          print('Erro ao recarregar receitas no novo idioma: $e');
        } 
      }
    });

    final recipesAsync = ref.watch(recipesProvider);
    final service = ref.watch(recipesServiceProvider);
    final shoppingListsAsync = ref.watch(shoppingListsProvider);
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    // Get target list (current or first)
    final targetList = ref.watch(currentListProvider) ?? shoppingListsAsync.value?.firstOrNull;
    
    // Get active items ONLY from the target (active) list
    final activeItems = targetList?.items.map((i) => i.name.toLowerCase()).toSet() ?? {};

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header & Search
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.restaurant_menu_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.recipesTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.recipesSubtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),

                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Search Bar with Autocomplete (Server Side)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return RawAutocomplete<Recipe>(
                        optionsBuilder: (TextEditingValue textEditingValue) async {
                          if (textEditingValue.text.length < 2) {
                            return const Iterable<Recipe>.empty();
                          }
                          // Use API search with current language
                          final results = await service.searchRecipes(
                            textEditingValue.text,
                            languageCode: (locale?.languageCode ?? Localizations.localeOf(context).languageCode) == 'pt' ? 'pt' : 'en',
                          );
                          return results;
                        },
                        displayStringForOption: (Recipe option) => option.name,
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                icon: Icon(
                                  Icons.search,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                ),
                                hintText: l10n.searchHint,
                                hintStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                              ),
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          // Calculate available height above keyboard
                          final mediaQuery = MediaQuery.of(context);
                          final keyboardHeight = mediaQuery.viewInsets.bottom;
                          final screenHeight = mediaQuery.size.height;
                          // Approx top offset of search bar is 200px. 
                          // Safe max height = Screen - Keyboard - TopOffset - Buffer
                          // Increased buffer to 340 to account for larger headers or safe areas
                          final maxListHeight = (screenHeight - keyboardHeight - 340).clamp(100.0, 400.0);

                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.transparent,
                              child: Container(
                                width: constraints.maxWidth,
                                margin: const EdgeInsets.only(top: 8),
                                constraints: BoxConstraints(maxHeight: maxListHeight),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFFFD700)), // Gold star
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.recipesFound,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                                    Flexible(
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                                        itemBuilder: (BuildContext context, int index) {
                                          final Recipe option = options.elementAt(index);
                                          
                                          return InkWell(
                                            onTap: () {
                                              onSelected(option);
                                              _showRecipeDetail(context, option);
                                            },
                                            child: Container(
                                              color: index == 0 
                                                  ? (isDark ? const Color(0xFF4DB6AC).withOpacity(0.1) : const Color(0xFFE0F2F1))
                                                  : null,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              child: Row(
                                                children: [
                                                  // Image
                                                  Container(
                                                    width: 48,
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      color: Colors.grey[200],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: CachedNetworkImage(
                                                        imageUrl: option.imageUrl,
                                                        fit: BoxFit.cover,
                                                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                                                        errorWidget: (context, url, error) => const Center(
                                                          child: Icon(Icons.restaurant, color: Colors.grey),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  // Text Info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          option.name,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: isDark ? Colors.white : Colors.black87,
                                                          ),
                                                        ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            '${option.difficulty} • ${option.prepTime} ${l10n.cookTime}',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Arrow
                                                  const Icon(
                                                    Icons.arrow_forward,
                                                    size: 18,
                                                    color: Color(0xFF4DB6AC),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        onSelected: (Recipe selection) {
                           _showRecipeDetail(context, selection);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: recipesAsync.when(
                data: (recipes) {
                  // Calculate matches for each recipe
                  final recipesWithMatches = recipes.map((recipe) {
                    final matchData = _calculateMatches(recipe, activeItems);
                    return MapEntry(recipe, matchData);
                  }).toList();

                  // Sort by number of matches (descending)
                  // Sort by number of matches (descending), then random tie-breaker
                  recipesWithMatches.sort((a, b) {
                    final matchesA = a.value['matchCount'] as int;
                    final matchesB = b.value['matchCount'] as int;
                    if (matchesA != matchesB) {
                      return matchesB.compareTo(matchesA);
                    }
                    // Tie-breaker: Random session order
                    final hashA = (a.key.id.hashCode + _sessionSeed).hashCode;
                    final hashB = (b.key.id.hashCode + _sessionSeed).hashCode;
                    return hashA.compareTo(hashB);
                  });

                  // Split into "Available" (at least 1 match) and "Others"
                  final availableRecipes = recipesWithMatches
                      .where((entry) => (entry.value['matchCount'] as int) > 0)
                      .toList();
                  
                  final otherRecipes = recipesWithMatches
                      .where((entry) => (entry.value['matchCount'] as int) == 0)
                      .toList();

                  // Shuffle "Others" consistently for this session but MORE vigorously
                  otherRecipes.sort((a, b) {
                     final recipeA = a.key;
                     final recipeB = b.key;
                     // Stronger mix for random feel
                     final hashA = (recipeA.id.toString().hashCode + _sessionSeed).toString().hashCode;
                     final hashB = (recipeB.id.toString().hashCode + _sessionSeed).toString().hashCode;
                     return hashA.compareTo(hashB);
                  });

                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Available Recipes Section
                      if (availableRecipes.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.circle, color: Color(0xFF4DB6AC), size: 16), // Teal circle
                                    const SizedBox(width: 12),
                                    Text(
                                      l10n.youCanCookNow,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4DB6AC).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${availableRecipes.length}',
                                        style: const TextStyle(
                                          color: Color(0xFF4DB6AC),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.youCanCookNowSubtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 320, // Increased height to prevent shadow clipping
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: availableRecipes.length,
                              itemBuilder: (context, index) {
                                final entry = availableRecipes[index];
                                final recipe = entry.key;
                                final matchData = entry.value;
                                
                                return Container(
                                  width: 200, // Fixed width for horizontal items
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  child: RecipeCard(
                                    recipe: recipe,
                                    matchCount: matchData['matchCount'] as int,
                                    missingCount: matchData['missingCount'] as int,
                                    onTap: () => _showRecipeDetail(context, recipe),
                                    onFavorite: () async {
                                      await service.toggleFavorite(recipe.id);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      // Other Recipes Section
                      if (otherRecipes.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.local_fire_department_outlined, color: Color(0xFFFF7043), size: 24), // Orange fire
                                    const SizedBox(width: 12),
                                    Text(
                                      l10n.otherRecipes,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey[300]
                                            : Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.otherRecipesSubtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverMasonryGrid.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childCount: otherRecipes.length,
                            itemBuilder: (context, index) {
                              final entry = otherRecipes[index];
                              final recipe = entry.key;
                              final matchData = entry.value;

                              return StaggeredEntry(
                                index: index,
                                child: RecipeCard(
                                  recipe: recipe,
                                  matchCount: matchData['matchCount'] as int,
                                  missingCount: matchData['missingCount'] as int,
                                  onTap: () => _showRecipeDetail(context, recipe),
                                  onFavorite: () async {
                                    await service.toggleFavorite(recipe.id);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      
                      // Loading Indicator at bottom
                      if (_isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      
                      // Bottom Padding
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Erro: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _calculateMatches(Recipe recipe, Set<String> activeItems) {
    int matches = 0;
    for (var ingredient in recipe.ingredients) {
      for (var item in activeItems) {
        if (ingredient.toLowerCase().contains(item)) {
          matches++;
          break;
        }
      }
    }
    return {
      'matchCount': matches,
      'missingCount': recipe.ingredients.length - matches,
    };
  }

  void _showRecipeDetail(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecipeDetailModal(recipe: recipe),
    );
  }
}
