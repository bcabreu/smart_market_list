import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter/services.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/ui/screens/smart_list/smart_list_screen.dart';
import 'package:smart_market_list/ui/screens/shopping_notes/shopping_notes_screen.dart';
import 'package:smart_market_list/ui/screens/recipes/recipes_screen.dart';
import 'package:smart_market_list/ui/screens/profile/profile_screen.dart';
import 'package:smart_market_list/ui/navigation/custom_bottom_navigation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/providers/navigation_provider.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/providers/sharing_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _previousIndex = 0;

  final List<Widget> _screens = [
    const SmartListScreen(),
    const ShoppingNotesScreen(),
    const RecipesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks();
    });
  }

  void _initDeepLinks() {
    ref.read(sharingServiceProvider).initDeepLinks((listId, familyId) {
      _handleJoinList(listId, familyId);
    });
  }

  Future<void> _handleJoinList(String listId, String familyId) async {
    final user = ref.read(userProfileProvider).value;
    if (user != null) {
      try {
        await ref.read(sharingServiceProvider).joinList(listId, familyId, user.uid);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Lista compartilhada adicionada! 🛒')),
           );
           // Switch to SmartListScreen and select the new list
           ref.read(bottomNavIndexProvider.notifier).state = 0;
           ref.read(currentListIdProvider.notifier).state = listId;
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erro ao entrar na lista: $e'), backgroundColor: Colors.red),
           );
        }
      }
    }
  }

  void _onTabTapped(int index) {
    final currentIndex = ref.read(bottomNavIndexProvider);
    if (currentIndex != index) {
      HapticFeedback.selectionClick();
      // Update provider - this triggers rebuild
      ref.read(bottomNavIndexProvider.notifier).state = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    // Activate Sync Manager
    ref.watch(syncManagerProvider);
    
    // Listen to changes to update previous index for animation
    ref.listen(bottomNavIndexProvider, (previous, next) {
      if (previous != null) {
        _previousIndex = previous;
      }
    });

    // Listen to Auth State to sync user data (Email/Name) on restart
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          // Sync Email
          if (user.email != null && user.email!.isNotEmpty) {
             ref.read(userEmailProvider.notifier).setEmail(user.email!);
          }
          // Sync Name (if available)
          if (user.displayName != null && user.displayName!.isNotEmpty) {
             ref.read(userNameProvider.notifier).setName(user.displayName!);
          }
        }
      });
    });

    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 500),
        reverse: currentIndex < _previousIndex,
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
        child: _screens[currentIndex],
      ),
      bottomNavigationBar: Hero(
        tag: 'bottom_nav_bar',
        child: CustomBottomNavigation(
          currentIndex: currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
