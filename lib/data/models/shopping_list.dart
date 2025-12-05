import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'shopping_item.dart';

part 'shopping_list.g.dart';

@HiveType(typeId: 1)
class ShoppingList extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String emoji;

  @HiveField(3)
  double budget;

  @HiveField(4)
  List<ShoppingItem> items;

  @HiveField(5)
  DateTime createdAt;

  ShoppingList({
    String? id,
    required this.name,
    this.emoji = '🛒',
    this.budget = 500.0,
    List<ShoppingItem>? items,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  double get totalSpent => items.fold(0.0, (sum, item) => sum + (item.checked ? item.price : 0.0));
  double get totalEstimated => items.fold(0.0, (sum, item) => sum + item.price);
  double get percentage => budget > 0 ? (totalSpent / budget) * 100 : 0;

  ShoppingList copyWith({
    String? id,
    String? name,
    String? emoji,
    double? budget,
    List<ShoppingItem>? items,
    DateTime? createdAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      budget: budget ?? this.budget,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
