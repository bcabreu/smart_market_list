import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/providers/profile_provider.dart';
import 'package:smart_market_list/providers/user_provider.dart';

import 'package:smart_market_list/l10n/generated/app_localizations.dart';

class ProfileSummary extends ConsumerWidget {
  const ProfileSummary({super.key});

  Future<void> _pickImage(BuildContext context, WidgetRef ref, ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        ref.read(profileImageProvider.notifier).setImage(pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.imageError(e.toString()))),
      );
    }
  }

  void _showImageSourceActionSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.changePhoto,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.camera_alt,
                  label: l10n.camera,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(context, ref, ImageSource.camera);
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.photo_library,
                  label: l10n.gallery,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(context, ref, ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = ref.watch(userNameProvider);
    final profileImagePath = ref.watch(profileImageProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: isDark 
            ? Border.all(color: Colors.white.withOpacity(0.1), width: 1)
            : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        children: [
          // Avatar Stack
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  border: Border.all(
                    color: const Color(0xFFE0F2F1), // Light Teal outline
                    width: 4,
                  ),
                  image: profileImagePath != null
                      ? DecorationImage(
                          image: FileImage(File(profileImagePath)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profileImagePath == null
                    ? Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 64,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      )
                    : null,
              ),
              if (isPremium)
                Positioned(
                  top: -12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8F00), // Orange/Gold
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.crown,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              // Edit Photo Button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showImageSourceActionSheet(context, ref),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).cardColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit, // Pencil icon
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Name
          Text(
            userName ?? AppLocalizations.of(context)!.guest,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Status Row (Only for Premium)
          if (isPremium)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.clientSince} Nov 2024',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8F00), // Orange
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.crown, color: Colors.white, size: 12),
                      SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.premiumLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

