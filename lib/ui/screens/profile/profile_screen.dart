import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/core/services/iap_service.dart';
import 'package:smart_market_list/providers/theme_provider.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/ui/common/modals/paywall_modal.dart';
import 'package:smart_market_list/ui/screens/profile/widgets/profile_summary.dart';
import 'package:smart_market_list/ui/screens/profile/widgets/profile_header.dart';
import 'package:smart_market_list/ui/screens/profile/widgets/profile_stats.dart';
import 'package:smart_market_list/ui/screens/profile/widgets/settings_card.dart';
import 'package:smart_market_list/providers/notifications_provider.dart';
import 'package:smart_market_list/ui/screens/profile/modals/share_list_modal.dart';
import 'package:smart_market_list/ui/screens/profile/modals/expense_charts_modal.dart';
import 'package:smart_market_list/ui/screens/profile/modals/help_support_modal.dart';
import 'package:smart_market_list/providers/locale_provider.dart';
import 'package:smart_market_list/ui/common/modals/loading_dialog.dart';
import 'package:smart_market_list/ui/common/modals/status_feedback_modal.dart';
import 'package:smart_market_list/core/services/pdf_service.dart';
import 'package:smart_market_list/providers/goals_provider.dart';
import 'package:smart_market_list/providers/shopping_notes_provider.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/providers/shared_users_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final currentLocale = ref.watch(localeProvider);
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.language,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('📱', style: TextStyle(fontSize: 24)),
                title: Text(AppLocalizations.of(context)!.darkModeSystem),
                trailing: currentLocale == null ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(null);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: const Text('English'),
                trailing: currentLocale?.languageCode == 'en' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇧🇷', style: TextStyle(fontSize: 24)),
                title: const Text('Português (BR)'),
                trailing: currentLocale?.languageCode == 'pt' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(const Locale('pt'));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaywallModal(),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                   Text(
                    l10n.privacy,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.privacyPolicyText,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            ),
             Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    
    // Get shared count for active list
    final currentList = ref.watch(currentListProvider);
    final sharedUsers = currentList != null 
        ? (ref.watch(sharedUsersProvider)[currentList.id] ?? []) 
        : <String>[];
    final sharedCount = sharedUsers.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            const ProfileHeader(),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    // Restored Profile Info (Avatar, Stats)
                    const ProfileSummary(),
                    
                    const SizedBox(height: 24),

                    // Stats Row
                    const ProfileStats(),
                    
                    const SizedBox(height: 24),
                    
                    // Preferences
                    SettingsCard(
                      title: l10n.settingsTitle,
                      children: [
                        SettingsTile(
                          icon: Icons.dark_mode,
                          title: l10n.darkMode,
                          subtitle: _getThemeModeName(themeMode, l10n),
                          trailing: Switch(
                            value: themeMode == ThemeMode.dark,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              ref.read(themeModeProvider.notifier).setTheme(
                                val ? ThemeMode.dark : ThemeMode.light
                              );
                            },
                          ),
                        ),
                        SettingsTile(
                          icon: Icons.notifications,
                          title: l10n.notifications,
                          subtitle: l10n.notificationsSubtitle,
                          trailing: Switch(
                            value: notificationsEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              ref.read(notificationsEnabledProvider.notifier).setEnabled(val);
                            },
                          ),
                        ),
                        SettingsTile(
                          icon: Icons.language,
                          title: l10n.language,
                          subtitle: locale == null 
                              ? l10n.darkModeSystem 
                              : (locale.languageCode == 'en' ? 'English' : 'Português (BR)'),
                          onTap: () => _showLanguagePicker(context, ref),
                        ),
                      ],
                    ),

                    // Premium Features
                    SettingsCard(
                      title: l10n.premiumFeatures,
                      children: [
                        SettingsTile(
                          icon: Icons.share,
                          title: l10n.shareList,
                          subtitle: sharedCount > 0 
                              ? (locale?.languageCode == 'pt' 
                                  ? 'Compartilhado com $sharedCount pessoa${sharedCount > 1 ? 's' : ''}' 
                                  : 'Shared with $sharedCount person${sharedCount > 1 ? 's' : ''}')
                              : l10n.shareListSubtitle,
                          isLocked: !isPremium,
                          onTap: !isPremium 
                              ? () => _showPaywall(context) 
                              : () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context).viewInsets.bottom,
                                    ),
                                    child: const ShareListModal(),
                                  ),
                                ),
                        ),
                        SettingsTile(
                          icon: Icons.bar_chart,
                          title: l10n.expenseCharts,
                          subtitle: l10n.expenseChartsSubtitle,
                          isLocked: !isPremium,
                          onTap: !isPremium 
                              ? () => _showPaywall(context) 
                              : () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const ExpenseChartsModal(),
                                ),
                        ),
                        SettingsTile(
                          icon: Icons.picture_as_pdf,
                          title: l10n.exportReports,
                          subtitle: l10n.exportReportsSubtitle,
                          isLocked: !isPremium,
                          onTap: !isPremium ? () => _showPaywall(context) : () => _generatePdfReport(context, ref),
                        ),
                      ],
                    ),

                    // Account
                    SettingsCard(
                      title: l10n.account,
                      children: [
                        SettingsTile(
                          icon: Icons.credit_card,
                          title: l10n.manageSubscription,
                          onTap: () => _manageSubscription(context),
                        ),
                        SettingsTile(
                          icon: Icons.restore,
                          title: l10n.restorePurchase,
                          onTap: () => _restorePurchases(context, ref),
                        ),
                        SettingsTile(
                          icon: Icons.help_outline,
                          title: l10n.helpSupport,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const HelpSupportModal(),
                          ),
                        ),
                        SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: l10n.privacy,
                          onTap: () => _showPrivacyPolicy(context),
                        ),
                        SettingsTile(
                          icon: Icons.delete_forever,
                          title: l10n.deleteAccount,
                          onTap: () => _deleteAccount(context, ref),
                          textColor: Colors.red,
                        ),
                        SettingsTile(
                          icon: Icons.logout,
                          title: l10n.logout,
                          onTap: () => _logout(context, ref),
                          trailing: const SizedBox(), // Hide chevron
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _generatePdfReport(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading dialog
      LoadingDialog.show(context, 'Gerando relatório em PDF...');

      // Small delay to ensure UI renders
      await Future.delayed(const Duration(milliseconds: 500));

      final notesAsync = ref.read(shoppingNotesProvider);
      final notes = notesAsync.value ?? []; 
      
      // Calculate goals for last 12 months
      final now = DateTime.now();
      final Map<String, double> goalsMap = {};
      
      for (int i = 0; i < 12; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        final goal = ref.read(goalsProvider.notifier).getGoal(key);
        goalsMap[key] = goal;
      }

      final l10n = AppLocalizations.of(context)!;
      final locale = Localizations.localeOf(context);

      await PdfService().generateAndShareReport(
        notes: notes, 
        goals: goalsMap,
        l10n: l10n,
        locale: locale,
      );
      
      // Hide loading
      if (context.mounted) {
        LoadingDialog.hide(context);
      }

    } catch (e) {
      if (context.mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar relatório: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getThemeModeName(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.system: return l10n.darkModeSystem;
      case ThemeMode.light: return l10n.darkModeLight;
      case ThemeMode.dark: return l10n.darkModeDark;
    }
  }

  Future<void> _manageSubscription(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri url = Uri.parse('https://apps.apple.com/account/subscriptions');
    try {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (context.mounted) {
        StatusFeedbackModal.show(
          context,
          title: l10n.errorTitle,
          message: l10n.subscriptionManagementError,
          type: FeedbackType.error,
        );
      }
    }
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      LoadingDialog.show(context, l10n.restoringPurchases);
      
      final service = ref.read(iapServiceProvider);
      // Ensure service is initialized/listening
      await service.initialize();
      
      final initiated = await service.restorePurchases();
      
      if (context.mounted) {
        LoadingDialog.hide(context);
        
        if (initiated) {
          StatusFeedbackModal.show(
            context,
            title: l10n.requestSentTitle,
            message: l10n.restoreSuccess,
            type: FeedbackType.success,
          );
        } else {
          StatusFeedbackModal.show(
            context,
            title: l10n.connectionErrorTitle,
            message: l10n.restoreError,
            type: FeedbackType.error,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        LoadingDialog.hide(context);
        StatusFeedbackModal.show(
          context,
          title: l10n.errorTitle,
          message: e.toString(),
          type: FeedbackType.error,
        );
      }
    }
  }
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE), // Red 50
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  size: 32,
                  color: Color(0xFFEF5350), // Red 400
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                l10n.deleteAccountTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Message
              Text(
                l10n.deleteAccountMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF5350), // Red 400
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.confirmDelete,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
       LoadingDialog.show(context, l10n.processing);
       
       try {
         // 1. Wipe Hive Data
         final shoppingListService = ref.read(shoppingListServiceProvider);
         await shoppingListService.deleteAllData();

         // 2. Clear Shared Preferences & User State
         ref.read(isLoggedInProvider.notifier).state = false;
         await ref.read(userEmailProvider.notifier).clearEmail();
         await ref.read(userNameProvider.notifier).clearName();
         
         // 3. Clear Shopping Notes
         final notesService = ref.read(shoppingNotesServiceProvider);
         await notesService.deleteAllNotes();
         
         // Wait a bit for UX
         await Future.delayed(const Duration(seconds: 1));

         if (context.mounted) {
           LoadingDialog.hide(context);
           // Navigate to Root
           Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
         }
       } catch (e) {
         if (context.mounted) {
           LoadingDialog.hide(context);
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error deleting account: $e')),
           );
         }
       }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE), // Red 50
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 32,
                  color: Color(0xFFEF5350), // Red 400
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                l10n.logoutTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Message
              Text(
                l10n.logoutMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF5350), // Red 400
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.confirmLogout,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      // Clear user state
      ref.read(isLoggedInProvider.notifier).state = false;
      await ref.read(userEmailProvider.notifier).clearEmail();
      await ref.read(userNameProvider.notifier).clearName();

      if (context.mounted) {
         Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }
}
