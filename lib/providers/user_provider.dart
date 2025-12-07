import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// Derived provider for boolean check (backward compatibility)
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(premiumSinceProvider) != null;
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
}

// User name provider
final userNameProvider = StateNotifierProvider<UserNameNotifier, String?>((ref) {
  return UserNameNotifier();
});

// Auth status provider
final isLoggedInProvider = StateProvider<bool>((ref) => false);
