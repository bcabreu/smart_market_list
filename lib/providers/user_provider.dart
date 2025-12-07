import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple state provider for premium status (simulated)
final isPremiumProvider = StateProvider<bool>((ref) => false);

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
