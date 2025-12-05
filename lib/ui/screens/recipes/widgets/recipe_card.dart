import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final int matchCount;
  final int missingCount;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onFavorite,
    required this.matchCount,
    required this.missingCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image and Content Overlay
              Stack(
                children: [
                  // Image
                  CachedNetworkImage(
                    imageUrl: recipe.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 220,
                    placeholder: (context, url) => Container(
                      height: 220,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 220,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: const Center(child: Icon(Icons.error)),
                    ),
                  ),

                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.8),
                          ],
                          stops: const [0.4, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top Badges
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(recipe.difficulty),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        recipe.difficulty,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: recipe.isFavorite ? Colors.red : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // Title and Metadata (Inside Image Area)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMetadataChip(Icons.access_time, '${recipe.prepTime} min'),
                            const SizedBox(width: 8),
                            _buildMetadataChip(Icons.people_outline, '${recipe.servings}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 10, color: Color(0xFF4DB6AC)), // Teal
                        const SizedBox(width: 6),
                        Text(
                          '$matchCount na lista',
                          style: const TextStyle(
                            color: Color(0xFF4DB6AC),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFFF7043)), // Orange
                        const SizedBox(width: 4),
                        Text(
                          '$missingCount faltando',
                          style: const TextStyle(
                            color: Color(0xFFFF7043),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'fácil':
        return const Color(0xFF00C853); // Green
      case 'médio':
        return const Color(0xFFFF9800); // Orange
      case 'difícil':
        return const Color(0xFFD50000); // Red
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }
}
