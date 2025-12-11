import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();

  factory AdService() {
    return instance;
  }

  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  
  // Counter for item adds
  int _itemsAddedSessionCount = 0;
  static const int _adFrequency = 10;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
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
  /// Disposes current ad
  void dispose() {
    _interstitialAd?.dispose();
  }
}
