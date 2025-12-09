import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/providers/sharing_provider.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';
import 'package:smart_market_list/ui/common/modals/paywall_modal.dart';

class ShareListModal extends ConsumerStatefulWidget {
  final String? familyId; // Optional: if null, we try to find it from user profile
  
  const ShareListModal({super.key, this.familyId});

  @override
  ConsumerState<ShareListModal> createState() => _ShareListModalState();
}

class _ShareListModalState extends ConsumerState<ShareListModal> {
  
  Future<void> _shareLink() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Get current user profile
    final user = await ref.read(userProfileProvider.future);
    if (user == null || user.familyId == null) return;
    
    final familyId = widget.familyId ?? user.familyId!;
    final ownerName = user.name ?? 'Seu familiar';

    try {
      // Use SharingService to generate and share the link
      await ref.read(sharingServiceProvider).shareFamilyAccess(familyId, ownerName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeMember(String familyId, String uid) async {
    final firestore = ref.read(firestoreServiceProvider);
    await firestore.removeFamilyMember(familyId, uid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Watch UserProfile to get FamilyID
    final userAsync = ref.watch(userProfileProvider);
    
    return userAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(50), 
        child: Center(child: CircularProgressIndicator())
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(24), 
        child: Text('Erro ao carregar perfil: $e')
      ),
      data: (user) {
        if (user == null || user.familyId == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Você precisa criar uma família primeiro.'),
          );
        }
        
        final familyId = user.familyId!;
        final firestore = ref.watch(firestoreServiceProvider);

        // Stream members
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: firestore.getFamilyMembers(familyId),
          builder: (context, membersSnapshot) {
             final members = membersSnapshot.data ?? [];
             
             // Filter out current user
             final otherMembers = members.where((m) => m['email'] != user.email).toList();
             final canAdd = otherMembers.isEmpty; // Limit 1 guest

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
                              'Família Premium', 
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Compartilhe acesso com 1 pessoa', 
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


                  const SizedBox(height: 32),
                  
                  // Check Plan Type
                  if (user.planType != 'premium_family') ...[
                     Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.lock_outline, size: 48, color: Colors.amber),
                          const SizedBox(height: 12),
                          Text(
                            l10n.familyPlanExclusiveFeature,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.familyPlanUpgradeDescription,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const PaywallModal(), // User can select Family tab there
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[700],
                                foregroundColor: Colors.white,
                              ),
                              child: Text(l10n.upgradeToFamily),
                            ),
                          ),
                        ],
                      ),
                     ),
                  ] else ...[ 
                    // Action Button (Share Link)
                    if (canAdd) 
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _shareLink,
                          icon: const Icon(Icons.share, color: Colors.white),
                          label: const Text('Convidar Familiar via Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.orange),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Limite de membros atingido (você + 1). Remova alguém para convidar novo membro.',
                                style: TextStyle(fontSize: 12, color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  
                  const SizedBox(height: 32),

                  // Members List
                  Text(
                    'Membros da Família',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (otherMembers.isEmpty)
                     const Padding(
                       padding: EdgeInsets.symmetric(vertical: 8.0),
                       child: Text('Nenhum membro convidado ainda.', style: TextStyle(color: Colors.grey)),
                     ),

                  ...otherMembers.map((member) {
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
                                  member['name'] ?? 'Familiar',
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
                          if (uid != null)
                            IconButton(
                              onPressed: () => _removeMember(familyId, uid), 
                              icon: const Icon(Icons.close, size: 18),
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                        ],
                      ),
                    );
                  }).toList(),

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
