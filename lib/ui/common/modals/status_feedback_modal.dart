import 'package:flutter/material.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';

enum FeedbackType { success, error, info, warning }

class StatusFeedbackModal {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    FeedbackType type = FeedbackType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    // Dismiss existing SnackBars
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Define colors and icons based on type
    Color backgroundColor;
    Color iconColor;
    IconData icon;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color subtitleColor = isDark ? Colors.white70 : Colors.black54;

    switch (type) {
      case FeedbackType.success:
        backgroundColor = isDark ? const Color(0xFF1E2C2C) : const Color(0xFFE0F7FA);
        iconColor = const Color(0xFF00BFA5); // Teal
        icon = Icons.check_circle_outline;
        break;
      case FeedbackType.error:
        backgroundColor = isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFEBEE);
        iconColor = const Color(0xFFEF5350); // Red
        icon = Icons.error_outline;
        break;
      case FeedbackType.warning:
        backgroundColor = isDark ? const Color(0xFF2C2515) : const Color(0xFFFFF8E1);
        iconColor = const Color(0xFFFFA000); // Amber
        icon = Icons.warning_amber_rounded;
        break;
      case FeedbackType.info:
      default:
        backgroundColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFE3F2FD);
        iconColor = AppColors.primary;
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: iconColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Close/Forward Icon
                if (onTap != null)
                   Icon(Icons.arrow_forward_ios, color: subtitleColor, size: 16)
                else
                   InkWell(
                     onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                     child: Icon(Icons.close, color: subtitleColor, size: 20),
                   )
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating, // Floating behavior
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        duration: duration,
      ),
    );
  }
}
