import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/user_profile.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/ui/common/modals/premium_success_modal.dart';

class PaywallModal extends ConsumerWidget {
  final int initialTabIndex;

  const PaywallModal({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Icon(Icons.star, size: 50, color: Colors.white),
            const SizedBox(height: 8),
            const Text(
              'Premium',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tabs
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: const Color(0xFFFF9A9E),
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                splashBorderRadius: BorderRadius.circular(20),
                tabs: const [
                  Tab(text: 'Individual'),
                  Tab(text: 'Família (+1)'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              height: 280, // Fixed height for constraints
              child: TabBarView(
                children: [
                  // Individual Tab
                  Column(
                    children: [
                      _buildFeatureItem('Salvar notas fiscais ilimitadas'),
                      _buildFeatureItem('Comparar preços entre mercados'),
                      _buildFeatureItem('Gráficos de gastos mensais'),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPlanCard(
                              title: 'ANUAL',
                              price: 'R\$ 89,90/ano',
                              subtitle: 'Economize 25%',
                              isPopular: true,
                              onTap: () => _subscribe(context, ref, isFamily: false, isAnnual: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPlanCard(
                              title: 'MENSAL',
                              price: 'R\$ 9,90/mês',
                              subtitle: 'Cancele quando quiser',
                              isPopular: false,
                              onTap: () => _subscribe(context, ref, isFamily: false, isAnnual: false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Family Tab
                  Column(
                    children: [
                      _buildFeatureItem('Tudo do Individual para 2 pessoas'),
                      _buildFeatureItem('Compartilhamento Automático'),
                      _buildFeatureItem('Acesso Premium para o convidado'),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPlanCard(
                              title: 'ANUAL',
                              price: 'R\$ 129,90/ano',
                              subtitle: 'Apenas R\$ 5,41/pessoa/mês',
                              isPopular: true,
                              onTap: () => _subscribe(context, ref, isFamily: true, isAnnual: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPlanCard(
                              title: 'MENSAL',
                              price: 'R\$ 14,90/mês',
                              subtitle: '2 Contas Premium',
                              isPopular: false,
                              onTap: () => _subscribe(context, ref, isFamily: true, isAnnual: false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Pagamento seguro via App Store/Play Store',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String subtitle,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPopular ? Border.all(color: AppColors.secondary, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MAIS POPULAR',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _subscribe(BuildContext context, WidgetRef ref, {required bool isFamily, required bool isAnnual}) {
    // Simulate subscription logic
    final planType = isFamily ? 'premium_family' : 'premium_individual';
    
    // Updates local provider
    ref.read(premiumSinceProvider.notifier).setPremium(true);
    
    // Sync with Firestore if logged in
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      ref.read(firestoreServiceProvider).updateUserPremiumStatus(
        user.uid, 
        isPremium: true,
        planType: planType
      );
    }
    
    Navigator.pop(context);
    
    // Show Premium Success Modal
    PremiumSuccessModal.show(context, isFamily: isFamily);
  }
}
