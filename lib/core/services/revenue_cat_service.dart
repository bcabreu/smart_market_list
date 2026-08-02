import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const _apiKeyAndroid = 'goog_raLiqgpczFimejjubyQVJpQYIEE';
  static const _apiKeyIOS = 'appl_BFVuFnVxDsDhiZLLOwUGkjDPXwb';

  static const entitlementIndividual = 'premium_individual';
  static const entitlementFamily = 'premium_family';

  // Singleton
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  /// Initialize RevenueCat SDK
  Future<void> init(String? appUserId) async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);

    PurchasesConfiguration? configuration;

    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKeyAndroid);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_apiKeyIOS);
    }

    if (configuration != null) {
      if (appUserId != null) {
        configuration.appUserID = appUserId;
      }
      await Purchases.configure(configuration);
    }
  }

  /// Update App User ID (e.g. on Login)
  Future<void> logIn(String appUserId) async {
    try {
      await Purchases.logIn(appUserId);
    } catch (e) {
      print('🔴 Error logging in to RevenueCat: $e');
    }
  }

  /// Clear User ID (e.g. on Logout)
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      print('🔴 Error logging out: $e');
    }
  }

  /// Get Offerings (Products to display)
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings;
    } on PlatformException catch (e) {
      print('🔴 Error fetching offerings: $e');
      return null;
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      return _checkEntitlements(purchaseResult.customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print('🔴 Purchase error: $e');
      }
      return false; // Cancelled or error
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return _checkEntitlements(customerInfo);
    } on PlatformException catch (e) {
      print('🔴 Restore error: $e');
      return false;
    }
  }

  /// Check current entitlement status
  Future<bool> checkPremiumStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _checkEntitlements(customerInfo);
    } on PlatformException catch (e) {
      print('🔴 Error checking status: $e');
      return false;
    }
  }

  /// Get active subscription details to sync with Firestore
  Future<Map<String, dynamic>?> getActiveSubscriptionDetails() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();

      if (kDebugMode) {
        debugPrint(
          'RevenueCat active entitlements: '
          '${customerInfo.entitlements.active.keys}',
        );
      }

      // 1. Check Specific Product IDs (Source of Truth)
      // This bypasses potential Entitlement Mapping errors in RevenueCat Dashboard
      // CRITICAL: Android Product IDs in Play Console MUST contain 'individual' or 'family'.

      bool hasIndividual = false;
      bool hasFamily = false;

      for (final productID in customerInfo.activeSubscriptions) {
        final id = productID.toLowerCase();
        if (id.contains('individual')) hasIndividual = true;
        if (id.contains('family')) hasFamily = true;
      }

      // PRIORITY LOGIC FIX:
      // If a user has BOTH (e.g. Sandbox upgrade/overlap), Family takes precedence.
      // We check Family FIRST.

      if (hasFamily) {
        print("✅ Identified Family Plan via Product ID (Priority)");
        return {'isPremium': true, 'planType': 'premium_family'};
      }

      if (hasIndividual) {
        print("✅ Identified Individual Plan via Product ID");
        return {'isPremium': true, 'planType': 'premium_individual'};
      }

      // Entitlements remain the fallback if product identifiers are renamed.
      final individual = customerInfo.entitlements.all[entitlementIndividual];
      if (individual != null) {
        print(
          "   - Individual: Active=${individual.isActive}, Exprires=${individual.expirationDate}",
        );
      }

      final family = customerInfo.entitlements.all[entitlementFamily];
      if (family != null) {
        print(
          "   - Family: Active=${family.isActive}, Exprires=${family.expirationDate}",
        );
      }

      if (individual?.isActive == true) {
        print("✅ Found Active Individual Entitlement");
        return {'isPremium': true, 'planType': 'premium_individual'};
      }

      if (family?.isActive == true) {
        print("✅ Found Active Family Entitlement");
        return {'isPremium': true, 'planType': 'premium_family'};
      }

      return null;
    } catch (e) {
      print('🔴 Error getting subscription details: $e');
      return null;
    }
  }

  /// Helper to check if ANY premium entitlement is active
  /// Helper to check if ANY premium entitlement is active
  bool _checkEntitlements(CustomerInfo info) {
    final individual =
        info.entitlements.all[entitlementIndividual]?.isActive ?? false;
    final family = info.entitlements.all[entitlementFamily]?.isActive ?? false;

    if (individual || family) return true;

    return info.activeSubscriptions.any((productId) {
      final normalized = productId.toLowerCase();
      return normalized.contains('individual') || normalized.contains('family');
    });
  }
}
