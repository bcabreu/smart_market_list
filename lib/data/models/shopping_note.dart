import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shopping_item.dart';

part 'shopping_note.g.dart';

@HiveType(typeId: 2)
class ShoppingNote extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String storeName;

  @HiveField(2)
  String storeEmoji;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String address;

  @HiveField(5)
  List<ShoppingItem> items;

  @HiveField(6)
  String? photoUrl;

  ShoppingNote({
    String? id,
    required this.storeName,
    this.storeEmoji = '🏪',
    required this.date,
    this.address = '',
    List<ShoppingItem>? items,
    this.photoUrl,
  })  : id = id ?? const Uuid().v4(),
        items = items ?? [];

  double get total => items.fold(0.0, (sum, item) => sum + item.price);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storeName': storeName,
      'storeEmoji': storeEmoji,
      'date': Timestamp.fromDate(date),
      'address': address,
      'items': items.map((i) => i.toMap()).toList(),
      'photoUrl': photoUrl,
    };
  }

  factory ShoppingNote.fromMap(Map<String, dynamic> map) {
    return ShoppingNote(
      id: map['id'],
      storeName: map['storeName'] ?? '',
      storeEmoji: map['storeEmoji'] ?? '🏪',
      date: (map['date'] as Timestamp).toDate(),
      address: map['address'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.where((x) => x is Map<String, dynamic>)
          .map((x) => ShoppingItem.fromMap(x as Map<String, dynamic>))
          .toList() ?? [],
      photoUrl: map['photoUrl'],
    );
  }
}
