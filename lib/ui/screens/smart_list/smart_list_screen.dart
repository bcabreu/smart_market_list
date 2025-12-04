import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/ui/screens/smart_list/widgets/shopping_item_card.dart';
import 'package:smart_market_list/ui/screens/smart_list/widgets/smart_list_header.dart';
import 'package:smart_market_list/ui/screens/smart_list/modals/add_item_modal.dart';

class SmartListScreen extends ConsumerWidget {
  const SmartListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentList = ref.watch(currentListProvider);
    final service = ref.watch(shoppingListServiceProvider);

    if (currentList == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final uncheckedItems = currentList.items.where((i) => !i.checked).toList();
    final checkedItems = currentList.items.where((i) => i.checked).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SmartListHeader(list: currentList),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (uncheckedItems.isEmpty && checkedItems.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text(
                          'Sua lista está vazia.\nAdicione itens para começar!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.mutedForeground),
                        ),
                      ),
                    ),
                    
                  ...uncheckedItems.map((item) => ShoppingItemCard(
                        item: item,
                        onCheckChanged: (val) {
                          final newItem = item.copyWith(checked: val);
                          service.updateItem(currentList.id, newItem);
                        },
                        onPriceChanged: (val) {
                          final newItem = item.copyWith(price: val);
                          service.updateItem(currentList.id, newItem);
                        },
                        onDelete: () => service.removeItem(currentList.id, item.id),
                        onEdit: () {
                          // TODO: Open edit modal
                        },
                      )),
                      
                  if (checkedItems.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Concluídos',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ...checkedItems.map((item) => Opacity(
                          opacity: 0.6,
                          child: ShoppingItemCard(
                            item: item,
                            onCheckChanged: (val) {
                              final newItem = item.copyWith(checked: val);
                              service.updateItem(currentList.id, newItem);
                            },
                            onPriceChanged: (val) {
                              final newItem = item.copyWith(price: val);
                              service.updateItem(currentList.id, newItem);
                            },
                            onDelete: () => service.removeItem(currentList.id, item.id),
                            onEdit: () {
                              // TODO: Open edit modal
                            },
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddItemModal(
              onAdd: (item) {
                service.addItem(currentList.id, item);
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
