import 'package:flutter/material.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';

enum FeedbackType { success, error, info }

class StatusFeedbackModal extends StatelessWidget {
  final String title;
  final String message;
  final FeedbackType type;
  final VoidCallback? onDismiss;

  const StatusFeedbackModal({
    super.key,
    required this.title,
    required this.message,
    this.type = FeedbackType.info,
    this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    FeedbackType type = FeedbackType.info,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      builder: (context) => StatusFeedbackModal(
        title: title,
        message: message,
        type: type,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    IconData icon;

    switch (type) {
      case FeedbackType.success:
        iconColor = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case FeedbackType.error:
        iconColor = Colors.red;
        icon = Icons.error_outline;
        break;
      case FeedbackType.info:
      default:
        iconColor = AppColors.primary;
        icon = Icons.info_outline;
        break;
    }

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
