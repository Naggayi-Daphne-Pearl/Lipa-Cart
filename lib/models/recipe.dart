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

  factory Recipe.fromStrapi(Map<String, dynamic> json, {String? baseUrl}) {
    final attributes = (json['attributes'] as Map<String, dynamic>?) ?? json;
    String imageUrl = _resolveMediaUrl(attributes['image'], baseUrl);

    // Parse ingredients component
    final ingredientsData = attributes['ingredients'] as List<dynamic>? ?? [];
    final ingredients = ingredientsData.map<RecipeIngredient>((item) {
      final i = item as Map<String, dynamic>;
      final qty = i['quantity'];
      final unit = i['unit'] as String? ?? '';
      final notes = i['notes'] as String? ?? '';
      String quantityStr = '';
      if (qty != null) quantityStr = '$qty $unit'.trim();
      if (notes.isNotEmpty) quantityStr += ' ($notes)';

      return RecipeIngredient(
        id: (i['id'] ?? '').toString(),
        name: i['name'] as String? ?? '',
        quantity: quantityStr,
      );
    }).toList();

    // Parse instructions component
    final instructionsData = attributes['instructions'] as List<dynamic>? ?? [];
    final sortedInstructions = List<Map<String, dynamic>>.from(
      instructionsData.map((e) => e as Map<String, dynamic>),
    )..sort((a, b) => ((a['step_number'] as int?) ?? 0).compareTo((b['step_number'] as int?) ?? 0));
    final instructions = sortedInstructions
        .map<String>((i) => i['description'] as String? ?? '')
        .toList();

    // Parse tags
    final tagsData = attributes['tags'];
    List<String> tags = [];
    if (tagsData is List) {
      tags = tagsData.map((e) => e.toString()).toList();
    }

    // Difficulty enum: Strapi stores lowercase
    final difficultyRaw = attributes['difficulty'] as String? ?? 'medium';
    final difficulty = '${difficultyRaw[0].toUpperCase()}${difficultyRaw.substring(1)}';

    return Recipe(
      id: (json['documentId'] ?? json['id']).toString(),
      name: attributes['name'] as String? ?? '',
      description: attributes['description'] as String? ?? '',
      image: imageUrl,
      authorName: attributes['author_name'] as String?,
      prepTime: attributes['prep_time'] as int? ?? 0,
      cookTime: attributes['cook_time'] as int? ?? 0,
      servings: attributes['servings'] as int? ?? 1,
      difficulty: difficulty,
      ingredients: ingredients,
      instructions: instructions,
      tags: tags,
      rating: (attributes['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: attributes['review_count'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(attributes['createdAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  static String _resolveMediaUrl(dynamic media, String? baseUrl) {
    if (media == null) return '';

    Map<String, dynamic>? data;
    if (media is Map<String, dynamic>) {
      data = (media['data'] as Map<String, dynamic>?) ?? media;
    }
    if (data == null) return '';

    final attrs = (data['attributes'] as Map<String, dynamic>?) ?? data;
    final url = attrs['url'] as String? ?? '';
    if (url.isEmpty) return '';

    return url.startsWith('http') ? url : '${baseUrl ?? ""}$url';
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

  static List<Recipe> getSampleRecipes() {
    final sampleProducts = Product.getSampleProducts();
    Product? findProduct(String name) {
      try {
        return sampleProducts.firstWhere(
            (p) => p.name.toLowerCase().contains(name.toLowerCase()));
      } catch (_) {
        return null;
      }
    }

    return [
      Recipe(
        id: '1',
        name: 'Luwombo (Steamed Chicken Stew)',
        description:
            'A traditional Ugandan dish where chicken is steamed in banana leaves with groundnut sauce. A ceremonial favourite often served at special occasions, originating from the Buganda Kingdom.',
        image: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400',
        authorName: 'Chef Aisha',
        prepTime: 30,
        cookTime: 90,
        servings: 6,
        difficulty: 'Medium',
        rating: 4.8,
        reviewCount: 42,
        tags: ['Traditional', 'Ugandan', 'Special Occasion'],
        createdAt: DateTime(2025, 1, 1),
        ingredients: [
          RecipeIngredient(
            id: '1-1',
            name: 'Whole Chicken (cut into pieces)',
            quantity: '1 piece',
            linkedProduct: findProduct('Whole Chicken'),
          ),
          RecipeIngredient(
            id: '1-2',
            name: 'Groundnut Paste',
            quantity: '200g',
          ),
          RecipeIngredient(
            id: '1-3',
            name: 'Tomatoes (chopped)',
            quantity: '4 pieces',
            linkedProduct: findProduct('Tomatoes'),
          ),
          RecipeIngredient(
            id: '1-4',
            name: 'Onions (sliced)',
            quantity: '2 pieces',
            linkedProduct: findProduct('Onions'),
          ),
          RecipeIngredient(
            id: '1-5',
            name: 'Banana Leaves (for wrapping)',
            quantity: '6 pieces',
          ),
          RecipeIngredient(
            id: '1-6',
            name: 'Salt',
            quantity: '1 tsp',
          ),
        ],
        instructions: [
          'Mix groundnut paste with a little water to form a smooth sauce.',
          'Season chicken pieces with salt and set aside.',
          'Soften banana leaves over an open flame until pliable.',
          'Place chicken, tomatoes, onions, and groundnut sauce onto banana leaves. Wrap tightly into parcels.',
          'Place parcels in a large pot with a little water at the bottom. Steam on low heat for about 90 minutes until chicken is tender.',
        ],
      ),
      Recipe(
        id: '2',
        name: 'Rolex (Rolled Eggs)',
        description:
            'Uganda\'s beloved street food — a chapati rolled around a fried egg omelette with vegetables. The name comes from "rolled eggs". Quick, cheap, and delicious.',
        image: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400',
        authorName: 'Street Food Joe',
        prepTime: 5,
        cookTime: 10,
        servings: 1,
        difficulty: 'Easy',
        rating: 4.9,
        reviewCount: 128,
        tags: ['Quick', 'Street Food', 'Ugandan', 'Budget'],
        createdAt: DateTime(2025, 1, 5),
        ingredients: [
          RecipeIngredient(
            id: '2-1',
            name: 'Chapati',
            quantity: '1 piece',
          ),
          RecipeIngredient(
            id: '2-2',
            name: 'Eggs',
            quantity: '2 pieces',
            linkedProduct: findProduct('Eggs'),
          ),
          RecipeIngredient(
            id: '2-3',
            name: 'Tomatoes (diced)',
            quantity: '1 piece',
            linkedProduct: findProduct('Tomatoes'),
          ),
          RecipeIngredient(
            id: '2-4',
            name: 'Onions (diced)',
            quantity: '½ piece',
            linkedProduct: findProduct('Onions'),
          ),
          RecipeIngredient(
            id: '2-5',
            name: 'Cabbage (shredded)',
            quantity: '1 handful',
            linkedProduct: findProduct('Cabbage'),
          ),
          RecipeIngredient(
            id: '2-6',
            name: 'Cooking Oil',
            quantity: '2 tbsp',
            linkedProduct: findProduct('Cooking Oil'),
          ),
        ],
        instructions: [
          'Beat eggs and mix with diced tomatoes, onions, and cabbage. Season with salt.',
          'Heat oil in a pan and pour in the egg mixture. Cook as a flat omelette.',
          'Warm the chapati on the pan for 30 seconds each side.',
          'Place the omelette on the chapati and roll tightly. Serve immediately.',
        ],
      ),
      Recipe(
        id: '3',
        name: 'Matoke (Steamed Green Bananas)',
        description:
            'The staple dish of Uganda — green bananas steamed and mashed, often served with a meat or groundnut sauce. Every Ugandan home has their own version.',
        image: 'https://images.unsplash.com/photo-1603833665858-e61d17a86224?w=400',
        authorName: 'Mama Grace',
        prepTime: 15,
        cookTime: 45,
        servings: 4,
        difficulty: 'Easy',
        rating: 4.6,
        reviewCount: 67,
        tags: ['Traditional', 'Ugandan', 'Staple', 'Vegetarian'],
        createdAt: DateTime(2025, 1, 10),
        ingredients: [
          RecipeIngredient(
            id: '3-1',
            name: 'Green Bananas (Matooke), peeled',
            quantity: '1 bunch',
            linkedProduct: findProduct('Bananas'),
          ),
          RecipeIngredient(
            id: '3-2',
            name: 'Tomatoes (chopped)',
            quantity: '3 pieces',
            linkedProduct: findProduct('Tomatoes'),
          ),
          RecipeIngredient(
            id: '3-3',
            name: 'Onions (chopped)',
            quantity: '1 piece',
            linkedProduct: findProduct('Onions'),
          ),
          RecipeIngredient(
            id: '3-4',
            name: 'Cooking Oil',
            quantity: '3 tbsp',
            linkedProduct: findProduct('Cooking Oil'),
          ),
          RecipeIngredient(
            id: '3-5',
            name: 'Salt',
            quantity: '1 tsp',
          ),
          RecipeIngredient(
            id: '3-6',
            name: 'Water',
            quantity: '500ml',
          ),
        ],
        instructions: [
          'Peel the green bananas and place in a pot lined with banana leaves or a steamer.',
          'Sauté onions in oil until golden, add tomatoes and cook until soft to make the sauce.',
          'Pour sauce over bananas, add water, cover tightly and steam on low heat for about 40 minutes.',
          'Mash the bananas in the pot until smooth. Serve hot with groundnut sauce or meat stew.',
        ],
      ),
    ];
  }
}
