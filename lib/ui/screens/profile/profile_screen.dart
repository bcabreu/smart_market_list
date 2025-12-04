import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/providers/theme_provider.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/ui/common/modals/paywall_modal.dart';
import 'package:smart_market_list/ui/screens/profile/widgets/profile_header.dart';
import 'package:smart_market_list/ui/screens/profile/widgets/settings_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaywallModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            const ProfileHeader(),
            const SizedBox(height: 16),
            
            // Preferences
            SettingsCard(
              title: 'Configurações',
              children: [
                SettingsTile(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  subtitle: _getThemeModeName(themeMode),
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
                const SettingsTile(
                  icon: Icons.notifications,
                  title: 'Notificações',
                  subtitle: 'Alertas de promoção',
                  trailing: Icon(Icons.toggle_on, color: AppColors.primary, size: 40),
                ),
                const SettingsTile(
                  icon: Icons.language,
                  title: 'Idioma',
                  subtitle: 'Português (BR)',
                ),
              ],
            ),

            // Premium Features
            SettingsCard(
              title: 'Recursos Premium',
              children: [
                SettingsTile(
                  icon: Icons.share,
                  title: 'Compartilhar Lista',
                  subtitle: 'Sincronize com família',
                  isLocked: !isPremium,
                  onTap: !isPremium ? () => _showPaywall(context) : null,
                ),
                SettingsTile(
                  icon: Icons.bar_chart,
                  title: 'Gráficos de Gastos',
                  subtitle: 'Análise mensal completa',
                  isLocked: !isPremium,
                  onTap: !isPremium ? () => _showPaywall(context) : null,
                ),
                SettingsTile(
                  icon: Icons.picture_as_pdf,
                  title: 'Exportar Relatórios',
                  subtitle: 'PDF com histórico',
                  isLocked: !isPremium,
                  onTap: !isPremium ? () => _showPaywall(context) : null,
                ),
              ],
            ),

            // Account
            SettingsCard(
              title: 'Conta',
              children: [
                SettingsTile(
                  icon: Icons.credit_card,
                  title: 'Gerenciar Assinatura',
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.restore,
                  title: 'Restaurar Compra',
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Ajuda e Suporte',
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.logout,
                  title: 'Sair da Conta',
                  onTap: () {},
                  trailing: const SizedBox(), // Hide chevron
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'Seguir sistema';
      case ThemeMode.light: return 'Claro';
      case ThemeMode.dark: return 'Escuro';
    }
  }
}
