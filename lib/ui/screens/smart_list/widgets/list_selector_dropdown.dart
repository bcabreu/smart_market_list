import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

class ListSelectorDropdown extends ConsumerStatefulWidget {
  final String selectedListId;
  final Function(String) onSelect;
  final Function(ShoppingList) onUpdate;
  final Function(ShoppingList) onDuplicate;
  final Function(ShoppingList) onDelete;
  final VoidCallback onDismiss;

  const ListSelectorDropdown({
    super.key,
    required this.selectedListId,
    required this.onSelect,
    required this.onUpdate,
    required this.onDuplicate,
    required this.onDelete,
    required this.onDismiss,
  });

  @override
  ConsumerState<ListSelectorDropdown> createState() => _ListSelectorDropdownState();
}

class _ListSelectorDropdownState extends ConsumerState<ListSelectorDropdown> {
  String? _editingListId;
  late TextEditingController _nameController;
  String _selectedEmoji = '🛒';

  final List<String> _emojis = [
    '🛒', '🥩', '🎄', '🎂', '🎉', '🏖️', '🍕', 
    '☕', '🥗', '🍰', '🎁', '🏠'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing(ShoppingList list) {
    setState(() {
      _editingListId = list.id;
      _nameController.text = list.name;
      _selectedEmoji = list.emoji;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingListId = null;
    });
  }

  void _confirmEditing(ShoppingList originalList) {
    if (_nameController.text.isNotEmpty) {
      final updatedList = ShoppingList(
        id: originalList.id,
        name: _nameController.text,
        emoji: _selectedEmoji,
        budget: originalList.budget,
        items: originalList.items,
        createdAt: originalList.createdAt,
      );
      widget.onUpdate(updatedList);
      setState(() {
        _editingListId = null;
      });
    }
  }

  Widget _buildEditingItem(BuildContext context, ShoppingList list) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Exact colors from image/request
    final inputBorderColor = isDark ? Colors.grey[600]! : Colors.black;
    // User requested to remove the "gray part", so we use transparent/white
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.transparent;
    
    // Button Colors
    final confirmBgColor = const Color(0xFFE0F7FA); // Light Teal
    final confirmIconColor = const Color(0xFF00BFA5); // Teal
    final cancelBgColor = const Color(0xFFF5F5F5); // Light Grey
    final cancelIconColor = Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2C4A4A) : const Color(0xFFB2EBF2).withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji Selector
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _emojis.map((emoji) {
              final isSelected = emoji == _selectedEmoji;
              return GestureDetector(
                onTap: () => setState(() => _selectedEmoji = emoji),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFFE0F7FA) // Light Teal background for selected
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? Border.all(color: const Color(0xFF00BFA5)) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Input Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: inputFillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: inputBorderColor, width: 2.0), // Thicker black border (2.0)
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false, // Ensure no background from theme
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Confirm Button
              InkWell(
                onTap: () => _confirmEditing(list),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2C2C) : confirmBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.check, color: confirmIconColor),
                ),
              ),
              const SizedBox(width: 8),

              // Cancel Button
              InkWell(
                onTap: _cancelEditing,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : cancelBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.close, color: isDark ? Colors.white : cancelIconColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(shoppingListsProvider);
    final lists = listsAsync.value ?? [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final selectedColor = isDark ? const Color(0xFF1E2C2C) : const Color(0xFFE0F7FA);
    final borderColor = isDark ? const Color(0xFF2C4A4A) : const Color(0xFFB2EBF2);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Material(
      color: Colors.transparent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: dropdownColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...lists.map((list) {
              if (list.id == _editingListId) {
                return _buildEditingItem(context, list);
              }

              final isSelected = list.id == widget.selectedListId;
              final itemCount = list.items.length;
              final total = list.totalSpent;

              return InkWell(
                onTap: () => widget.onSelect(list.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? selectedColor : Colors.transparent,
                    border: list != lists.last
                        ? Border(bottom: BorderSide(color: borderColor.withOpacity(0.5)))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Text(
                          list.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              list.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$itemCount ${AppLocalizations.of(context)!.items.toLowerCase()} • ${NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString()).format(total)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected) ...[
                        const Icon(Icons.check, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                      ],
                      Theme(
                        data: Theme.of(context).copyWith(
                          popupMenuTheme: PopupMenuThemeData(
                            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: subtitleColor, size: 20),
                          offset: const Offset(0, 50),
                          onCanceled: widget.onDismiss,
                          onSelected: (value) {
                            switch (value) {
                              case 'rename':
                                _startEditing(list);
                                break;
                              case 'duplicate':
                                widget.onDuplicate(list);
                                break;
                              case 'delete':
                                widget.onDelete(list);
                                break;
                            }
                          },
                          itemBuilder: (context) {
                            // Check Guest Status
                            final isGuest = ref.watch(isFamilyGuestProvider);
                            final defaultListId = Hive.box('settings').get('default_list_id');
                            final isDefaultList = list.id == defaultListId;
                            
                            // Permission Logic:
                            // 1. Owner can always delete (isGuest == false)
                            // 2. Family Member (Guest) can delete IF the list belongs to their family
                            // 3. Shared List User (Guest) CANNOT delete (list.familyId != user.familyId)
                            final userProfile = ref.watch(userProfileProvider).asData?.value;
                            final isFamilyList = userProfile?.familyId != null && list.familyId == userProfile?.familyId;
                            final canDelete = !isDefaultList && (!isGuest || isFamilyList);

                            return [
                              PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.of(context)!.renameList,
                                      style: const TextStyle(color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'duplicate',
                                child: Row(
                                  children: [
                                    const Icon(Icons.copy_outlined, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.of(context)!.duplicateList,
                                      style: const TextStyle(color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                              if (canDelete) 
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        AppLocalizations.of(context)!.deleteList,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                            ];
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
