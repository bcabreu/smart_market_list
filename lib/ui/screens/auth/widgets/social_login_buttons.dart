import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(context, FontAwesomeIcons.google, isDark, () {}),
        const SizedBox(width: 16),
        _buildButton(context, FontAwesomeIcons.apple, isDark, () {}),
      ],
    );
  }

  Widget _buildButton(BuildContext context, IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Center(
          child: FaIcon(
            icon,
            size: 24,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
