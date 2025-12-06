import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/providers/theme_provider.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/ui/common/modals/paywall_modal.dart';
import 'package:smart_market_list/ui/screens/profile/widgets/profile_summary.dart';
import 'package:smart_market_list/ui/screens/profile/widgets/profile_header.dart';
import 'package:smart_market_list/ui/screens/profile/widgets/profile_stats.dart';
import 'package:smart_market_list/ui/screens/profile/widgets/settings_card.dart';
import 'package:smart_market_list/providers/notifications_provider.dart';

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

  void _showPrivacyPolicy(BuildContext context) {
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Política de Privacidade',
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
                        SettingsTile(
                          icon: Icons.notifications,
                          title: 'Notificações',
                          subtitle: 'Alertas de promoção',
                          trailing: Switch(
                            value: notificationsEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              ref.read(notificationsEnabledProvider.notifier).setEnabled(val);
                            },
                          ),
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
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacidade',
                          onTap: () => _showPrivacyPolicy(context),
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
