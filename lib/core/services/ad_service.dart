import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AdService {
  static final AdService instance = AdService._internal();

  factory AdService() {
    return instance;
  }

  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  
  // Counter for item adds (session-based, for interstitial ads)
  int _itemsAddedSessionCount = 0;
  static const int _adFrequency = 10;

  // Counter for paywall upsell (persistent, accumulated across sessions)
  static const int _paywallFrequency = 10;
  static const String _paywallCounterKey = 'paywall_item_counter';

  // Counter for app open paywall (persistent)
  static const int _firstPaywallOpen = 3; // Show on 3rd app open
  static const int _repeatPaywallInterval = 5; // Then every 5 opens
  static const String _appOpenCounterKey = 'app_open_counter';

  // Counter for recipe views
  int _recipesViewedSessionCount = 0;
  static const int _recipeAdFrequency = 5;

  /// Request App Tracking Transparency permission on iOS
  /// Must be called before initializing Mobile Ads SDK
  Future<TrackingStatus> requestTrackingPermission() async {
    // Only request on iOS
    if (!Platform.isIOS) {
      return TrackingStatus.notSupported;
    }

    // Check current status first
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    
    // If not determined yet, request permission
    if (status == TrackingStatus.notDetermined) {
      // Small delay to ensure app is fully loaded (Apple recommendation)
      await Future.delayed(const Duration(milliseconds: 500));
      final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();
      print('📱 ATT Permission Result: $newStatus');
      return newStatus;
    }
    
    print('📱 ATT Status already set: $status');
    return status;
  }

  Future<void> initialize() async {
    // Request ATT permission BEFORE initializing ads (iOS 14.5+ requirement)
    await requestTrackingPermission();
    
    await MobileAds.instance.initialize();
    loadInterstitial(); // Pre-load immediately
  }

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Android Banner ID (Production)
      return 'ca-app-pub-8735023541465246/9121190351';  
    } else if (Platform.isIOS) {
      // Prod ID for iOS Banner
      return 'ca-app-pub-8735023541465246/9460101708';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // Android Interstitial ID (Production)
      return 'ca-app-pub-8735023541465246/4175167195';
    } else if (Platform.isIOS) {
      // Prod ID for iOS Interstitial
      return 'ca-app-pub-8735023541465246/8613089749';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Load an interstitial ad to be ready for showing
  void loadInterstitial() {
    if (_interstitialAd != null || _isInterstitialLoading) return;

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print('$ad loaded');
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Show the interstitial ad if available. 
  /// Executes [onAdDismissed] when closed, or immediately if ad not ready.
  void showInterstitialAd({required VoidCallback onAdDismissed}) {
    if (_interstitialAd == null) {
      print('Warning: Interstitial Ad not ready, executing callback immediately.');
      onAdDismissed();
      loadInterstitial(); // Try to load for next time
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _interstitialAd = null; // Clear reference
        onAdDismissed();
        loadInterstitial(); // Load next one
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed(); // Proceed anyway
        loadInterstitial();
      },
    );

    _interstitialAd!.show();
  }

  /// Checks if ad should be shown based on item count.
  /// Returns true if ad was triggered (and callback will be called).
  /// Returns false if ad not triggered (callback called immediately).
  bool checkItemAdTrigger({required VoidCallback onContinue}) {
    _itemsAddedSessionCount++;
    print('AdService: Items added: $_itemsAddedSessionCount');
    
    if (_itemsAddedSessionCount >= _adFrequency) {
      _itemsAddedSessionCount = 0; // Reset
      showInterstitialAd(onAdDismissed: onContinue);
      return true;
    }
    
    onContinue();
    return false;
  }

  /// Checks if ad should be shown based on recipe view count.
  /// Returns true if ad was triggered (and callback will be called).
  /// Returns false if ad not triggered (callback called immediately).
  bool checkRecipeAdTrigger({required VoidCallback onContinue}) {
    _recipesViewedSessionCount++;
    print('AdService: Recipes viewed: $_recipesViewedSessionCount');
    
    if (_recipesViewedSessionCount >= _recipeAdFrequency) {
      _recipesViewedSessionCount = 0; // Reset
      showInterstitialAd(onAdDismissed: onContinue);
      return true;
    }
    
    onContinue();
    return false;
  }

  /// Checks if premium paywall should be shown based on accumulated item count.
  /// Uses persistent storage so count survives app restarts.
  /// Returns true if paywall should be shown (every 10 items).
  bool shouldShowPaywall() {
    try {
      final box = Hive.box('settings');
      int count = box.get(_paywallCounterKey, defaultValue: 0) as int;
      count++;
      
      if (count >= _paywallFrequency) {
        box.put(_paywallCounterKey, 0); // Reset
        print('AdService: Paywall trigger reached ($count items)');
        return true;
      }
      
      box.put(_paywallCounterKey, count);
      print('AdService: Paywall counter: $count/$_paywallFrequency');
      return false;
    } catch (e) {
      print('AdService: Paywall counter error: $e');
      return false;
    }
  }

  /// Checks if premium paywall should be shown on app open.
  /// Shows on the 3rd open, then every 5th open after that (8th, 13th, 18th...).
  bool shouldShowPaywallOnOpen() {
    try {
      final box = Hive.box('settings');
      int count = box.get(_appOpenCounterKey, defaultValue: 0) as int;
      count++;
      box.put(_appOpenCounterKey, count);
      
      print('AdService: App open count: $count');
      
      // First trigger at 3rd open
      if (count == _firstPaywallOpen) {
        return true;
      }
      
      // After 3rd open, trigger every 5 opens (8, 13, 18, 23...)
      if (count > _firstPaywallOpen && (count - _firstPaywallOpen) % _repeatPaywallInterval == 0) {
        return true;
      }
      
      return false;
    } catch (e) {
      print('AdService: App open counter error: $e');
      return false;
    }
  }

  /// Disposes current ad
  void dispose() {
    _interstitialAd?.dispose();
  }
}
