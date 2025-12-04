import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'shopping_item.g.dart';

@HiveType(typeId: 0)
class ShoppingItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String quantity;

  @HiveField(3)
  double price;

  @HiveField(4)
  String category;

  @HiveField(5)
  bool checked;

  @HiveField(6)
  String imageUrl;

  ShoppingItem({
    String? id,
    required this.name,
    this.quantity = '1 un',
    this.price = 0.0,
    this.category = 'outros',
    this.checked = false,
    this.imageUrl = '',
  }) : id = id ?? const Uuid().v4();

  ShoppingItem copyWith({
    String? name,
    String? quantity,
    double? price,
    String? category,
    bool? checked,
    String? imageUrl,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      category: category ?? this.category,
      checked: checked ?? this.checked,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
