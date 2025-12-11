import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';

class RevenueCatService {
  static const _apiKeyAndroid = 'goog_YOUR_ANDROID_KEY_HERE'; // TODO: Replace
  static const _apiKeyIOS = 'appl_BFVuFnVxDsDhiZLLOwUGkjDPXwb';
  
  static const entitlementId = 'premium';
  
  // Singleton
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  /// Initialize RevenueCat SDK
  Future<void> init(String? appUserId) async {
    await Purchases.setLogLevel(LogLevel.debug);

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
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
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
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      print('🔴 Restore error: $e');
      return false;
    }
  }

  /// Check current entitlement status
  Future<bool> checkPremiumStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      print('🔴 Error checking status: $e');
      return false;
    }
  }
}
