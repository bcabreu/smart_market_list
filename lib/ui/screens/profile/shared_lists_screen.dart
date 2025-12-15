import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/core/services/firestore_service.dart';

class SharedListsScreen extends ConsumerWidget {
  const SharedListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listsAsync = ref.watch(shoppingListsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get Family Info
    final userAsync = ref.watch(userProfileProvider);


    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.sharingListsStats.replaceAll('\n', ' '), 
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return _buildEmptyState(l10n);

          return listsAsync.when(
            data: (lists) {
              final sharedLists = lists.where((list) {
                final hasGuests = list.members.any((m) => m != list.ownerId);
                final amIGuest = list.ownerId != null && list.ownerId != user.uid;
                return hasGuests || amIGuest;
              }).toList();

              if (sharedLists.isEmpty) return _buildEmptyState(l10n);

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sharedLists.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final list = sharedLists[index];
                  // Display explicit list members
                  final displayMembers = list.members; 

                  return Card(
                    elevation: 0,
                    color: isDark ? AppColors.darkCard : AppColors.cardBackground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                list.emoji ?? '🛒',
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  list.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${displayMembers.length} membros',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            l10n.sharingWithLabel, 
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // List members 
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: displayMembers.map((memberId) {
                               return _MemberChip(
                                 memberId: memberId,
                                 isMe: memberId == user.uid,
                               );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _buildEmptyState(l10n),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildEmptyState(l10n),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.mutedForeground),
          const SizedBox(height: 16),
          Text(
            l10n.noLists, 
            style: const TextStyle(color: AppColors.mutedForeground, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _MemberChip extends ConsumerWidget {
  final String memberId;
  final bool isMe;

  const _MemberChip({required this.memberId, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMe) {
      return Chip(
         avatar: const CircleAvatar(
           backgroundColor: AppColors.inputBackground, 
           child: Icon(Icons.person, size: 14, color: AppColors.mutedForeground),
         ),
         label: Text(
           AppLocalizations.of(context)!.me, 
           style: const TextStyle(fontSize: 12),
         ),
         backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkInputBackground : AppColors.inputBackground,
         side: BorderSide.none,
       );
    }

    final firestore = ref.watch(firestoreServiceProvider);

    return FutureBuilder<Map<String, dynamic>?>(
      future: firestore.getUserData(memberId),
      builder: (context, snapshot) {
        String label = memberId; // Fallback
        
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          // Try Name -> Email -> ID
          label = data['name'] as String? ?? data['email'] as String? ?? memberId;
        }

        return Chip(
           avatar: const CircleAvatar(
             backgroundColor: AppColors.inputBackground, 
             child: Icon(Icons.person, size: 14, color: AppColors.mutedForeground),
           ),
           label: Text(
             label, 
             style: const TextStyle(fontSize: 12),
             overflow: TextOverflow.ellipsis,
           ),
           backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkInputBackground : AppColors.inputBackground,
           side: BorderSide.none,
         );
      },
    );
  }
}
