import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/providers/recipes_provider.dart';
import 'package:smart_market_list/ui/screens/recipes/widgets/recipe_card.dart';
import 'package:smart_market_list/ui/screens/recipes/modals/recipe_detail_modal.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_market_list/data/models/recipe.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    final service = ref.watch(recipesServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.purple, // Matches bottom nav
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
                          Icons.restaurant_menu_rounded, // Chef hat alternative
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

            // Content
            Expanded(
              child: recipesAsync.when(
                data: (recipes) {
                  if (recipes.isEmpty) {
                    return const Center(child: Text('Nenhuma receita encontrada.'));
                  }

                  return MasonryGridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return RecipeCard(
                        recipe: recipe,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => RecipeDetailModal(recipe: recipe),
                          );
                        },
                        onFavorite: () {
                          service.toggleFavorite(recipe.id);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erro: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
