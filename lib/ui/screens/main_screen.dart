import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter/services.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/ui/screens/smart_list/smart_list_screen.dart';
import 'package:smart_market_list/ui/screens/shopping_notes/shopping_notes_screen.dart';
import 'package:smart_market_list/ui/screens/recipes/recipes_screen.dart';
import 'package:smart_market_list/ui/screens/profile/profile_screen.dart';
import 'package:smart_market_list/ui/navigation/custom_bottom_navigation.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _screens = [
    const SmartListScreen(),
    const ShoppingNotesScreen(),
    const RecipesScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 500),
        reverse: _currentIndex < _previousIndex,
        transitionBuilder: (
          Widget child,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            child: child,
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
