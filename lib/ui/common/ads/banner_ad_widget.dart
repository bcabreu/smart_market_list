import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ad_service.dart';
import '../../../data/models/user_profile.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/user_profile_provider.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  void _loadAd() {
    // Check if user is premium
    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile != null && (userProfile.planType == PlanType.premium_individual || userProfile.planType == PlanType.premium_family)) {
      return; // Do not load ad for premium
    }

    final bannerId = AdService.instance.bannerAdUnitId;

    _bannerAd = BannerAd(
      adUnitId: bannerId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
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
    // Re-check premium status in build to react to changes (e.g. upgrade)
    final userProfile = ref.watch(userProfileProvider).value;
    if (userProfile != null && (userProfile.planType == PlanType.premium_individual || userProfile.planType == PlanType.premium_family)) {
      return const SizedBox.shrink();
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
