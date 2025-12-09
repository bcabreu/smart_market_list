import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/ui/screens/smart_list/modals/edit_list_modal.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/ui/screens/smart_list/widgets/list_selector_dropdown.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/ui/common/modals/paywall_modal.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_market_list/providers/sharing_provider.dart';



class SmartListHeader extends ConsumerStatefulWidget {
  final ShoppingList list;

  const SmartListHeader({super.key, required this.list});

  @override
  ConsumerState<SmartListHeader> createState() => _SmartListHeaderState();
}

class _SmartListHeaderState extends ConsumerState<SmartListHeader> {
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  bool _hideHeader = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _duplicateList(ShoppingList list) {
    final service = ref.read(shoppingListServiceProvider);
    final newList = ShoppingList(
      id: const Uuid().v4(),
      name: '${list.name}${AppLocalizations.of(context)!.copySuffix}',
      emoji: list.emoji,
      budget: list.budget,
      items: list.items.map((i) => i.copyWith(id: const Uuid().v4())).toList(),
      createdAt: DateTime.now(),
    );
    service.createList(newList);
  }

  void _deleteList(ShoppingList list) {
    // Prevent deleting the last list or the currently selected one if it's the only one
    // But for now, just delete. If current list is deleted, provider should handle or we switch.
    final service = ref.read(shoppingListServiceProvider);
    service.deleteList(list.id);
    
    // If we deleted the current list, switch to another one or create a default one
    if (widget.list.id == list.id) {
       // Logic to switch list is handled by the parent or provider usually, 
       // but here we might need to ensure we don't show a deleted list.
       // The stream builder in SmartListScreen will update.
    }
  }

  Future<void> _openDropdown() async {
    final lists = ref.read(shoppingListsProvider).value ?? [];
    
    setState(() {
      _isOpen = true;
      _hideHeader = true;
    });

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Stack(
            children: [
              // Dropdown content (Behind Header Copy)
              Positioned(
                width: MediaQuery.of(context).size.width - 32,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: const Offset(16, 96), // 16px left margin, 96px top (16 margin + 72 height + 8 gap)
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: ListSelectorDropdown(
                        selectedListId: widget.list.id,
                        onSelect: (id) {
                          ref.read(currentListIdProvider.notifier).state = id;
                          Navigator.of(context).pop();
                        },
                        onUpdate: (updatedList) {
                          final service = ref.read(shoppingListServiceProvider);
                          service.updateList(updatedList);
                        },
                        onDuplicate: (list) {
                          _duplicateList(list);
                        },
                        onDelete: (list) {
                          _deleteList(list);
                        },
                        onDismiss: _closeDropdown,
                      ),
                    ),
                  ),
                ),
              ),

              // Header Copy (On Top)
              Positioned(
                width: MediaQuery.of(context).size.width - 32,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: const Offset(16, 16), // Match the original header's margin position
                  child: _buildHeaderVisual(context, ref, forceOpen: true),
                ),
              ),
            ],
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child; // Animations are handled inside pageBuilder for specific elements
        },
      ),
    );

    if (mounted) {
      setState(() {
        _isOpen = false;
        _hideHeader = false;
      });
    }
  }

  void _closeDropdown() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildHeaderVisual(BuildContext context, WidgetRef ref, {bool forceOpen = false}) {
    final uncheckedCount = widget.list.items.where((i) => !i.checked).length;
    final percentage = widget.list.percentage / 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cardColor = isDark 
        ? const Color(0xFF1E2C2C)
        : const Color(0xFFE0F7FA).withOpacity(0.5);
    final borderColor = isDark
        ? const Color(0xFF2C4A4A)
        : const Color(0xFFB2EBF2);
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Container(
      height: 72, // Fixed height for consistency
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleDropdown,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  widget.list.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.list.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.itemsRemaining(uncheckedCount),
                            style: TextStyle(fontSize: 12, color: subtitleColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: percentage),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          final isOverBudget = value > 1.0;
                          final color = isOverBudget ? const Color(0xFFEF5350) : AppColors.primary; // Red 400 or Primary
                          
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: 1,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? Colors.grey[800]! : Colors.grey[200]!
                                ),
                                strokeWidth: 4,
                              ),
                              CircularProgressIndicator(
                                value: value.clamp(0.0, 1.0),
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                strokeWidth: 4,
                              ),
                              Text(
                                '${(value * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        if (_isOpen) _closeDropdown();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const EditListModal(),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: AppColors.primary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: (forceOpen || _isOpen) ? 0.5 : 0,
                      child: Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 8), // Gap
                    InkWell(
                      onTap: () {
                         final isPremium = ref.read(userProfileProvider).value?.isPremium ?? false;
                         
                         if (!isPremium) {
                           showModalBottomSheet(
                             context: context,
                             isScrollControlled: true,
                             backgroundColor: Colors.transparent,
                             builder: (context) => const PaywallModal(),
                           );
                         } else {
                           // Share logic (Premium Access)
                           final sharingService = ref.read(sharingServiceProvider);
                           final profile = ref.read(userProfileProvider).value;
                           final familyIdToUse = widget.list.familyId ?? profile?.familyId;
                           
                           if (familyIdToUse != null) {
                              sharingService.shareList(widget.list, familyIdToUse);
                           } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erro: Lista não sincronizada ou família não encontrada.')),
                              );
                           }
                         }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                           color: isDark ? Colors.grey[800] : Colors.white.withOpacity(0.5),
                           shape: BoxShape.circle,
                           border: Border.all(color: borderColor),
                        ),
                        child: Icon(Icons.share, color: iconColor, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Opacity(
          opacity: _hideHeader ? 0.0 : 1.0,
          child: _buildHeaderVisual(context, ref),
        ),
      ),
    );
  }
}
