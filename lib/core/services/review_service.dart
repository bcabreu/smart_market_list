import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:in_app_review/in_app_review.dart';

/// Service to manage in-app review prompts
/// Follows best practices:
/// - Only prompt after positive user actions
/// - Respect cooldown periods (30 days)
/// - Require minimum usage thresholds
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;
  
  // Keys for Hive storage
  static const String _boxName = 'review_settings';
  static const String _lastPromptKey = 'last_review_prompt';
  static const String _promptCountKey = 'review_prompt_count';
  static const String _appOpenCountKey = 'app_open_count';
  static const String _listsCompletedKey = 'lists_completed_count';
  static const String _hasReviewedKey = 'has_reviewed';

  // Configuration
  static const int _minAppOpens = 5;           // Minimum app opens before prompting
  static const int _minListsCompleted = 2;     // Minimum completed lists before prompting
  static const int _cooldownDays = 30;         // Days between prompts
  static const int _maxPrompts = 3;            // Maximum total prompts

  Box? _box;

  /// Initialize the service and track app open
  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox(_boxName);
      } else {
        _box = Hive.box(_boxName);
      }
      await incrementAppOpens();
    } catch (e) {
      debugPrint('ReviewService init error: $e');
    }
  }

  /// Track app opens
  Future<void> incrementAppOpens() async {
    try {
      final currentCount = _box?.get(_appOpenCountKey, defaultValue: 0) ?? 0;
      await _box?.put(_appOpenCountKey, currentCount + 1);
      debugPrint('📊 App opens: ${currentCount + 1}');
    } catch (e) {
      debugPrint('Error tracking app opens: $e');
    }
  }

  /// Track completed lists
  Future<void> incrementListsCompleted() async {
    try {
      final currentCount = _box?.get(_listsCompletedKey, defaultValue: 0) ?? 0;
      await _box?.put(_listsCompletedKey, currentCount + 1);
      debugPrint('📊 Lists completed: ${currentCount + 1}');
    } catch (e) {
      debugPrint('Error tracking completed lists: $e');
    }
  }

  /// Check if we should show review prompt
  Future<bool> shouldPromptReview() async {
    try {
      // Check if already reviewed (user said yes before)
      final hasReviewed = _box?.get(_hasReviewedKey, defaultValue: false) ?? false;
      if (hasReviewed) {
        debugPrint('🎯 ReviewService: Already reviewed, skipping');
        return false;
      }

      // Check max prompts
      final promptCount = _box?.get(_promptCountKey, defaultValue: 0) ?? 0;
      if (promptCount >= _maxPrompts) {
        debugPrint('🎯 ReviewService: Max prompts reached ($promptCount)');
        return false;
      }

      // Check minimum app opens
      final appOpens = _box?.get(_appOpenCountKey, defaultValue: 0) ?? 0;
      if (appOpens < _minAppOpens) {
        debugPrint('🎯 ReviewService: Not enough app opens ($appOpens < $_minAppOpens)');
        return false;
      }

      // Check minimum lists completed
      final listsCompleted = _box?.get(_listsCompletedKey, defaultValue: 0) ?? 0;
      if (listsCompleted < _minListsCompleted) {
        debugPrint('🎯 ReviewService: Not enough lists completed ($listsCompleted < $_minListsCompleted)');
        return false;
      }

      // Check cooldown period
      final lastPromptMillis = _box?.get(_lastPromptKey) as int?;
      if (lastPromptMillis != null) {
        final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMillis);
        final daysSinceLastPrompt = DateTime.now().difference(lastPrompt).inDays;
        if (daysSinceLastPrompt < _cooldownDays) {
          debugPrint('🎯 ReviewService: Still in cooldown ($daysSinceLastPrompt days < $_cooldownDays)');
          return false;
        }
      }

      // Check if in-app review is available
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        debugPrint('🎯 ReviewService: In-app review not available on this device');
        return false;
      }

      debugPrint('✅ ReviewService: All conditions met, should prompt for review');
      return true;
    } catch (e) {
      debugPrint('Error checking review conditions: $e');
      return false;
    }
  }

  /// Request the native in-app review dialog
  Future<void> requestReview() async {
    try {
      // Update tracking
      await _box?.put(_lastPromptKey, DateTime.now().millisecondsSinceEpoch);
      final promptCount = _box?.get(_promptCountKey, defaultValue: 0) ?? 0;
      await _box?.put(_promptCountKey, promptCount + 1);

      debugPrint('🌟 Requesting in-app review...');
      await _inAppReview.requestReview();
      
      // Mark as reviewed (assume they did after seeing the prompt)
      // Note: We can't actually know if they left a review
      await _box?.put(_hasReviewedKey, true);
      
      debugPrint('🌟 In-app review requested successfully');
    } catch (e) {
      debugPrint('Error requesting review: $e');
    }
  }

  /// Check conditions and request review if appropriate
  /// Call this after positive user actions (e.g., completing a list)
  Future<void> checkAndPromptReview() async {
    if (await shouldPromptReview()) {
      await requestReview();
    }
  }

  /// Open the app store page directly (fallback/manual option)
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: '6738698003', // Your App Store ID
      );
    } catch (e) {
      debugPrint('Error opening store listing: $e');
    }
  }

  /// Reset review tracking (for testing only)
  Future<void> resetTracking() async {
    await _box?.clear();
    debugPrint('🔄 Review tracking reset');
  }
}
