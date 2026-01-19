import 'product.dart';

class RecipeIngredient {
  final String id;
  final String name;
  final String quantity; // e.g., "2 cups", "500g", "3 pieces"
  final Product? linkedProduct; // Optional link to actual product
  final bool isOptional;

  RecipeIngredient({
    required this.id,
    required this.name,
    required this.quantity,
    this.linkedProduct,
    this.isOptional = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'linkedProductId': linkedProduct?.id,
      'isOptional': isOptional,
    };
  }
}

class Recipe {
  final String id;
  final String name;
  final String description;
  final String image;
  final String? authorName;
  final String? authorImage;
  final int prepTime; // in minutes
  final int cookTime; // in minutes
  final int servings;
  final String difficulty; // Easy, Medium, Hard
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final List<String> tags; // e.g., "Vegetarian", "Quick", "Kenyan"
  final double rating;
  final int reviewCount;
  final bool isFavorite;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.authorName,
    this.authorImage,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    this.difficulty = 'Medium',
    this.ingredients = const [],
    this.instructions = const [],
    this.tags = const [],
    this.rating = 0,
    this.reviewCount = 0,
    this.isFavorite = false,
    required this.createdAt,
  });

  int get totalTime => prepTime + cookTime;

  // Get ingredients that have linked products (can be added to cart)
  List<RecipeIngredient> get purchasableIngredients =>
      ingredients.where((i) => i.linkedProduct != null).toList();

  // Calculate estimated cost based on linked products
  double get estimatedCost {
    double total = 0;
    for (final ingredient in purchasableIngredients) {
      if (ingredient.linkedProduct != null) {
        total += ingredient.linkedProduct!.price;
      }
    }
    return total;
  }

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    String? authorName,
    String? authorImage,
    int? prepTime,
    int? cookTime,
    int? servings,
    String? difficulty,
    List<RecipeIngredient>? ingredients,
    List<String>? instructions,
    List<String>? tags,
    double? rating,
    int? reviewCount,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'authorName': authorName,
      'authorImage': authorImage,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'difficulty': difficulty,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
