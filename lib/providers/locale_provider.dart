import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    
    if (languageCode != null) {
      if (languageCode == 'system') {
        state = null; // System default
      } else {
        state = Locale(languageCode);
      }
    } else {
      state = null; // Default to system if not set
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.setString('language_code', 'system');
    } else {
      await prefs.setString('language_code', locale.languageCode);
    }
  }

  // Returns the active locale (either manual or system)
  Locale getActiveLocale() {
    if (state != null) return state!;
    // Fallback logic if needed, but usually we pass null to MaterialApp for system
    return ui.window.locale;
  }
}
