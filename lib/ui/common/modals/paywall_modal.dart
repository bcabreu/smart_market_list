import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/ui/common/modals/premium_success_modal.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/providers/subscription_provider.dart';
import 'package:smart_market_list/core/services/revenue_cat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_market_list/ui/common/modals/status_feedback_modal.dart';

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
  void initState() {
    super.initState();
    if (widget.initialTabIndex == 1) {
      _isFamilyPlan = true;
    }
    // Auto-check: If user is already premium locally (RC) but here (means Firestore is free),
    // we should auto-sync and close.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndAutoFix());
  }

  Future<void> _checkAndAutoFix() async {
    final details = await ref.read(revenueCatServiceProvider).getActiveSubscriptionDetails();
    final isPremium = details != null && details['isPremium'] == true;
    final planType = details?['planType'];

    if (isPremium && mounted) {
      // Logic: 
      // 1. If we are in "Family Mode" (_isFamilyPlan), ONLY close if user HAS Family Plan.
      // 2. If we are in "Any Mode" (default), close if user has ANY plan.
      
      if (_isFamilyPlan) {
         if (planType == 'premium_family') {
            print("🔵 [Paywall] Already Family Premium. Syncing...");
            await _handleSync(context, ref, autoClose: true);
         } else {
            print("🟡 [Paywall] User is Invalid Premium, but wants Family. Staying open for upgrade.");
         }
      } else {
         // Standard Paywall: If user has ANY premium, close it.
         print("🔵 [Paywall] User is Premium. Syncing...");
         await _handleSync(context, ref, autoClose: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offeringsAsync = ref.watch(subscriptionOfferingsProvider);
    
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
      body: offeringsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFFA726))),
        error: (err, stack) => Center(child: Text('Error loading offerings: $err', style: const TextStyle(color: Colors.white))),
        data: (offerings) {
          final currentOffering = offerings?.current;
          
          if (currentOffering == null) {
             return Center(child: Text(l10n.genericError('No offerings found'), style: const TextStyle(color: Colors.white)));
          }

          // Helper to find package by ID
          Package? getPackage(String id) {
            return currentOffering.availablePackages.firstWhere(
              (p) => p.identifier == id, 
              orElse: () => currentOffering.availablePackages.first // Fallback safely? Or handled below
            );
          }

          // Select packages based on Toggle
          final monthlyId = _isFamilyPlan ? 'family_monthly' : 'individual_monthly';
          final annualId = _isFamilyPlan ? 'family_yearly' : 'individual_yearly';

          // Try to find exact matches
          Package? monthlyPackage; 
          Package? annualPackage;
          
          try {
            monthlyPackage = currentOffering.availablePackages.firstWhere((p) => p.identifier == monthlyId);
            annualPackage = currentOffering.availablePackages.firstWhere((p) => p.identifier == annualId);
          } catch (_) {
            // If explicit IDs fail, fallback to standard .monthly / .annual for Individual at least
            // But for Family we really need the correct ID.
            if (!_isFamilyPlan) {
               monthlyPackage = currentOffering.monthly;
               annualPackage = currentOffering.annual;
            }
          }
          
          if (monthlyPackage == null || annualPackage == null) {
             return Center(child: Text(l10n.genericError('Packages not found in Offering'), style: const TextStyle(color: Colors.white)));
          }

          // Calculate Discount & Monthly Equivalent
          final monthlyPrice = monthlyPackage.storeProduct.price;
          final annualPrice = annualPackage.storeProduct.price;
          final currencyCode = annualPackage.storeProduct.currencyCode;
          
          int discountPercent = 0;
          if (monthlyPrice > 0) {
            final annualizedMonthly = monthlyPrice * 12;
            discountPercent = (((annualizedMonthly - annualPrice) / annualizedMonthly) * 100).round();
          }

          final monthlyEquivalentValue = annualPrice / 12;
          final monthlyEquivalentStr = "$currencyCode ${monthlyEquivalentValue.toStringAsFixed(2)}";

          return Column(
            children: [
              // 1. Header with Gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 60,
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
                      // Toggle Individual / Family (Disabled for now as RC example assumes simple packages)
                      // If you have specific Family packages in RC, you'd switch offerings here.
                      // For now, let's assume standard individual subscription via RC.
                      // If you want Family, you'd need a separate Offering or Package in RC.
                      
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
                      
                      // Features List (Conditioned)
                      if (_isFamilyPlan) ...[
                         // FAMILY FEATURES
                         _buildFeatureCard(l10n.featureFamilyShare, l10n.familyPlanSubtitle, icon: Icons.group_add, color: const Color(0xFFAB47BC), cardColor: cardColor),
                         _buildFeatureCard(l10n.featurePremiumGuest, l10n.featurePremiumGuestSubtitle, icon: Icons.star, color: Colors.orangeAccent, cardColor: cardColor), 
                         _buildFeatureCard(l10n.featureAutoSync, l10n.shareRealTimeInfo, icon: Icons.sync, color: const Color(0xFF4FC3F7), cardColor: cardColor),
                         _buildFeatureCard(l10n.featureAllBenefits, l10n.featureAllBenefitsSubtitle, icon: Icons.check_circle_outline, color: const Color(0xFFAED581), cardColor: cardColor),
                      ] else ...[
                         // INDIVIDUAL FEATURES
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



                      // Plans Row (Dynamic from RevenueCat)
                      Row(
                        children: [
                          Expanded(
                            child: _buildPlanOption(
                              title: l10n.planMonthly,
                              price: monthlyPackage.storeProduct.priceString,
                              subtitle: l10n.billedMonthly,
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
                              price: annualPackage.storeProduct.priceString,
                              subtitle: l10n.pricePerMonth(monthlyEquivalentStr),
                              yearPrice: l10n.billedAnnually, 
                              isSelected: _selectedPlanIndex == 1,
                              // badgeText: l10n.savePercent(discountPercent.toString()), // Old Discount Badge
                              badgeText: l10n.tryFree7Days, // New Free Trial Badge (Conversion Booster)
                              onTap: () => setState(() => _selectedPlanIndex = 1),
                              cardColor: cardColor,
                              highlightColor: const Color(0xFFFFA726),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _subscribe(context, ref, (_selectedPlanIndex == 0 ? monthlyPackage : annualPackage)!),
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
                                    l10n.subscribeButton(_selectedPlanIndex == 0 ? monthlyPackage.storeProduct.priceString : annualPackage.storeProduct.priceString),
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

                      // Restore Button
                      Center(
                         child: TextButton(
                           onPressed: () => _restorePurchases(context, ref),
                           child: Text(
                             'Restore Purchases', // Localize
                             style: TextStyle(color: Colors.grey[400], fontSize: 13, decoration: TextDecoration.underline),
                           ),
                         ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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

  Future<void> _subscribe(BuildContext context, WidgetRef ref, Package package) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print("🔵 Starting purchase for ${package.identifier}");
      // 1. Purchase via RevenueCat
      final success = await ref.read(revenueCatServiceProvider).purchasePackage(package);
      
      // Close Loading
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (success) {
        if (!context.mounted) return;
        await _handleSync(context, ref, autoClose: true);
      } else {
        print("🟡 Purchase returned false (Cancelled or Failed)");
      }
    } catch (e) {
      // Close Loading if active
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      
      print("🔴 Critical Purchase Error: $e");
      if (context.mounted) {
         final l10n = AppLocalizations.of(context)!;
         StatusFeedbackModal.show(
            context,
            title: l10n.purchaseErrorTitle ?? 'Erro na Compra',
            message: l10n.purchaseErrorMessage ?? 'Ocorreu um erro: $e',
            type: FeedbackType.error,
         );
      }
    }
  }

  /// Centralized Logic to Sync RC -> Firestore
  Future<void> _handleSync(BuildContext context, WidgetRef ref, {bool autoClose = false}) async {
      try {
          final user = FirebaseAuth.instance.currentUser;
          
          if (user == null) {
              print("⚠️ User is null (Visitor). Skipping Firestore sync.");
              // For visitors, we rely on RevenueCat caching, so skipping DB sync is fine.
              
              if (context.mounted && autoClose) {
                // Still close if we are auto-fixing based on local premium status
                 Navigator.pop(context);
                 // Check if we need to show success for visitor? 
                 // Usually yes, if RC says yes.
                 final isPremium = await ref.read(revenueCatServiceProvider).checkPremiumStatus();
                 if (isPremium) {
                    PremiumSuccessModal.show(context, isFamily: false);
                 }
              }
              return;
          }

          final details = await ref.read(revenueCatServiceProvider).getActiveSubscriptionDetails();
          
          if (details != null && details['isPremium'] == true) {
             print("🔵 Updating Firestore for uid: ${user.uid} with ${details['planType']}");
             
             await ref.read(firestoreServiceProvider).updateUserPremiumStatus(
                user.uid, 
                isPremium: true,
                planType: details['planType'] ?? 'premium_individual'
             );
             
             print("🟢 Firestore Updated.");
             
             if (context.mounted) {
                if (autoClose) Navigator.pop(context); // Close Paywall
                PremiumSuccessModal.show(context, isFamily: details['planType'].toString().contains('family'));
             }
          } else {
             print("⚠️ _handleSync called but no active subscription found in details.");
          }
      } catch (e) {
          print('🔴 Sync Error: $e');
          if (context.mounted && !autoClose) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao sincronizar: $e')));
          }
      }
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
     final l10n = AppLocalizations.of(context)!;

    // Security Check: Prevent Guest Restore (Anti-Farming)
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (!isLoggedIn) {
      if (context.mounted) {
        StatusFeedbackModal.show(
          context,
          title: l10n.loginRequiredTitle ?? "Login Necessário",
          message: l10n.loginRequiredMessage ?? "Faça login para restaurar e sincronizar sua assinatura.", 
          type: FeedbackType.info,
        );
      }
      return;
    }

     final success = await ref.read(revenueCatServiceProvider).restorePurchases();
     if (success) {
        if (context.mounted) {
            // Updated to Sync with Firestore
            await _handleSync(context, ref, autoClose: true);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchases Restored & Synced!')));
        }
     } else {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No subscription found to restore.')));
        }
     }
  }
}
