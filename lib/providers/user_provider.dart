import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/providers/subscription_provider.dart';

// Premium Status & Date Notifier
class PremiumNotifier extends StateNotifier<DateTime?> {
  PremiumNotifier() : super(null) {
    _loadStatus();
  }

  static const _keyDate = 'premium_since';

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_keyDate);
    if (dateStr != null) {
      state = DateTime.parse(dateStr);
    }
  }

  Future<void> setPremium(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    if (isPremium) {
      // Only set date if not already set (preserve original subscription date)
      if (state == null) {
        final now = DateTime.now();
        state = now;
        await prefs.setString(_keyDate, now.toIso8601String());
      }
    } else {
      state = null;
      await prefs.remove(_keyDate);
    }
  }
}

final premiumSinceProvider = StateNotifierProvider<PremiumNotifier, DateTime?>((ref) {
  return PremiumNotifier();
});

// Derived provider for boolean check (backward compatibility + RevenueCat)
final isPremiumProvider = Provider<bool>((ref) {
  // 1. Check RevenueCat Status (Real Source of Truth)
  final subscriptionActive = ref.watch(subscriptionStatusProvider);
  
  // 2. Fallback to Legacy/Local (if migrating or manual override)
  final localPremium = ref.watch(premiumSinceProvider) != null;
  final cloudProfile = ref.watch(userProfileProvider).asData?.value;
  
  return subscriptionActive || localPremium || (cloudProfile?.isPremium ?? false);
});

class UserNameNotifier extends StateNotifier<String?> {
  UserNameNotifier() : super(null) {
    _loadName();
  }

  static const _key = 'user_name';

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> setName(String name) async {
    state = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, name);
  }

  Future<void> clearName() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// User email provider
final userEmailProvider = StateNotifierProvider<UserEmailNotifier, String?>((ref) {
  return UserEmailNotifier();
});

class UserEmailNotifier extends StateNotifier<String?> {
  UserEmailNotifier() : super(null) {
    _loadEmail();
  }

  static const _key = 'user_email';

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> setEmail(String email) async {
    state = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, email);
  }

  Future<void> clearEmail() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// User name provider
final userNameProvider = StateNotifierProvider<UserNameNotifier, String?>((ref) {
  return UserNameNotifier();
});

// Auth status provider using StateNotifier for persistence
final isLoggedInProvider = StateNotifierProvider<IsLoggedInNotifier, bool>((ref) {
  return IsLoggedInNotifier();
});

class IsLoggedInNotifier extends StateNotifier<bool> {
  IsLoggedInNotifier() : super(false) {
    _loadStatus();
  }

  static const _key = 'is_logged_in';

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
