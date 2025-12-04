import 'package:flutter/material.dart';

class AppColors {
  // Light Mode
  static const Color primary = Color(0xFF4ECDC4); // Verde Menta
  static const Color primaryLight = Color(0xFF7FE0D9);
  static const Color primaryDark = Color(0xFF3BAEA5);
  static const Color secondary = Color(0xFFFF6B35); // Laranja Vibrante
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF1A1A1A);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFF5F5F5);
  static const Color mutedForeground = Color(0xFF737373);
  static const Color border = Color(0x1A000000); // rgba(0,0,0,0.1)
  static const Color inputBackground = Color(0xFFF8F8F8);

  // Dark Mode
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkForeground = Color(0xFFF5F5F5);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkMuted = Color(0xFF2A2A2A);
  static const Color darkMutedForeground = Color(0xFFA3A3A3);
  static const Color darkBorder = Color(0x1AFFFFFF); // rgba(255,255,255,0.1)
  static const Color darkInputBackground = Color(0xFF2A2A2A);

  // Budget States
  static const Color budgetSafe = Color(0xFF4ECDC4); // < 60%
  static const Color budgetWarning = Color(0xFFFFB627); // 60-85%
  static const Color budgetDanger = Color(0xFFFF6B35); // > 85%

  // Category Gradients
  static const Map<String, List<Color>> categoryGradients = {
    'hortifruti': [Color(0xFF4ADE80), Color(0xFF10B981)],
    'padaria': [Color(0xFFFBBF24), Color(0xFFF97316)],
    'laticinios': [Color(0xFF60A5FA), Color(0xFF06B6D4)],
    'outros': [Color(0xFFA78BFA), Color(0xFFEC4899)],
    'custom': [Color(0xFF818CF8), Color(0xFF8B5CF6)],
  };
}
