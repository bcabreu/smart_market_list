import 'package:flutter/material.dart';
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
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
