import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/ui/screens/smart_list/modals/edit_list_modal.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';

class SmartListHeader extends ConsumerWidget {
  final ShoppingList list;

  const SmartListHeader({super.key, required this.list});

  Color _getBudgetColor(double percentage) {
    if (percentage < 60) return AppColors.budgetSafe;
    if (percentage < 85) return AppColors.budgetWarning;
    return AppColors.budgetDanger;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = list.percentage;
    final budgetColor = _getBudgetColor(percentage);
    final listsAsync = ref.watch(shoppingListsProvider);
    final currentListId = ref.watch(currentListIdProvider);
    final service = ref.read(shoppingListServiceProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // List Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: listsAsync.when(
                  data: (lists) {
                    if (lists.isEmpty) return const SizedBox();
                    return PopupMenuButton<String>(
                      initialValue: list.id,
                      onSelected: (id) {
                        if (id == 'new') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const EditListModal(),
                          );
                        } else {
                          ref.read(currentListIdProvider.notifier).state = id;
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              list.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lista Atual',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        list.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      itemBuilder: (context) => [
                        ...lists.map((l) => PopupMenuItem(
                          value: l.id,
                          child: Row(
                            children: [
                              Text(l.emoji),
                              const SizedBox(width: 8),
                              Text(l.name),
                              if (l.id == list.id) ...[
                                const Spacer(),
                                const Icon(Icons.check, color: AppColors.primary, size: 16),
                              ],
                            ],
                          ),
                        )),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'new',
                          child: Row(
                            children: [
                              Icon(Icons.add, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Nova Lista', style: TextStyle(color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => EditListModal(list: list),
                  );
                },
              ),
              // Percentage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: budgetColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(
                    color: budgetColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Budget Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orçamento',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      // TODO: Edit budget
                    },
                    child: Text(
                      'R\$ ${list.budget.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Gasto',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'R\$ ${list.totalSpent.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: budgetColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.muted,
              valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
