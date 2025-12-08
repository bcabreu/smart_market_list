import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart'; // Keep if we want to send a link eventually, but for now we just invite
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/core/services/family_invitation_service.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/ui/common/modals/loading_dialog.dart';
import 'package:smart_market_list/ui/common/modals/status_feedback_modal.dart';
import 'package:smart_market_list/ui/screens/profile/modals/widgets/invitation_tile.dart';

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

  Future<void> _sendInvite() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    
    if (email.isEmpty || !email.contains('@')) {
       // Simple validation
       return;
    }

    try {
      LoadingDialog.show(context, l10n.processing);
      
      final service = ref.read(familyInvitationServiceProvider);
      
      // Add timeout to prevent infinite loading
      await service.inviteMember(email).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet.');
        },
      );
      
      if (mounted) {
        LoadingDialog.hide(context);
        _emailController.clear();
        
        StatusFeedbackModal.show(
          context,
          title: l10n.inviteSentTitle,
          message: l10n.inviteSentMessage,
          type: FeedbackType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        // Ensure dialog is closed if still open
        // We can't easily check if it's open, but if we are here, we probably need to close it 
        // IF it was opened by us. 
        // LoadingDialog.hide pops the navigator. If we pop too much we might close the modal.
        // But since we awaited show, we should be fine.
        LoadingDialog.hide(context);
        
        StatusFeedbackModal.show(
          context,
          title: l10n.errorTitle,
          message: e.toString().replaceAll('Exception: ', ''),
          type: FeedbackType.error,
        );
      }
    }
  }

  Future<void> _removeMember(String uid) async {
    final service = ref.read(familyInvitationServiceProvider);
    await service.removeMember(uid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Watch Family Members
    final invitationService = ref.watch(familyInvitationServiceProvider);
    final membersStream = invitationService.getFamilyMembers();
    final invitationsStream = invitationService.getSentInvitations(); // New stream

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: membersStream,
      builder: (context, membersSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: invitationsStream,
          builder: (context, invitationsSnapshot) {
            final members = membersSnapshot.data ?? [];
            final invitations = invitationsSnapshot.data ?? [];
            final currentUser = ref.watch(currentUserProvider);
            
            // Filter out current user from display to only show WHO we are sharing with
            final otherMembers = members.where((m) => m['email'] != currentUser?.email).toList();
            
            // Allow add ONLY if no members AND no pending invitations
            final canAdd = otherMembers.isEmpty && invitations.isEmpty; 


        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
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
                          l10n.shareList, // Using existing title "Compartilhar Lista"
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

              // Email Input Section (Only if canAdd)
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
                        hintText: canAdd ? l10n.memberEmailHint : l10n.shareLimitReached, // repurposed keys
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
                    color: canAdd ? const Color(0xFF4DB6AC) : Colors.grey, 
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: canAdd ? _sendInvite : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.send_rounded, // Changed to Send icon for invite
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Sharing With Section
              if (otherMembers.isNotEmpty || invitations.isNotEmpty) ...[
                Text(
                  l10n.sharingWithLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Pending Invitations
                ...invitations.map((invite) {
                  final email = invite['toEmail'] as String;
                  final inviteId = invite['id'] as String;
                  
                  return InvitationTile(
                    email: email,
                    isDark: isDark,
                    onCancel: () {
                      final service = ref.read(familyInvitationServiceProvider);
                      service.cancelInvitation(inviteId);
                    },
                  );
                }),
                
                const SizedBox(height: 8), 
                
                // Active Members
                ...otherMembers.map((member) {
                  // We need the UID to remove. The member map depends on Firestore structure.
                  // Wait, getFamilyMembers returns user docs. we don't have the UID inside the doc usually unless we added it.
                  // FirestoreService.getFamilyMembers assumes adding entire data() which doesn't include ID by default.
                  // I should probably fix that in FirestoreService or assume we can't remove easily without ID.
                  // Wait, inviteMember/removeMember logic... 
                  // Let's assume for now we can't fully remove without ID. 
                  // Actually, let's fix FirestoreService return type or use email to remove?
                  // removeFamilyMember takes 'memberUid'.
                  // I need to ensure the member map includes 'uid' or I can find it.
                  // Ah, in FirestoreService I used `snapshot.data()` which is Map.
                  // I should add ID to it.
                  
                  final email = member['email'] ?? 'Unknown';
                  final uid = member['uid']; 
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
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
                          alignment: Alignment.center,
                          child: Text(
                             email.substring(0, 1).toUpperCase(),
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name'] ?? 'Family Member',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600]
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Only Owner can remove
                        if (uid != null)
                          IconButton(
                            onPressed: () => _removeMember(uid), 
                            icon: const Icon(Icons.close, size: 18),
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  );
                }).toList(),
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
                  l10n.inviteSentMessage, // Reusing "The invited person must log in..."
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
    );
      }
    );
  }
}
