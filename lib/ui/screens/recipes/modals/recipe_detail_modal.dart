import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/recipe.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/ui/common/modals/paywall_modal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_market_list/providers/recipes_provider.dart';
import 'package:smart_market_list/providers/sharing_provider.dart';

class RecipeDetailModal extends ConsumerWidget {
  final Recipe recipe;

  const RecipeDetailModal({super.key, required this.recipe});

  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsAsync = ref.watch(shoppingListsProvider);
    final shoppingListService = ref.watch(shoppingListServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    
    // Resolve current recipe state (for reactive favorites)
    final recipes = ref.watch(recipesProvider).value ?? [];
    final currentRecipe = recipes.firstWhere((r) => r.id == recipe.id, orElse: () => recipe);

    // Get target list (current or first)
    final targetList = ref.watch(currentListProvider) ?? shoppingListsAsync.value?.firstOrNull;
    
    // Get active items ONLY from the target (active) list
    final activeItems = targetList?.items.map((i) => i.name.toLowerCase()).toSet() ?? {};

    final availableIngredients = <String>[];
    final missingIngredients = <String>[];

    for (var ingredient in recipe.ingredients) {
      bool match = false;
      for (var item in activeItems) {
        if (ingredient.toLowerCase().contains(item)) {
          match = true;
          break;
        }
      }
      if (match) {
        availableIngredients.add(ingredient);
      } else {
        missingIngredients.add(ingredient);
      }
    }

    Future<void> addItems(List<String> ingredients) async {
      if (targetList == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noListFound)),
        );
        return;
      }

      try {
        // Create new items
        final newItems = ingredients.map((name) => ShoppingItem(
          name: name,
          category: 'outros', // Could be smarter here
        )).toList();

        // Add to list via service
        // We can optimize by adding all at once if service supported it, 
        // but for now we'll loop or update the list directly.
        // Updating list directly is better for batch add.
        
        final currentItems = List<ShoppingItem>.from(targetList.items);
        currentItems.addAll(newItems);
        
        final updatedList = targetList.copyWith(items: currentItems);
        await shoppingListService.updateList(updatedList);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.itemsAdded(ingredients.length, targetList.name)),
              backgroundColor: const Color(0xFF4DB6AC),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorAddingItems(e.toString()))),
          );
        }
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Image Header
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  automaticallyImplyLeading: false,
                  actions: [
                    // Share Button
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.share, color: Colors.white, size: 20),
                          onPressed: () async {
                             await ref.read(sharingServiceProvider).shareRecipe(
                               recipeId: currentRecipe.id, 
                               recipeName: currentRecipe.name,
                               shareMessage: l10n.shareRecipeMessage(currentRecipe.name),
                               viewRecipeLabel: l10n.viewRecipe,
                             );
                          },
                        ),
                      ),
                    ),
                    // Favorite Button
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: Icon(
                            currentRecipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: currentRecipe.isFavorite ? Colors.red : Colors.white,
                            size: 20,
                          ),
                          onPressed: () async {
                            final service = ref.read(recipesServiceProvider);
                            await service.toggleFavorite(currentRecipe.id);
                          },
                        ),
                      ),
                    ),
                    // Close Button (Existing)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: recipe.imageUrl,
                          fit: BoxFit.cover,
                        ),
                        // Difficulty Badge
                        Positioned(
                          top: 56, // Adjust based on safe area/app bar height
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(recipe.difficulty),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getLocalizedDifficulty(context, recipe.difficulty),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Extra bottom padding for floating button
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Meta Chips
                        Row(
                          children: [
                            _buildChip(
                              context,
                              Icons.access_time,
                              '${recipe.prepTime} ${l10n.cookTime}',
                              const Color(0xFFE0F2F1), // Teal 50
                              const Color(0xFF009688), // Teal 500
                            ),
                            const SizedBox(width: 12),
                             _buildChip(
                              context,
                              Icons.people_outline,
                              l10n.servings(recipe.servings),
                              const Color(0xFFE3F2FD), // Blue 50
                              const Color(0xFF2196F3), // Blue 500
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Available Ingredients
                        if (availableIngredients.isNotEmpty) ...[
                          Row(
                           children: [
                              const Icon(Icons.circle, size: 12, color: Color(0xFF4DB6AC)),
                              const SizedBox(width: 8),
                              Text(
                                l10n.ingredientsInList,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...availableIngredients.map((ingredient) => _buildIngredientItem(context, ingredient, true)),
                          const SizedBox(height: 24),
                        ],

                        // Missing Ingredients
                        if (missingIngredients.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department_rounded, size: 18, color: Color(0xFFFF7043)),
                              const SizedBox(width: 8),
                              Text(
                                l10n.missingIngredientsSectionTitle,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...missingIngredients.map((ingredient) => _buildIngredientItem(
                            context, 
                            ingredient, 
                            false,
                            onAdd: () => addItems([ingredient]),
                          )),
                          const SizedBox(height: 32),
                        ],

                        // Instructions
                        Text(
                          l10n.instructionsTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...recipe.instructions.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    height: 1.6,
                                    fontSize: 15,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Floating Bottom Button
            if (missingIngredients.isNotEmpty)
              Positioned(
                left: 24,
                right: 24,
                bottom: 32,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final isPremium = ref.read(isPremiumProvider);
                      if (!isPremium) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const PaywallModal(),
                        );
                      } else {
                        addItems(missingIngredients);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DB6AC), // Teal
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF4DB6AC).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(
                      l10n.addItemsToList(missingIngredients.length),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label, Color bgLight, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.2) : bgLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(BuildContext context, String name, bool isAvailable, {VoidCallback? onAdd}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: (!isAvailable && onAdd != null) ? onAdd : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isAvailable
                ? (isDark ? Colors.green.withOpacity(0.1) : Colors.white)
                : (isDark ? Colors.grey[800] : Colors.grey[50]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAvailable
                  ? (isDark ? Colors.green.withOpacity(0.3) : Colors.green.withOpacity(0.1))
                  : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            boxShadow: isAvailable && !isDark
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAvailable ? const Color(0xFF4DB6AC) : Colors.transparent,
                  border: isAvailable
                      ? null
                      : Border.all(color: Colors.grey[400]!, width: 2),
                ),
                child: isAvailable
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isAvailable ? FontWeight.w500 : FontWeight.normal,
                    color: isAvailable
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'fácil':
      case 'easy':
        return const Color(0xFF00C853); // Green
      case 'médio':
      case 'medium':
        return const Color(0xFFFFA000); // Amber
      case 'difícil':
      case 'hard':
        return const Color(0xFFD84315); // Deep Orange
      default:
        return Colors.grey;
    }
  }

  String _getLocalizedDifficulty(BuildContext context, String difficulty) {
    final l10n = AppLocalizations.of(context)!;
    switch (difficulty.toLowerCase()) {
      case 'fácil':
      case 'easy':
        return l10n.difficultyEasy;
      case 'médio':
      case 'medium':
        return l10n.difficultyMedium;
      case 'difícil':
      case 'hard':
        return l10n.difficultyHard;
      default:
        return difficulty; // Fallback to original if not matched
    }
  }
}
