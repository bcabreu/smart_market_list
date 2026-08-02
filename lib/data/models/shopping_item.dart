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

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? statusChangedAt;

  @HiveField(9, defaultValue: 1)
  int unitQuantity;

  @HiveField(10)
  final DateTime? historyUpdatedAt;

  /// Calcula o preço total: quantidade × preço unitário
  double get totalPrice => unitQuantity * price;

  DateTime get historyTimestamp => historyUpdatedAt ?? createdAt;

  ShoppingItem({
    String? id,
    required this.name,
    this.quantity = '1 un',
    this.price = 0.0,
    this.category = 'outros',
    this.checked = false,
    this.imageUrl = '',
    DateTime? createdAt,
    this.statusChangedAt,
    this.unitQuantity = 1,
    this.historyUpdatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? quantity,
    double? price,
    String? category,
    bool? checked,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? statusChangedAt,
    int? unitQuantity,
    DateTime? historyUpdatedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      category: category ?? this.category,
      checked: checked ?? this.checked,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      unitQuantity: unitQuantity ?? this.unitQuantity,
      historyUpdatedAt: historyUpdatedAt ?? this.historyUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'category': category,
      'checked': checked,
      'imageUrl': imageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'statusChangedAt': statusChangedAt?.millisecondsSinceEpoch,
      'unitQuantity': unitQuantity,
      'historyUpdatedAt': historyUpdatedAt?.millisecondsSinceEpoch,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'],
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? '1 un',
      price: (map['price'] ?? 0.0).toDouble(),
      category: map['category'] ?? 'outros',
      checked: map['checked'] ?? false,
      imageUrl: map['imageUrl'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      statusChangedAt: map['statusChangedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['statusChangedAt'])
          : null,
      unitQuantity: map['unitQuantity'] ?? 1,
      historyUpdatedAt: map['historyUpdatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['historyUpdatedAt'])
          : null,
    );
  }
}
