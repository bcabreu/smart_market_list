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
import 'package:smart_market_list/providers/locale_provider.dart';
import 'package:smart_market_list/ui/common/modals/loading_dialog.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.privacy,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Última atualização: 06/12/2025',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPolicySection(
                      context,
                      '1. Coleta de Dados',
                      'Coletamos apenas as informações necessárias para o funcionamento do app, como suas listas de compras e receitas salvas. Todos os dados são armazenados localmente no seu dispositivo.',
                    ),
                    _buildPolicySection(
                      context,
                      '2. Uso das Informações',
                      'Suas informações são utilizadas exclusivamente para personalizar sua experiência, sugerir receitas baseadas nos seus itens e facilitar suas compras.',
                    ),
                    _buildPolicySection(
                      context,
                      '3. Compartilhamento',
                      'Não compartilhamos seus dados pessoais com terceiros. O recurso de compartilhamento de lista funciona através de links seguros gerados por você.',
                    ),
                    _buildPolicySection(
                      context,
                      '4. Segurança',
                      'Empregamos medidas de segurança padrão da indústria para proteger suas informações contra acesso não autorizado.',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[400] 
                  : Colors.grey[600],
            ),
          ),
        ],
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
                          onTap: () {},
                        ),
                        SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: l10n.privacy,
                          onTap: () => _showPrivacyPolicy(context),
                        ),
                        SettingsTile(
                          icon: Icons.logout,
                          title: l10n.logout,
                          onTap: () {},
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
    final Uri url = Uri.parse('https://apps.apple.com/account/subscriptions');
    try {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível abrir o gerenciamento de assinaturas.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      }
    }


  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    try {
      LoadingDialog.show(context, 'Restaurando compras...');
      
      final service = ref.read(iapServiceProvider);
      // Ensure service is initialized/listening
      await service.initialize();
      
      final initiated = await service.restorePurchases();
      
      if (context.mounted) {
        LoadingDialog.hide(context);
        
        if (initiated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitação enviada. Se houver compras ativas, elas serão restauradas em breve.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível conectar à loja.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
