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

  @HiveField(9, defaultValue: 2)
  final int servings;

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
    this.servings = 2,
  }) : id = id ?? const Uuid().v4();

  Recipe copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<String>? ingredients,
    List<String>? instructions,
    int? prepTime,
    String? difficulty,
    int? likes,
    bool? isFavorite,
    int? servings,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepTime: prepTime ?? this.prepTime,
      difficulty: difficulty ?? this.difficulty,
      likes: likes ?? this.likes,
      isFavorite: isFavorite ?? this.isFavorite,
      servings: servings ?? this.servings,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTime': prepTime,
      'difficulty': difficulty,
      'likes': likes,
      'isFavorite': isFavorite,
      'servings': servings,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      prepTime: map['prepTime'] ?? 30,
      difficulty: map['difficulty'] ?? 'Médio',
      likes: map['likes'] ?? 0,
      isFavorite: map['isFavorite'] ?? false,
      servings: map['servings'] ?? 2,
    );
  }
}
