import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final l10n = AppLocalizations.of(context)!;
    
    // Get bottom safe area padding for system navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final items = [
      _NavItemData(
        icon: Icons.shopping_cart_outlined,
        activeIcon: Icons.shopping_cart,
        label: l10n.navShop,
        color: AppColors.primary,
      ),
      _NavItemData(
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        label: l10n.navNotes,
        color: AppColors.secondary,
      ),
      _NavItemData(
        icon: FontAwesomeIcons.kitchenSet,
        activeIcon: FontAwesomeIcons.kitchenSet,
        label: l10n.navRecipes,
        color: Colors.purple,
      ),
      _NavItemData(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: l10n.navProfile,
        color: Colors.blue,
      ),
    ];

    return Material(
      type: MaterialType.transparency,
      child: Container(
        // Fixed height of 90 for nav items + dynamic bottom padding for safe area
        height: 90 + bottomPadding,
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / items.length;
            final activeItem = items[currentIndex];

            return Stack(
              children: [
                // Sliding Light Background
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: currentIndex * itemWidth,
                  top: 10, // Adjusted top position
                  width: itemWidth,
                  height: 64, // Height of the active area
                  child: Center(
                    child: Container(
                      width: itemWidth - 8, // Wider rectangle (less padding)
                      height: 52, // Shorter height for rectangular look
                      decoration: BoxDecoration(
                        color: activeItem.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                // Items
                Row(
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = index == currentIndex;

                    return SizedBox(
                      width: itemWidth,
                      child: GestureDetector(
                        onTap: () => onTap(index),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            // Icon Container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? item.color : Colors.transparent,
                                borderRadius: BorderRadius.circular(12), // Slightly less rounded for squircle effect
                              ),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected ? Colors.white : Colors.grey,
                                size: 22, // Slightly smaller icon to fit well
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Label
                            Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected 
                                    ? (isDark ? Colors.white : Colors.black87) 
                                    : Colors.grey,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Sliding Dot Indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: (currentIndex * itemWidth) + (itemWidth / 2) - 2, // Center the dot
                  bottom: 8,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: activeItem.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
