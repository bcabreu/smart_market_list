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
  
  if (box.isEmpty) {
    await box.add(ShoppingList(name: 'Compras do Mês', emoji: '🛒', budget: 500.0));
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
