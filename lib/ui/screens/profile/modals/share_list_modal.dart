import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/providers/shared_users_provider.dart';

class ShareListModal extends ConsumerStatefulWidget {
  const ShareListModal({super.key});

  @override
  ConsumerState<ShareListModal> createState() => _ShareListModalState();
}

class _ShareListModalState extends ConsumerState<ShareListModal> {
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    
    // Get current list ID
    final currentList = ref.read(currentListProvider);
    if (currentList == null) return;
    
    // Get shared users from provider
    final sharedUsers = ref.read(sharedUsersProvider)[currentList.id] ?? [];
    
    if (email.isNotEmpty && email.contains('@')) {
      if (sharedUsers.isNotEmpty) { 
         // Limit to 1 person
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.shareLimitError)),
         );
         return;
      }
      
      // Update persistent state
      await ref.read(sharedUsersProvider.notifier).addUser(currentList.id, email);
      _emailController.clear();
      
      // Open system share dialog
      await Share.share(l10n.shareInviteMessage);
    }
  }

  void _removeUser(String email) {
    final currentList = ref.read(currentListProvider);
    if (currentList == null) return;
    
    ref.read(sharedUsersProvider.notifier).removeUser(currentList.id, email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final currentList = ref.watch(currentListProvider);
    final sharedUsers = currentList != null 
        ? (ref.watch(sharedUsersProvider)[currentList.id] ?? []) 
        : <String>[];
        
    final canAdd = sharedUsers.isEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
               Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people_outline_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.shareList,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.shareListSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Email Input Section
          Text(
            l10n.shareEmailLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  enabled: canAdd,
                  decoration: InputDecoration(
                    hintText: canAdd ? l10n.emailHint : l10n.shareLimitReached,
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: canAdd ? const Color(0xFF4DB6AC) : Colors.grey, // Teal like image
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: canAdd ? _addUser : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Sharing With Section
          if (sharedUsers.isNotEmpty) ...[
            Text(
              l10n.sharingWithLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4DB6AC), // Teal
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sharedUsers.first,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeUser(sharedUsers.first),
                    icon: const Icon(Icons.close, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEBEE), // Light red
                      foregroundColor: const Color(0xFFEF5350), // Red icon
                      padding: const EdgeInsets.all(8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Info Footer
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1), // Light Teal
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFB2DFDB)),
            ),
            child: Text(
              l10n.shareRealTimeInfo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF00796B), // Dark Teal text
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
