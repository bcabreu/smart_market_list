import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/providers/recipes_provider.dart';
import 'package:smart_market_list/ui/screens/recipes/widgets/recipe_card.dart';
import 'package:smart_market_list/ui/screens/recipes/modals/recipe_detail_modal.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:smart_market_list/ui/common/animations/staggered_entry.dart';
import 'package:smart_market_list/ui/navigation/custom_bottom_navigation.dart';
import 'package:smart_market_list/providers/navigation_provider.dart';

import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/data/models/recipe.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

class FavoriteRecipesScreen extends ConsumerWidget {
  const FavoriteRecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    final shoppingListsAsync = ref.watch(shoppingListsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // Get target list (current or first)
    final targetList = ref.watch(currentListProvider) ?? shoppingListsAsync.value?.firstOrNull;
    
    // Get active items ONLY from the target (active) list
    final activeItems = targetList?.items.map((i) => i.name.toLowerCase()).toSet() ?? {};

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n?.favoriteRecipesTitle ?? 'Receitas Favoritas',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: recipesAsync.when(
        data: (recipes) {
          final favorites = recipes.where((r) => r.isFavorite).toList();

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.noFavorites ?? 'Nenhuma receita favorita',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.noFavoritesSubtitle ?? 'Marque receitas com ❤️ para vê-las aqui',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return MasonryGridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final recipe = favorites[index];
              final matchData = _calculateMatches(recipe, activeItems);
              
              return StaggeredEntry(
                index: index,
                child: FavoriteItemWrapper(
                  key: ValueKey(recipe.id),
                  onDismiss: () {
                     ref.read(recipesServiceProvider).toggleFavorite(recipe.id);
                  },
                  builder: (context, triggerAnimation) {
                    return RecipeCard(
                      recipe: recipe,
                      matchCount: matchData['matchCount'] as int,
                      missingCount: matchData['missingCount'] as int,
                      onTap: () => _showRecipeDetail(context, recipe),
                      onFavorite: triggerAnimation,
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
      bottomNavigationBar: Hero(
        tag: 'bottom_nav_bar',
        child: CustomBottomNavigation(
          currentIndex: 3, 
          onTap: (index) {
            if (index != 3) {
               // Update global navigation index
               ref.read(bottomNavIndexProvider.notifier).state = index;
               // Pop back to the MainScreen (root of this stack)
               Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
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

class FavoriteItemWrapper extends StatefulWidget {
  final Widget Function(BuildContext, VoidCallback) builder;
  final VoidCallback onDismiss;

  const FavoriteItemWrapper({
    super.key,
    required this.builder,
    required this.onDismiss,
  });

  @override
  State<FavoriteItemWrapper> createState() => _FavoriteItemWrapperState();
}

class _FavoriteItemWrapperState extends State<FavoriteItemWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600), // Increased from 300ms
      vsync: this,
      value: 1.0, 
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInBack, // Slightly retracts before disappearing
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerExit() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _scaleAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.builder(context, _triggerExit),
      ),
    );
  }
}
