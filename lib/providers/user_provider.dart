import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple state provider for premium status (simulated)
final isPremiumProvider = StateProvider<bool>((ref) => false);

// User name provider
final userNameProvider = StateProvider<String?>((ref) => null);
