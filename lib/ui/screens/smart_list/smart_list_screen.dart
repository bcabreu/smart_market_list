import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/local/shopping_list_service.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/ui/screens/smart_list/widgets/shopping_item_card.dart';
import 'package:smart_market_list/ui/screens/smart_list/widgets/smart_list_header.dart';
import 'package:smart_market_list/ui/screens/smart_list/widgets/budget_info_card.dart';
import 'package:smart_market_list/ui/screens/smart_list/modals/add_item_modal.dart';
import 'package:smart_market_list/ui/widgets/pulse_fab.dart';

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
            BudgetInfoCard(list: currentList),
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
                    
                  // Grouped Unchecked Items
                  ..._buildGroupedItems(context, uncheckedItems, service, currentList.id),
                      
                  if (checkedItems.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        children: [
                          // Left Divider
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey[800] 
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Title
                          Text(
                            'Finalizados (${checkedItems.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white 
                                  : Colors.black87,
                            ),
                          ),
                          
                          const SizedBox(width: 16),

                          // Restore Button
                          InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  backgroundColor: Theme.of(context).cardColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Icon
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F2F1), // Teal 50
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.refresh_rounded,
                                            size: 32,
                                            color: Color(0xFF009688), // Teal 500
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Title
                                        Text(
                                          'Restaurar Itens?',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.white 
                                                : Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // Message
                                        Text(
                                          'Todos os itens finalizados voltarão para a lista de compras.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.grey[400] 
                                                : Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        
                                        // Buttons
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Cancelar',
                                                  style: TextStyle(
                                                    color: Theme.of(context).brightness == Brightness.dark 
                                                        ? Colors.grey[400] 
                                                        : Colors.grey[600],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  service.restoreCompletedItems(currentList.id);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF009688), // Teal 500
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Restaurar',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2F1), // Teal 50
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFB2DFDB)), // Teal 100
                              ),
                              child: const Icon(
                                Icons.refresh,
                                size: 20,
                                color: Color(0xFF009688), // Teal 500
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Delete All Button
                          InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  backgroundColor: Theme.of(context).cardColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Icon
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFEBEE), // Red 50
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.delete_forever_rounded,
                                            size: 32,
                                            color: Color(0xFFE57373), // Red 300
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Title
                                        Text(
                                          'Limpar Concluídos?',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.white 
                                                : Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // Message
                                        Text(
                                          'Todos os itens marcados como concluídos serão removidos permanentemente.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.grey[400] 
                                                : Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        
                                        // Buttons
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Cancelar',
                                                  style: TextStyle(
                                                    color: Theme.of(context).brightness == Brightness.dark 
                                                        ? Colors.grey[400] 
                                                        : Colors.grey[600],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  service.removeCompletedItems(currentList.id);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFEF5350), // Red 400
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Limpar',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE), // Red 50
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFCDD2)), // Red 100
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Color(0xFFE57373), // Red 300
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Right Divider
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey[800] 
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...checkedItems.map((item) => Opacity(
                          opacity: 0.6,
                          child: ShoppingItemCard(
                            key: ValueKey(item.id),
                            item: item,
                            onCheckChanged: (val) {
                              final newItem = item.copyWith(
                                checked: val,
                                statusChangedAt: DateTime.now(),
                              );
                              service.updateItem(currentList.id, newItem);
                            },
                            onPriceChanged: (val) {
                              final newItem = item.copyWith(price: val);
                              service.updateItem(currentList.id, newItem);
                            },
                            onDelete: () => service.removeItem(currentList.id, item.id),
                            onEdit: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => AddItemModal(
                                  itemToEdit: item,
                                  onAdd: (updatedItem) {
                                    service.updateItem(currentList.id, updatedItem);
                                  },
                                ),
                              );
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
      floatingActionButton: PulseFloatingActionButton(
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
      ),
    );
  }

  List<Widget> _buildGroupedItems(BuildContext context, List<ShoppingItem> items, ShoppingListService service, String listId) {
    if (items.isEmpty) return [];

    final grouped = <String, List<ShoppingItem>>{};
    for (var item in items) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }

    // Sort categories (optional, maybe define a specific order)
    final sortedCategories = grouped.keys.toList()..sort();

    final widgets = <Widget>[];
    for (var category in sortedCategories) {
      widgets.add(_buildCategoryHeader(context, category));
      widgets.addAll(grouped[category]!.map((item) => ShoppingItemCard(
            key: ValueKey(item.id),
            item: item,
            onCheckChanged: (val) {
              final newItem = item.copyWith(
                checked: val,
                statusChangedAt: DateTime.now(),
              );
              service.updateItem(listId, newItem);
            },
            onPriceChanged: (val) {
              final newItem = item.copyWith(price: val);
              service.updateItem(listId, newItem);
            },
            onDelete: () => service.removeItem(listId, item.id),
            onEdit: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddItemModal(
                  itemToEdit: item,
                  onAdd: (updatedItem) {
                    service.updateItem(listId, updatedItem);
                  },
                ),
              );
            },
          )));
    }
    return widgets;
  }

  Widget _buildCategoryHeader(BuildContext context, String category) {
    final gradient = AppColors.categoryGradients[category.toLowerCase()] ?? AppColors.categoryGradients['outros']!;
    final color = gradient.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), color],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              category[0].toUpperCase() + category.substring(1),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
