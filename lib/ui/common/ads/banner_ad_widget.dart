import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ad_service.dart';
import '../../../providers/user_profile_provider.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _loadScheduled = false;

  void _loadAd() {
    _loadScheduled = false;
    if (!mounted || _bannerAd != null || !AdService.instance.canShowAds) {
      return;
    }

    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile != null && userProfile.isPremium) {
      return;
    }

    final bannerId = AdService.instance.bannerAdUnitId;

    _bannerAd = BannerAd(
      adUnitId: bannerId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    if (profileState.isLoading) return const SizedBox.shrink();

    final userProfile = profileState.value;
    if (userProfile != null && userProfile.isPremium) {
      final existingAd = _bannerAd;
      if (existingAd != null) {
        _bannerAd = null;
        _isLoaded = false;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => existingAd.dispose(),
        );
      }
      return const SizedBox.shrink();
    }

    if (_bannerAd == null && !_loadScheduled && AdService.instance.canShowAds) {
      _loadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
    }

    if (_bannerAd != null && _isLoaded) {
      return SafeArea(
        top: false,
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
