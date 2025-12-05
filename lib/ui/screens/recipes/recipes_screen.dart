import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/providers/recipes_provider.dart';
import 'package:smart_market_list/ui/screens/recipes/widgets/recipe_card.dart';
import 'package:smart_market_list/ui/screens/recipes/modals/recipe_detail_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_market_list/data/models/recipe.dart';

import 'package:smart_market_list/providers/shopping_list_provider.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    final service = ref.watch(recipesServiceProvider);
    final shoppingListsAsync = ref.watch(shoppingListsProvider);

    // Get active list items (assuming first list is active for now, or use a selectedListProvider if available)
    // For now, we'll take all items from all lists or just the first one.
    // Let's assume the first list is the active one as per previous context.
    final activeItems = shoppingListsAsync.value?.expand((list) => list.items).map((i) => i.name.toLowerCase()).toSet() ?? {};

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header & Search
            SliverToBoxAdapter(
              child: Padding(
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Sugestões de receitas',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Flexible(
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final Recipe option = options.elementAt(index) as Recipe;
                                            final isFirst = index == 0;
                                            return InkWell(
                                              onTap: () {
                                                onSelected(option);
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor: Colors.transparent,
                                                  builder: (context) => RecipeDetailModal(recipe: option),
                                                );
                                              },
                                              child: Container(
                                                color: isFirst
                                                    ? const Color(0xFFE0F2F1) // Teal 50
                                                    : null,
                                                padding: const EdgeInsets.all(12),
                                                child: Row(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(20), // Circular/Squircle
                                                      child: SizedBox(
                                                        width: 48,
                                                        height: 48,
                                                        child: CachedNetworkImage(
                                                          imageUrl: option.imageUrl,
                                                          fit: BoxFit.cover,
                                                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                                                          errorWidget: (context, url, error) => const Icon(Icons.error),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            option.name,
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 14,
                                                              color: Theme.of(context).brightness == Brightness.dark
                                                                  ? Colors.white
                                                                  : Colors.black87,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            '${option.ingredients.length} ingredientes disponíveis',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Theme.of(context).brightness == Brightness.dark
                                                                  ? Colors.grey[400]
                                                                  : Colors.grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 14,
                                                          color: Theme.of(context).brightness == Brightness.dark
                                                              ? Colors.grey[400]
                                                              : Colors.grey[600],
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '${option.prepTime} min',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Theme.of(context).brightness == Brightness.dark
                                                                ? Colors.grey[400]
                                                                : Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
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
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),

            recipesAsync.when(
              data: (recipes) {
                if (recipes.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Text('Nenhuma receita encontrada.')),
                  );
                }

                // Logic to split recipes
                final availableRecipes = <Recipe>[];
                final otherRecipes = <Recipe>[];

                for (var recipe in recipes) {
                  // Count matches
                  // Simple logic: check if recipe ingredient string contains any of the active items
                  // or vice versa. Since ingredients are strings like "2 eggs", we check if "eggs" is in list.
                  // For robust matching, we'd need structured ingredients.
                  // Here we'll do a basic check: if activeItems contains any word from recipe ingredient.
                  // Actually, let's assume recipe.ingredients are just names for now or do a simple contains check.
                  
                  int matches = 0;
                  for (var ingredient in recipe.ingredients) {
                    bool match = false;
                    for (var item in activeItems) {
                      if (ingredient.toLowerCase().contains(item)) {
                        match = true;
                        break;
                      }
                    }
                    if (match) matches++;
                  }
                  
                  // If matches > 0, it's "Available" (partially or fully)
                  // The prompt implies "Receitas com ingredientes que você já tem na lista".
                  if (matches > 0) {
                    availableRecipes.add(recipe);
                  } else {
                    otherRecipes.add(recipe);
                  }
                }

                // Sort available by match count desc
                availableRecipes.sort((a, b) {
                   int matchesA = _calculateMatches(a, activeItems);
                   int matchesB = _calculateMatches(b, activeItems);
                   return matchesB.compareTo(matchesA);
                });

                return SliverList(
                  delegate: SliverChildListDelegate([
                    if (availableRecipes.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Você Pode Fazer Agora', 'Receitas com ingredientes que você já tem na lista', const Color(0xFF4DB6AC)), // Teal
                      MasonryGridView.count(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: availableRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = availableRecipes[index];
                          final matches = _calculateMatches(recipe, activeItems);
                          final missing = recipe.ingredients.length - matches;
                          return RecipeCard(
                            recipe: recipe,
                            matchCount: matches,
                            missingCount: missing,
                            onTap: () => _showRecipeDetail(context, recipe),
                            onFavorite: () => service.toggleFavorite(recipe.id),
                          );
                        },
                      ),
                    ],

                    if (otherRecipes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'Outras Receitas', 'Descubra novas receitas e adicione os ingredientes à sua lista', const Color(0xFFFF7043)), // Orange
                      MasonryGridView.count(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: otherRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = otherRecipes[index];
                          final matches = _calculateMatches(recipe, activeItems);
                          final missing = recipe.ingredients.length - matches;
                          return RecipeCard(
                            recipe: recipe,
                            matchCount: matches,
                            missingCount: missing,
                            onTap: () => _showRecipeDetail(context, recipe),
                            onFavorite: () => service.toggleFavorite(recipe.id),
                          );
                        },
                      ),
                      const SizedBox(height: 80), // Bottom padding
                    ],
                  ]),
                );
              },
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Erro: $err'))),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateMatches(Recipe recipe, Set<String> activeItems) {
    int matches = 0;
    for (var ingredient in recipe.ingredients) {
      for (var item in activeItems) {
        if (ingredient.toLowerCase().contains(item)) {
          matches++;
          break;
        }
      }
    }
    return matches;
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
