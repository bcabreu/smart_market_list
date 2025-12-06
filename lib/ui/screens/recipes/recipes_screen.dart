import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/providers/recipes_provider.dart';
import 'package:smart_market_list/ui/screens/recipes/widgets/recipe_card.dart';
import 'package:smart_market_list/ui/screens/recipes/modals/recipe_detail_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_market_list/data/models/recipe.dart';
import 'package:smart_market_list/ui/common/animations/staggered_entry.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    final service = ref.watch(recipesServiceProvider);
    final shoppingListsAsync = ref.watch(shoppingListsProvider);

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
                          const Text(
                            'Receitas pra Você 👨‍🍳',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Baseadas nos seus ingredientes',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Search Bar with Autocomplete
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return RawAutocomplete<Recipe>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.length < 2) {
                            return const Iterable<Recipe>.empty();
                          }
                          return recipesAsync.value?.where((recipe) {
                                return recipe.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                              }) ??
                              const Iterable<Recipe>.empty();
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
                                hintText: 'Buscar receitas...',
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
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(16),
                              color: Theme.of(context).cardColor,
                              child: Container(
                                width: constraints.maxWidth,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Theme.of(context).cardColor,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: options.map((Recipe option) {
                                    return ListTile(
                                      title: Text(option.name),
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: option.imageUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      onTap: () {
                                        onSelected(option);
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => RecipeDetailModal(recipe: option),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                        onSelected: (Recipe selection) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => RecipeDetailModal(recipe: selection),
                          );
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
                  recipesWithMatches.sort((a, b) {
                    final matchesA = a.value['matchCount'] as int;
                    final matchesB = b.value['matchCount'] as int;
                    return matchesB.compareTo(matchesA);
                  });

                  // Split into "Available" (at least 1 match) and "Others"
                  final availableRecipes = recipesWithMatches
                      .where((entry) => (entry.value['matchCount'] as int) > 0)
                      .toList();
                  
                  final otherRecipes = recipesWithMatches
                      .where((entry) => (entry.value['matchCount'] as int) == 0)
                      .toList();

                  return CustomScrollView(
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
                                      'Você Pode Fazer Agora',
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
                                  'Receitas com ingredientes que você já tem na lista',
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
                            height: 280, // Fixed height for horizontal cards
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => RecipeDetailModal(recipe: recipe),
                                      );
                                    },
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
                                      'Outras Receitas',
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
                                  'Descubra novas receitas e adicione os ingredientes à sua lista',
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
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => RecipeDetailModal(recipe: recipe),
                                    );
                                  },
                                  onFavorite: () async {
                                    await service.toggleFavorite(recipe.id);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      
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

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (title == 'Outras Receitas')
                 Icon(Icons.local_fire_department_rounded, color: dotColor, size: 24)
              else
                 Icon(Icons.circle, color: dotColor, size: 16),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
