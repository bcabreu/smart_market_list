import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter/services.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/ui/screens/smart_list/smart_list_screen.dart';
import 'package:smart_market_list/ui/screens/shopping_notes/shopping_notes_screen.dart';
import 'package:smart_market_list/ui/screens/recipes/recipes_screen.dart';
import 'package:smart_market_list/ui/screens/profile/profile_screen.dart';
import 'package:smart_market_list/ui/navigation/custom_bottom_navigation.dart';
import 'package:smart_market_list/ui/screens/auth/login_screen.dart';
import 'package:smart_market_list/ui/screens/auth/signup_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/providers/navigation_provider.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/providers/sharing_provider.dart';
import 'package:smart_market_list/core/services/sharing_service.dart';

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
    ref.read(sharingServiceProvider).initDeepLinks(
      onJoinList: (listId, familyId) {
        _handleJoinList(listId, familyId);
      },
      onJoinFamily: (familyId) {
        _handleJoinFamily(familyId);
      },
    );
  }
  Future<void> _handleJoinFamily(String familyId) async {
    final user = await ref.read(userProfileProvider.future);
    
    if (user != null) {
      try {
        await ref.read(sharingServiceProvider).joinFamily(familyId, user.uid);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Parabéns! Agora você faz parte da Família Premium! 🏠✨'),
               backgroundColor: Colors.green,
             ),
           );
           // Refresh profile
           ref.refresh(userProfileProvider);
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erro ao entrar na família: $e'), backgroundColor: Colors.red),
           );
        }
      }
    } else {
      print('⚠️ User not authenticated. Storing pending invite for family $familyId.');
      SharingService.pendingFamilyId = familyId;
      SharingService.pendingListId = null; 
      
      if (mounted) {
        _showLoginSheet();
      }
    }
  }

  void _showLoginSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_add_rounded, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Entrar na Família',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Para aceitar o convite da família, você precisa entrar ou criar uma conta.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Entrar'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Criar Conta'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
  }

  Future<void> _handleJoinList(String listId, String familyId) async {
    // Wait for the user profile to be loaded (handles cold start race condition)
    final user = await ref.read(userProfileProvider.future);
    
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
    } else {
      // User not authenticated. Store pending invite and redirect/prompt.
      print('⚠️ User not authenticated. Storing pending invite for list $listId.');
      SharingService.pendingListId = listId;
      SharingService.pendingFamilyId = familyId;
      
      if (mounted) {
        // Show a modal asking to Login or Signup to join the list
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_add_rounded, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Entrar na Lista Compartilhada',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para acessar esta lista, você precisa entrar ou criar uma conta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Entrar'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Criar Conta'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
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
          
          // Check for Pending Invites
          if (SharingService.pendingListId != null && SharingService.pendingFamilyId != null) {
            _handleJoinList(SharingService.pendingListId!, SharingService.pendingFamilyId!);
            SharingService.pendingListId = null;
            SharingService.pendingFamilyId = null;
          } else if (SharingService.pendingFamilyId != null && SharingService.pendingListId == null) {
             // Pending Family Join (without list)
            _handleJoinFamily(SharingService.pendingFamilyId!);
            SharingService.pendingFamilyId = null;
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

