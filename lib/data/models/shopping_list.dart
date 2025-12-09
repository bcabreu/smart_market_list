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

  @HiveField(6)
  List<String> members;

  @HiveField(7)
  String? ownerId;

  @HiveField(8)
  String? inviteCode;

  @HiveField(9)
  String? familyId;

  ShoppingList({
    String? id,
    required this.name,
    this.emoji = '🛒',
    this.budget = 500.0,
    List<ShoppingItem>? items,
    DateTime? createdAt,
    List<String>? members,
    this.ownerId,
    this.inviteCode,
    this.familyId,
  })  : id = id ?? const Uuid().v4(),
        items = items ?? [],
        members = members ?? [],
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
    List<String>? members,
    String? ownerId,
    String? inviteCode,
    String? familyId,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      budget: budget ?? this.budget,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      ownerId: ownerId ?? this.ownerId,
      inviteCode: inviteCode ?? this.inviteCode,
      familyId: familyId ?? this.familyId,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'budget': budget,
      'items': items.map((x) => x.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'members': members,
      'ownerId': ownerId,
      'inviteCode': inviteCode,
      'familyId': familyId,
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'],
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '🛒',
      budget: (map['budget'] ?? 500.0).toDouble(),
      items: (map['items'] as List<dynamic>? ?? [])
          .where((x) => x is Map<String, dynamic>)
          .map<ShoppingItem>((x) => ShoppingItem.fromMap(x as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      members: List<String>.from(map['members'] ?? []),
      ownerId: map['ownerId'],
      inviteCode: map['inviteCode'],
      familyId: map['familyId'],
    );
  }
}
