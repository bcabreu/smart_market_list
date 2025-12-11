import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:smart_market_list/core/services/revenue_cat_service.dart';

// Service Provider
final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService();
});

// Current Offerings (Products) Provider
final subscriptionOfferingsProvider = FutureProvider<Offerings?>((ref) async {
  final service = ref.watch(revenueCatServiceProvider);
  return await service.getOfferings();
});

// Premium Status Provider (Live from RevenueCat)
// This overrides or complements the local/firestore check
class SubscriptionStatusNotifier extends StateNotifier<bool> {
  final RevenueCatService _service;
  
  SubscriptionStatusNotifier(this._service) : super(false) {
    _checkStatus();
    // Listen to purchase updates globally
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateStatus(customerInfo);
    });
  }

  Future<void> _checkStatus() async {
    final isPremium = await _service.checkPremiumStatus();
    state = isPremium;
  }

  void _updateStatus(CustomerInfo info) {
    final isPremium = info.entitlements.all[RevenueCatService.entitlementId]?.isActive ?? false;
    state = isPremium;
  }

  Future<bool> restorePurchases() async {
    final isPremium = await _service.restorePurchases();
    state = isPremium;
    return isPremium;
  }
}

final subscriptionStatusProvider = StateNotifierProvider<SubscriptionStatusNotifier, bool>((ref) {
  final service = ref.watch(revenueCatServiceProvider);
  return SubscriptionStatusNotifier(service);
});
