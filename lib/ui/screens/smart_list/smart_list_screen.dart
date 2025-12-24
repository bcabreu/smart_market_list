import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/local/shopping_list_service.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:smart_market_list/ui/screens/smart_list/widgets/shopping_item_card.dart';
import 'package:smart_market_list/ui/screens/smart_list/widgets/smart_list_header.dart';
import 'package:smart_market_list/ui/screens/smart_list/widgets/budget_info_card.dart';
import 'package:smart_market_list/ui/screens/smart_list/modals/add_item_modal.dart';
import 'package:smart_market_list/ui/widgets/pulse_fab.dart';
import 'package:smart_market_list/ui/common/animations/staggered_entry.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/providers/user_provider.dart';

class SmartListScreen extends ConsumerWidget {
  const SmartListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentList = ref.watch(currentListProvider);
    final service = ref.watch(shoppingListServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    
    // Activate Sync Manager
    ref.watch(syncManagerProvider);

    // If we have a list, show it. If not, check if we need to show Empty State or Loading.
    if (currentList == null) {
      final listsAsync = ref.watch(shoppingListsProvider);
      
      return listsAsync.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => Scaffold(body: Center(child: Text('Erro: $e'))),
        data: (lists) {
          if (lists.isEmpty) {
             // Check Profile State to avoid Race Condition
             final userProfileAsync = ref.watch(userProfileProvider);
             
             return userProfileAsync.when(
               data: (profile) {
                 final isPremium = profile?.isPremium ?? false;
                               // LISTS EMPTY: Auto-create immediately... BUT WAIT FOR SYNC if applicable!
                  // This prevents creating a duplicate if cloud lists are still loading.
                  
                  final isSynced = ref.watch(initialListSyncProvider).value ?? false;
                  final userProfile = ref.read(userProfileProvider).value;
                  final shouldWaitForSync = userProfile?.familyId != null && !isSynced;

                  if (shouldWaitForSync) {
                     return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }

                   // Check if we already have a default list ID saved
                   // This prevents creating duplicates during hot restart when Hive data hasn't fully loaded yet
                   final settingsBox = Hive.isBoxOpen('settings') ? Hive.box('settings') : null;
                   final existingDefaultId = settingsBox?.get('default_list_id');
                   
                   if (existingDefaultId != null) {
                      // A default list was previously created, wait for it to load from Hive
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                   }

                   Future.microtask(() async {
                      // Double-check if settings box is open and no default exists
                      if (Hive.isBoxOpen('settings')) {
                        final settings = Hive.box('settings');
                        if (settings.get('default_list_id') != null) {
                          return; // Default already exists, don't create another
                        }
                      }
                      
                      final newList = ShoppingList(
                         name: 'Compras do Mês',
                         emoji: '🛒',
                         budget: 500.0
                      );
                      await service.createList(newList);
                      // Set as default list
                      if (Hive.isBoxOpen('settings')) {
                         await Hive.box('settings').put('default_list_id', newList.id);
                      }
                   });
                   return const Scaffold(body: Center(child: CircularProgressIndicator()));
                },
                loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
                error: (_, __) => const Scaffold(body: Center(child: CircularProgressIndicator())), 
              );


          }
          // Lists exist but current is null (loading specific list?)
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
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
              child: (uncheckedItems.isEmpty && checkedItems.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.emptyListTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.emptyListSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
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
                                  '${l10n.completedItems} (${checkedItems.length})',
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
                                                l10n.restoreItemsTitle,
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
                                                l10n.restoreItemsMessage,
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
                                                        l10n.cancel,
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
                                                      child: Text(
                                                        l10n.restore,
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                                                l10n.clearCompletedTitle,
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
                                                l10n.clearCompletedMessage,
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
                                                        l10n.cancel,
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
                                                      child: Text(
                                                        l10n.clear,
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                                  onQuantityChanged: (val) {
                                    final newItem = item.copyWith(
                                      unitQuantity: val,
                                      quantity: '$val un',
                                    );
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
    int index = 0;
    
    for (var category in sortedCategories) {
      widgets.add(_buildCategoryHeader(context, category));
      
      final categoryItems = grouped[category]!;
      categoryItems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      for (var item in categoryItems) {
        widgets.add(StaggeredEntry(
          index: index++,
          child: ShoppingItemCard(
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
            onQuantityChanged: (val) {
              final newItem = item.copyWith(
                unitQuantity: val,
                quantity: '$val un',
              );
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
          ),
        ));
      }
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
              _getLocalizedCategoryName(context, category),
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

  String _getLocalizedCategoryName(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category.toLowerCase()) {
      case 'hortifruti': return l10n.cat_hortifruti;
      case 'padaria': return l10n.cat_padaria;
      case 'laticinios': return l10n.cat_laticinios;
      case 'acougue': return l10n.cat_acougue;
      case 'mercearia': return l10n.cat_mercearia;
      case 'bebidas': return l10n.cat_bebidas;
      case 'limpeza': return l10n.cat_limpeza;
      case 'higiene': return l10n.cat_higiene;
      case 'congelados': return l10n.cat_congelados;
      case 'doces': return l10n.cat_doces;
      case 'pet': return l10n.cat_pet;
      case 'bebe': return l10n.cat_bebe;
      case 'utilidades': return l10n.cat_utilidades;
      case 'utilidades': return l10n.cat_utilidades;
      case 'outros': return l10n.cat_outros;
      default: 
        // If it's a custom category, capitalize it
        if (category.isEmpty) return l10n.cat_outros;
        return category[0].toUpperCase() + category.substring(1);
    }
  }
}
