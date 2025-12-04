import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'recipe.g.dart';

@HiveType(typeId: 3)
class Recipe extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String imageUrl;

  @HiveField(3)
  final List<String> ingredients;

  @HiveField(4)
  final List<String> instructions;

  @HiveField(5)
  final int prepTime;

  @HiveField(6)
  final String difficulty;

  @HiveField(7)
  int likes;

  @HiveField(8)
  bool isFavorite;

  Recipe({
    String? id,
    required this.name,
    required this.imageUrl,
    required this.ingredients,
    required this.instructions,
    this.prepTime = 30,
    this.difficulty = 'Médio',
    this.likes = 0,
    this.isFavorite = false,
  }) : id = id ?? const Uuid().v4();
}
