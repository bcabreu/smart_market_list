import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:smart_market_list/core/services/backend_service.dart';
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
  final BackendService _backend;

  final Ref _ref;

  SubscriptionStatusNotifier(this._service, this._backend, this._ref)
    : super(false) {
    _checkStatus();
    // Listen to purchase updates globally
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      unawaited(_updateStatus(customerInfo));
    });
  }

  Future<void> _checkStatus() async {
    final isPremium = await _service.checkPremiumStatus();
    state = isPremium;

    // Also update plan type initial check
    final details = await _service.getActiveSubscriptionDetails();
    if (details != null) {
      Future.microtask(() {
        _ref
            .read(revenueCatPlanTypeProvider.notifier)
            .setPlan(details['planType']);
      });
    }
    await _syncServerStatus();
  }

  Future<void> _updateStatus(CustomerInfo info) async {
    final individual =
        info
            .entitlements
            .all[RevenueCatService.entitlementIndividual]
            ?.isActive ??
        false;
    final family =
        info.entitlements.all[RevenueCatService.entitlementFamily]?.isActive ??
        false;

    state = individual || family;

    // FIX: Defer provider updates to avoid "modifying provider during build" error
    Future.microtask(() {
      if (family) {
        _ref
            .read(revenueCatPlanTypeProvider.notifier)
            .setPlan('premium_family');
      } else if (individual) {
        _ref
            .read(revenueCatPlanTypeProvider.notifier)
            .setPlan('premium_individual');
      } else {
        _ref.read(revenueCatPlanTypeProvider.notifier).setPlan(null);
      }
    });
    await _syncServerStatus();
  }

  Future<void> _syncServerStatus() async {
    try {
      await _backend.syncRevenueCatStatus();
    } catch (_) {
      // Anonymous/offline users cannot sync. Access remains based on the last
      // server-validated profile, never on this local listener.
    }
  }

  Future<bool> restorePurchases() async {
    final isPremium = await _service.restorePurchases();
    state = isPremium;
    await _syncServerStatus();
    return isPremium;
  }
}

final subscriptionStatusProvider =
    StateNotifierProvider<SubscriptionStatusNotifier, bool>((ref) {
      final service = ref.watch(revenueCatServiceProvider);
      final backend = ref.watch(backendServiceProvider);
      return SubscriptionStatusNotifier(service, backend, ref);
    });

// Plan Type Provider (Tracks 'premium_family' vs 'premium_individual' for visitors)
class PlanTypeNotifier extends StateNotifier<String?> {
  PlanTypeNotifier() : super(null);
  void setPlan(String? plan) => state = plan;
}

final revenueCatPlanTypeProvider =
    StateNotifierProvider<PlanTypeNotifier, String?>((ref) {
      return PlanTypeNotifier();
    });
