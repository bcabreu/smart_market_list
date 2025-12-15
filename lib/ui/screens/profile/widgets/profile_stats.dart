import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/providers/recipes_provider.dart';
import 'package:smart_market_list/providers/shopping_notes_provider.dart';
import 'package:smart_market_list/ui/screens/profile/favorite_recipes_screen.dart';
import 'package:smart_market_list/ui/screens/profile/shared_lists_screen.dart';
import 'package:smart_market_list/providers/navigation_provider.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/providers/shared_users_provider.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';

import 'package:smart_market_list/l10n/generated/app_localizations.dart';

class ProfileStats extends ConsumerWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double cardSpacing = 12.0;
    final l10n = AppLocalizations.of(context)!;
    
    // Watch providers
    final recipesAsync = ref.watch(recipesProvider);
    final notesAsync = ref.watch(shoppingNotesProvider);

    // Calculate counts
    var favoritesCount = 0;
    recipesAsync.whenData((recipes) {
      favoritesCount = recipes.where((r) => r.isFavorite).length;
    });

    var notesCount = 0;
    notesAsync.whenData((notes) {
      notesCount = notes.length;
    });

    // Calculate shared lists count
    final userAsync = ref.watch(userProfileProvider);
    final listsAsync = ref.watch(shoppingListsProvider);
    
    var sharedCount = 0;
    
    final user = userAsync.valueOrNull;

    if (user != null) {
      listsAsync.whenData((lists) {
        sharedCount = lists.where((list) {
          final hasGuests = list.members.any((m) => m != list.ownerId);
          final amIGuest = list.ownerId != null && list.ownerId != user.uid;
          return hasGuests || amIGuest;
        }).length;
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
            context,
            icon: Icons.favorite_border_rounded,
            iconColor: Colors.white,
            iconBgColor: const Color(0xFFFF4081), // PinkAccent
            count: '$favoritesCount',
            label: l10n.favoriteRecipesStats,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoriteRecipesScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: cardSpacing),
          _buildStatCard(
            context,
            icon: Icons.description_outlined,
            iconColor: Colors.white,
            iconBgColor: const Color(0xFFFF9800), // Orange
            count: '$notesCount',
            label: l10n.savedNotesStats,
            onTap: () {
               ref.read(bottomNavIndexProvider.notifier).state = 1;
            },
          ),
          const SizedBox(width: cardSpacing),
          _buildStatCard(
            context,
            icon: Icons.group_outlined,
            iconColor: Colors.white,
            iconBgColor: const Color(0xFF26A69A), // Teal
            count: '$sharedCount',
            label: l10n.sharingListsStats,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SharedListsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String count,
    required String label,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: isDark 
                ? Border.all(color: Colors.white.withOpacity(0.1), width: 1)
                : null,
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 32, // Fixed height for 2 lines of text
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11, // Slightly smaller
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
