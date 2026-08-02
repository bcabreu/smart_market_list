import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:smart_market_list/data/local/shopping_list_service.dart';
import 'package:smart_market_list/data/models/shopping_item.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';

void main() {
  late Directory temporaryDirectory;
  late Box<ShoppingList> listBox;

  setUpAll(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'smart_market_list_service_test_',
    );
    Hive.init(temporaryDirectory.path);
    if (!Hive.isAdapterRegistered(ShoppingItemAdapter().typeId)) {
      Hive.registerAdapter(ShoppingItemAdapter());
    }
    if (!Hive.isAdapterRegistered(ShoppingListAdapter().typeId)) {
      Hive.registerAdapter(ShoppingListAdapter());
    }
  });

  setUp(() async {
    listBox = await Hive.openBox<ShoppingList>('shopping_lists_test');
    await listBox.clear();
  });

  tearDown(() async {
    await listBox.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await temporaryDirectory.delete(recursive: true);
  });

  test('keeps the latest price in history after removing an item', () async {
    final rememberedItems = <ShoppingItem>[];
    final service = ShoppingListService(
      listBox,
      null,
      null,
      (item) async => rememberedItems.add(item),
    );
    final list = ShoppingList(name: 'Mercado', ownerId: 'user-1');
    await listBox.put(list.id, list);

    final item = ShoppingItem(name: 'tomate', price: 7.50);
    await service.addItem(list.id, item);
    final storedItem = listBox.get(list.id)!.items.single;
    expect(storedItem.name, 'Tomate');

    await service.updateItem(list.id, storedItem.copyWith(price: 8.75));
    await service.removeItem(list.id, storedItem.id);

    expect(listBox.get(list.id)!.items, isEmpty);
    expect(rememberedItems.last.name, 'Tomate');
    expect(rememberedItems.last.price, 8.75);
  });

  test('downgrade keeps a personal cloud list as a local list', () async {
    final service = ShoppingListService(listBox);
    final list = ShoppingList(
      name: 'Mercado',
      familyId: 'family-1',
      ownerId: 'user-1',
      items: [ShoppingItem(name: 'Tomate', price: 8.75)],
    );
    await listBox.put(list.id, list);

    await service.startSync('family-1', 'user-1', syncFamilyLists: false);

    final localOnly = listBox.get(list.id)!;
    expect(localOnly.familyId, isNull);
    expect(localOnly.items.single.price, 8.75);
  });
}
