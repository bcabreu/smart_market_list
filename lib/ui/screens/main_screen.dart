import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:smart_market_list/ui/common/ads/banner_ad_widget.dart';
import 'package:smart_market_list/ui/common/modals/status_feedback_modal.dart';
import 'package:flutter/services.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/ui/screens/smart_list/smart_list_screen.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/ui/screens/shopping_notes/shopping_notes_screen.dart';
import 'package:smart_market_list/ui/screens/recipes/recipes_screen.dart';
import 'package:smart_market_list/ui/screens/recipes/modals/recipe_detail_modal.dart';
import 'package:smart_market_list/ui/screens/profile/profile_screen.dart';
import 'package:smart_market_list/ui/navigation/custom_bottom_navigation.dart';
import 'package:smart_market_list/ui/screens/auth/login_screen.dart';
import 'package:smart_market_list/ui/screens/auth/signup_screen.dart';
import 'package:smart_market_list/data/models/recipe.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/providers/navigation_provider.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/providers/sharing_provider.dart';
import 'package:smart_market_list/providers/recipes_provider.dart';
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
    // Initialize Deep Links with a slight delay to ensure Native Bridge is ready (iOS Fix)
    Future.delayed(const Duration(milliseconds: 800), () {
       _initDeepLinks();
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateSession();
    });
  }

  Future<void> _validateSession() async {
    try {
      await ref.read(authServiceProvider).validateSession();
    } catch (e) {
      print('Session validation failed: $e');
      // If user was signed out by validation, the stream will update the UI automatically.
    }
  }

  void _initDeepLinks() {
    // We use read here because it's a one-time subscription setup
     ref.read(sharingServiceProvider).initDeepLinks(
      onJoinList: (listId, familyId) {
        _handleJoinList(listId, familyId);
      },
      onJoinFamily: (familyId, inviteCode) {
        _handleJoinFamily(familyId, inviteCode);
      },
      onOpenRecipe: (recipeId) {
        // Switch to Recipes Tab (Index 2)
        ref.read(bottomNavIndexProvider.notifier).state = 2;
        _handleOpenRecipe(recipeId);
      },
    );
  }

  Future<void> _handleOpenRecipe(String recipeId) async {
    // 1. Try to find in currently loaded list (Cache/Local)
    final recipes = ref.read(recipesProvider).value ?? [];
    Recipe? recipe;
    
    try {
      recipe = recipes.firstWhere((r) => r.id == recipeId);
    } catch (e) {
      // Not found locally
      recipe = null;
    }

    // 2. If not found locally, try to fetch from API via Service
    if (recipe == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carregando receita...'), duration: Duration(seconds: 1)),
        );
      }
      
      try {
        final lang = Localizations.localeOf(context).languageCode;
        recipe = await ref.read(recipesServiceProvider).getRecipeById(recipeId, languageCode: lang);
      } catch (e) {
        print('Error fetching recipe deep link: $e');
      }
    }

    // 3. Open Modal if found
    if (recipe != null) {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => RecipeDetailModal(recipe: recipe!),
        );
      }
    } else {
      // 4. Error if still null
      if (mounted) {
         StatusFeedbackModal.show(
           context,
           title: AppLocalizations.of(context)!.errorTitle,
           message: "Recipe not found.",
           type: FeedbackType.error,
         );
      }
    }
  }
  
  Future<void> _handleJoinFamily(String familyId, String? inviteCode) async {
    final user = await ref.read(userProfileProvider.future);
    final l10n = AppLocalizations.of(context)!;
    
    if (user != null) {
      try {
        await ref.read(sharingServiceProvider).joinFamily(familyId, user.uid, inviteCode: inviteCode);
        if (mounted) {
           StatusFeedbackModal.show(
             context,
             title: l10n.welcomeToFamilyTitle,
             message: l10n.welcomeToFamilyMessage,
             type: FeedbackType.success,
           );
           // Refresh profile
           ref.refresh(userProfileProvider);
        }
      } catch (e) {
        if (mounted) {
           String errorMessage;
           String errorTitle = l10n.errorTitle;
           
           final msg = e.toString();
           if (msg.contains('familyAlreadyHasMember')) {
             errorMessage = l10n.familyAlreadyHasMember;
           } else if (msg.contains('inviteInvalidOrExpired')) {
             errorMessage = l10n.inviteInvalidOrExpired;
           } else if (msg.contains('familyNotFound')) {
             errorMessage = l10n.genericError('Family not found');
           } else {
             // Fallback for unexpected errors, stripping "Exception: "
             errorMessage = msg.replaceAll('Exception: ', '');
           }
           
           StatusFeedbackModal.show(
             context,
             title: errorTitle,
             message: errorMessage,
             type: FeedbackType.error,
           );
        }
      }
    } else {
       // ... existing pending logic ...
       // Store pending invite code
       SharingService.pendingFamilyId = familyId;
       SharingService.pendingInviteCode = inviteCode; // Need to add this static field
       SharingService.pendingListId = null;
       
       if (mounted) {
         // ... existing warning logic ...
       }
    }
  }
  // Code removed


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
           StatusFeedbackModal.show(
             context,
             title: AppLocalizations.of(context)!.successTitle,
             message: AppLocalizations.of(context)!.welcomeToList,
             type: FeedbackType.success,
           );
           // Switch to SmartListScreen and select the new list
           ref.read(bottomNavIndexProvider.notifier).state = 0;
           ref.read(currentListIdProvider.notifier).state = listId;
        }
      } catch (e) {
        if (mounted) {
           StatusFeedbackModal.show(
             context,
             title: AppLocalizations.of(context)!.errorTitle,
             message: AppLocalizations.of(context)!.joinListError(e.toString()),
             type: FeedbackType.error,
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
             // Pending Family Join (without list)
            _handleJoinFamily(SharingService.pendingFamilyId!, SharingService.pendingInviteCode);
            SharingService.pendingFamilyId = null;
            SharingService.pendingInviteCode = null;
          }
        }
      });
    });
    
    // Sync Local Name from Firestore Profile (Restores name after reinstall)
    ref.listen(userProfileProvider, (previous, next) {
      next.whenData((profile) {
        if (profile != null && profile.name != null) {
           final currentLocalName = ref.read(userNameProvider);
           // Only update if local is empty (priority to local edits, but fill holes from cloud)
           if (currentLocalName == null || currentLocalName.isEmpty) {
              ref.read(userNameProvider.notifier).setName(profile.name!);
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          Hero(
            tag: 'bottom_nav_bar',
            child: CustomBottomNavigation(
              currentIndex: currentIndex,
              onTap: _onTabTapped,
            ),
          ),
        ],
      ),
    );
  }
}

