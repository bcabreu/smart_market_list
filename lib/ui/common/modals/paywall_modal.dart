import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/ui/common/modals/premium_success_modal.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/providers/user_provider.dart';

class PaywallModal extends ConsumerStatefulWidget {
  final int initialTabIndex; // Kept for compatibility

  const PaywallModal({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<PaywallModal> createState() => _PaywallModalState();
}

class _PaywallModalState extends ConsumerState<PaywallModal> {
  // 0 = Monthly, 1 = Annual
  int _selectedPlanIndex = 1; 
  bool _isFamilyPlan = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Gradient from Image (Orange -> Pink)
    final mainGradient = const LinearGradient(
      colors: [Color(0xFFFFA726), Color(0xFFFF4081)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final backgroundColor = const Color(0xFF121212);
    final cardColor = const Color(0xFF1E1E1E);
    final textColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // 1. Header with Gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 60, // Increased to clear status bar
              bottom: 32, 
              left: 24, 
              right: 24
            ),
            decoration: BoxDecoration(
              gradient: mainGradient,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.emoji_events_outlined, 
                  size: 64, 
                  color: Colors.white
                ),
                const SizedBox(height: 16),
                Text(
                  _isFamilyPlan ? l10n.premiumFamilyTitle : l10n.bePremium,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isFamilyPlan ? l10n.shareAccessSubtitle : l10n.unlockResources,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle Individual / Family
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToggleButton(l10n.planToggleIndividual, !_isFamilyPlan, () {
                            setState(() => _isFamilyPlan = false);
                          }),
                          _buildToggleButton(l10n.planToggleFamily, _isFamilyPlan, () {
                            setState(() => _isFamilyPlan = true);
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: const Color(0xFF80CBC4), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.exclusiveResources,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Features List
                  if (_isFamilyPlan) ...[
                     _buildFeatureCard(l10n.featureAllBenefits, l10n.featureAllBenefitsSubtitle, icon: Icons.star, color: Colors.purpleAccent, cardColor: cardColor),
                     _buildFeatureCard(l10n.featureFamilyShare, l10n.shareAccessSubtitle, icon: Icons.group_add, color: const Color(0xFFFF4081), cardColor: cardColor),
                     _buildFeatureCard(l10n.featureAutoSync, l10n.shareListSubtitle, icon: Icons.sync, color: Colors.blueAccent, cardColor: cardColor),
                     _buildFeatureCard(l10n.featurePremiumGuest, l10n.featurePremiumGuestSubtitle, icon: Icons.person_add, color: Colors.greenAccent, cardColor: cardColor),
                  ] else ...[
                     _buildFeatureCard(l10n.featureReceiptScanning, l10n.featureReceiptScanningSubtitle, icon: Icons.receipt_long, color: Colors.orangeAccent, cardColor: cardColor),
                     _buildFeatureCard(l10n.featureRealTimeShare, l10n.featureRealTimeShareSubtitle, icon: Icons.share, color: const Color(0xFF4DB6AC), cardColor: cardColor),
                     _buildFeatureCard(l10n.featureNoAds, l10n.featureNoAds, icon: Icons.block, color: Colors.redAccent, cardColor: cardColor),
                     _buildFeatureCard(l10n.featureCharts, l10n.expenseChartsSubtitle, icon: Icons.show_chart, color: const Color(0xFF4FC3F7), cardColor: cardColor),
                     _buildFeatureCard(l10n.featureReports, l10n.exportReportsSubtitle, icon: Icons.description_outlined, color: const Color(0xFFFFF176), cardColor: cardColor),
                     _buildFeatureCard(l10n.featureCloudBackup, l10n.featureCloudBackupSubtitle, icon: Icons.security, color: const Color(0xFFAED581), cardColor: cardColor),
                  ],

                  const SizedBox(height: 32),

                  // "Escolha seu plano"
                  Center(
                    child: Text(
                      l10n.chooseYourPlan,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Plans Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildPlanOption(
                          title: l10n.planMonthly,
                          price: _isFamilyPlan ? l10n.planFamilyMonthlyPrice.split('/')[0] : l10n.planMonthlyPrice,
                          subtitle: _isFamilyPlan ? l10n.planFamilyMonthlySubtitle : l10n.planMonthlySubtitle,
                          yearPrice: '',
                          isSelected: _selectedPlanIndex == 0,
                          onTap: () => setState(() => _selectedPlanIndex = 0),
                          cardColor: cardColor,
                          highlightColor: const Color(0xFFFFA726),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPlanOption(
                          title: l10n.planAnnual,
                          price: _isFamilyPlan ? l10n.planFamilyAnnualBreakdown : l10n.planAnnualBreakdown,
                          subtitle: _isFamilyPlan ? l10n.planFamilyAnnualSubtitle : l10n.planAnnualSubtitle,
                          yearPrice: _isFamilyPlan ? l10n.planFamilyAnnualPrice : l10n.planAnnualPrice,
                          isSelected: _selectedPlanIndex == 1,
                          badgeText: '-40%',
                          onTap: () => setState(() => _selectedPlanIndex = 1),
                          cardColor: cardColor,
                          highlightColor: const Color(0xFFFFA726),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Savings Badge
                  if (_selectedPlanIndex == 1)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: const Color(0xFFFFA726)), // Orange border
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💰 ', style: TextStyle(fontSize: 16)),
                          Text(
                            _isFamilyPlan ? l10n.saveYiarlyAmountFamily : l10n.saveYiarlyAmount,
                            style: const TextStyle(
                              color: Color(0xFFFFA726),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _subscribe(context, ref),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: mainGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                l10n.subscribeButton(_getButtonPrice(l10n)),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Footer Text
                  Center(
                     child: Text(
                       '${l10n.cancelAnytime} • ${l10n.sevenDaysFree}',
                       style: TextStyle(color: Colors.grey[400], fontSize: 13),
                     ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFA726) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, {required IconData icon, required Color color, required Color cardColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.check, color: Color(0xFF80CBC4)),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required String title,
    required String price,
    required String subtitle,
    required String yearPrice,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardColor,
    required Color highlightColor,
    String? badgeText,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? highlightColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                if (isSelected)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Icon(Icons.check_circle, color: highlightColor, size: 24),
                  )
                else
                  const SizedBox(height: 24),
                
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (yearPrice.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    yearPrice,
                    style: TextStyle(fontSize: 12, color: highlightColor),
                  ),
                ] else
                   const SizedBox(height: 18), 
              ],
            ),
          ),
          if (badgeText != null)
            Positioned(
              top: -10,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper updated to take l10n
  String _getButtonPrice(AppLocalizations l10n) {
    if (_isFamilyPlan) {
      if (_selectedPlanIndex == 1) return l10n.planFamilyAnnualSubtitle;
      return l10n.planFamilyMonthlySubtitle;
    } else {
      if (_selectedPlanIndex == 1) return l10n.planAnnualSubtitle;
      return l10n.planMonthlySubtitle;
    }
  }

  void _subscribe(BuildContext context, WidgetRef ref) {
    final planType = _isFamilyPlan ? 'premium_family' : 'premium_individual';
    
    ref.read(premiumSinceProvider.notifier).setPremium(true);
    
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      ref.read(firestoreServiceProvider).updateUserPremiumStatus(
        user.uid, 
        isPremium: true,
        planType: planType
      );
    }
    
    Navigator.pop(context);
    PremiumSuccessModal.show(context, isFamily: _isFamilyPlan);
  }
}
