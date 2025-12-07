import 'package:flutter/material.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';

class SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark 
            ? Border.all(color: Colors.white.withOpacity(0.1), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLocked;
  final Color? textColor;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isLocked = false,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary),
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLocked) const Icon(Icons.lock, size: 16, color: AppColors.mutedForeground),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ] else
            const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
        ],
      ),
      onTap: onTap,
    );
  }
}
