import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the active tab index of the BottomNavigationBar in MainScreen
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
