import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/data/models/user_profile.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/core/services/ad_service.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:uuid/uuid.dart';

class EditListModal extends ConsumerStatefulWidget {
  final ShoppingList? list; // If null, create new list

  const EditListModal({super.key, this.list});

  @override
  ConsumerState<EditListModal> createState() => _EditListModalState();
}

class _EditListModalState extends ConsumerState<EditListModal> {
  final _nameController = TextEditingController();
  String _selectedEmoji = '🛒';

  final List<String> _emojis = [
    '🛒', '🥩', '🎄', '🎂', '🎉', '🏖️', '🍕', 
    '☕', '🥗', '🍰', '🎁', '🏠'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.list != null) {
      _nameController.text = widget.list!.name;
      _selectedEmoji = widget.list!.emoji;
    }
    
    // Pre-load interstitial ad if creating new list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.list == null) {
        final userProfile = ref.read(userProfileProvider).value;
        if (userProfile == null || (userProfile.planType != 'premium_individual' && userProfile.planType != 'premium_family')) {
           AdService.instance.loadInterstitial();
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isNotEmpty) {
      final name = _nameController.text;
      final service = ref.read(shoppingListServiceProvider);

      try {
        if (widget.list != null) {
          // Update
          final updatedList = ShoppingList(
            id: widget.list!.id,
            name: name,
            emoji: _selectedEmoji,
            budget: widget.list!.budget, // Keep existing budget
            items: widget.list!.items,
            createdAt: widget.list!.createdAt,
          );
          await service.updateList(updatedList);
        } else {
          // Create
          final userProfile = ref.read(userProfileProvider).value;
          final isPremium = userProfile != null && userProfile.isPremium;
          
          Future<void> createListAction() async {
            final newList = ShoppingList(
              id: const Uuid().v4(),
              name: name,
              emoji: _selectedEmoji,
              budget: 0.0, // Default to 0
              items: [],
              createdAt: DateTime.now(),
            );
            await service.createList(newList);
            // Auto-select the new list
            ref.read(currentListIdProvider.notifier).state = newList.id;
          }

          if (!isPremium) {
            AdService.instance.showInterstitialAd(
              onAdDismissed: () async {
                await createListAction();
                if (mounted) Navigator.pop(context);
              },
            );
            return; 
          } else {
             await createListAction();
          }
        }
        
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error saving list: $e');
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erro ao salvar: $e')),
           );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.list != null 
                        ? AppLocalizations.of(context)!.editList
                        : AppLocalizations.of(context)!.newList,
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.createPersonalizedList,
                      style: TextStyle(
                        fontSize: 14, 
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 20, color: subtitleColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Emoji Selector
            Text(
              AppLocalizations.of(context)!.chooseEmoji,
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _emojis.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary.withOpacity(0.15) 
                          : (isDark ? Colors.grey[800] : const Color(0xFFF5F5F5)),
                      borderRadius: BorderRadius.circular(16), // Rounded square/squircle
                      border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
  
            // Name Input
            Row(
              children: [
                Icon(Icons.list, size: 20, color: subtitleColor),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.listName,
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.transparent), // Placeholder for focus border if needed
              ),
              child: TextField(
                controller: _nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.listNameHint,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
  
            // Create Button
            SizedBox(
              width: double.infinity,
              height: 80, // Large button
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    // Plus Icon Circle
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    
                    // Text
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.list != null 
                                ? AppLocalizations.of(context)!.saveChanges 
                                : AppLocalizations.of(context)!.createListButton,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.list != null 
                                ? AppLocalizations.of(context)!.updateDetails 
                                : AppLocalizations.of(context)!.startPlanning,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
  
                    // Arrow Icon
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
