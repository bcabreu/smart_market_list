import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/models/shopping_item.dart';
import 'data/models/shopping_list.dart';
import 'data/models/shopping_note.dart';
import 'data/models/recipe.dart';
import 'providers/theme_provider.dart';
import 'ui/screens/main_screen.dart';

void main() async {
  await Hive.initFlutter();
  
  Hive.registerAdapter(ShoppingItemAdapter());
  Hive.registerAdapter(ShoppingListAdapter());
  Hive.registerAdapter(ShoppingNoteAdapter());
  Hive.registerAdapter(RecipeAdapter());

  final box = await Hive.openBox<ShoppingList>('shopping_lists');
  await Hive.openBox<ShoppingNote>('shopping_notes');
  await Hive.openBox<Recipe>('recipes');
  await Hive.openBox<List<String>>('categories');
  
  // Migration: Ensure all lists use ID as key
  final keys = box.keys.toList();
  for (var key in keys) {
    if (key is int) {
      final list = box.get(key);
      if (list != null) {
        await box.delete(key);
        await box.put(list.id, list);
      }
    }
  }

  if (box.isEmpty) {
    final defaultList = ShoppingList(name: 'Compras do Mês', emoji: '🛒', budget: 500.0);
    await box.put(defaultList.id, defaultList);
  }

  runApp(const ProviderScope(child: SmartMarketListApp()));
}

class SmartMarketListApp extends ConsumerWidget {
  const SmartMarketListApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Smart Market List',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainScreen(),
    );
  }
}
