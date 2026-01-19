import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/product.dart';

class RecipeProvider extends ChangeNotifier {
  List<Recipe> _recipes = [];
  List<Recipe> _favoriteRecipes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Recipe> get recipes => _recipes;
  List<Recipe> get favoriteRecipes => _favoriteRecipes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Recipe> get popularRecipes =>
      _recipes.where((r) => r.rating >= 4.5).take(6).toList();

  List<Recipe> get quickRecipes =>
      _recipes.where((r) => r.totalTime <= 30).toList();

  List<String> get allTags {
    final tags = <String>{};
    for (final recipe in _recipes) {
      tags.addAll(recipe.tags);
    }
    return tags.toList()..sort();
  }

  Future<void> loadRecipes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      _recipes = _getSampleRecipes();
      _favoriteRecipes = _recipes.where((r) => r.isFavorite).toList();
    } catch (e) {
      _errorMessage = 'Failed to load recipes. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Recipe? getRecipeById(String id) {
    try {
      return _recipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Recipe> getRecipesByTag(String tag) {
    return _recipes.where((r) => r.tags.contains(tag)).toList();
  }

  List<Recipe> searchRecipes(String query) {
    if (query.isEmpty) return [];
    final lowercaseQuery = query.toLowerCase();
    return _recipes.where((recipe) {
      return recipe.name.toLowerCase().contains(lowercaseQuery) ||
          recipe.description.toLowerCase().contains(lowercaseQuery) ||
          recipe.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
          recipe.ingredients
              .any((i) => i.name.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  void toggleFavorite(String recipeId) {
    final index = _recipes.indexWhere((r) => r.id == recipeId);
    if (index != -1) {
      _recipes[index] = _recipes[index].copyWith(
        isFavorite: !_recipes[index].isFavorite,
      );
      _favoriteRecipes = _recipes.where((r) => r.isFavorite).toList();
      notifyListeners();
    }
  }

  // Sample recipes with Kenyan/African and international dishes
  List<Recipe> _getSampleRecipes() {
    final products = Product.getSampleProducts();

    Product? findProduct(String name) {
      try {
        return products.firstWhere(
          (p) => p.name.toLowerCase().contains(name.toLowerCase()),
        );
      } catch (_) {
        return null;
      }
    }

    return [
      Recipe(
        id: '1',
        name: 'Nyama Choma',
        description:
            'Classic Kenyan grilled meat with kachumbari salad. Perfect for family gatherings and celebrations.',
        image: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800',
        authorName: 'Chef Wanjiku',
        prepTime: 30,
        cookTime: 45,
        servings: 6,
        difficulty: 'Medium',
        rating: 4.9,
        reviewCount: 234,
        tags: ['Kenyan', 'Grilled', 'Meat', 'Traditional'],
        ingredients: [
          RecipeIngredient(
            id: '1',
            name: 'Beef Ribs',
            quantity: '2 kg',
            linkedProduct: findProduct('Beef'),
          ),
          RecipeIngredient(
            id: '2',
            name: 'Tomatoes',
            quantity: '4 large',
            linkedProduct: findProduct('Tomato'),
          ),
          RecipeIngredient(
            id: '3',
            name: 'Onions',
            quantity: '2 large',
            linkedProduct: findProduct('Onion'),
          ),
          RecipeIngredient(
            id: '4',
            name: 'Coriander',
            quantity: '1 bunch',
            linkedProduct: findProduct('Coriander'),
          ),
          RecipeIngredient(
            id: '5',
            name: 'Lemon',
            quantity: '2 pieces',
            linkedProduct: findProduct('Lemon'),
          ),
          RecipeIngredient(
            id: '6',
            name: 'Salt',
            quantity: 'To taste',
          ),
        ],
        instructions: [
          'Season the beef ribs with salt and let them rest for 30 minutes at room temperature.',
          'Prepare the charcoal grill to medium-high heat.',
          'Place the ribs on the grill and cook for 20-25 minutes per side, turning occasionally.',
          'While meat grills, prepare kachumbari: dice tomatoes and onions finely.',
          'Mix tomatoes, onions, and chopped coriander in a bowl.',
          'Season kachumbari with salt and lemon juice.',
          'Once meat reaches desired doneness, let it rest for 5 minutes.',
          'Slice and serve with kachumbari and ugali.',
        ],
        isFavorite: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Recipe(
        id: '2',
        name: 'Pilau',
        description:
            'Aromatic Swahili spiced rice dish with tender meat. A coastal Kenyan favorite with rich flavors.',
        image: 'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=800',
        authorName: 'Mama Fatuma',
        prepTime: 20,
        cookTime: 50,
        servings: 8,
        difficulty: 'Medium',
        rating: 4.8,
        reviewCount: 189,
        tags: ['Kenyan', 'Rice', 'Swahili', 'One-Pot'],
        ingredients: [
          RecipeIngredient(
            id: '1',
            name: 'Basmati Rice',
            quantity: '3 cups',
            linkedProduct: findProduct('Rice'),
          ),
          RecipeIngredient(
            id: '2',
            name: 'Beef',
            quantity: '500g',
            linkedProduct: findProduct('Beef'),
          ),
          RecipeIngredient(
            id: '3',
            name: 'Onions',
            quantity: '3 large',
            linkedProduct: findProduct('Onion'),
          ),
          RecipeIngredient(
            id: '4',
            name: 'Garlic',
            quantity: '6 cloves',
            linkedProduct: findProduct('Garlic'),
          ),
          RecipeIngredient(
            id: '5',
            name: 'Pilau Masala',
            quantity: '2 tbsp',
          ),
          RecipeIngredient(
            id: '6',
            name: 'Potatoes',
            quantity: '2 medium',
            linkedProduct: findProduct('Potato'),
            isOptional: true,
          ),
        ],
        instructions: [
          'Wash rice and soak in water for 30 minutes, then drain.',
          'In a heavy pot, heat oil and fry sliced onions until deep brown.',
          'Add beef pieces and brown on all sides.',
          'Add garlic, ginger, and pilau masala. Stir for 2 minutes.',
          'Pour in water (double the amount of rice) and bring to boil.',
          'Add potatoes if using, then add the soaked rice.',
          'Reduce heat to low, cover tightly, and cook for 25 minutes.',
          'Fluff with fork and serve hot.',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      Recipe(
        id: '3',
        name: 'Ugali & Sukuma Wiki',
        description:
            'The quintessential Kenyan meal. Cornmeal porridge served with sautéed collard greens.',
        image: 'https://images.unsplash.com/photo-1604329760661-e71dc83f8f26?w=800',
        authorName: 'Chef Kamau',
        prepTime: 10,
        cookTime: 25,
        servings: 4,
        difficulty: 'Easy',
        rating: 4.7,
        reviewCount: 312,
        tags: ['Kenyan', 'Vegetarian', 'Traditional', 'Quick'],
        ingredients: [
          RecipeIngredient(
            id: '1',
            name: 'Maize Flour',
            quantity: '2 cups',
            linkedProduct: findProduct('Flour'),
          ),
          RecipeIngredient(
            id: '2',
            name: 'Sukuma Wiki (Kale)',
            quantity: '1 large bunch',
            linkedProduct: findProduct('Spinach'),
          ),
          RecipeIngredient(
            id: '3',
            name: 'Onion',
            quantity: '1 medium',
            linkedProduct: findProduct('Onion'),
          ),
          RecipeIngredient(
            id: '4',
            name: 'Tomatoes',
            quantity: '2 medium',
            linkedProduct: findProduct('Tomato'),
          ),
          RecipeIngredient(
            id: '5',
            name: 'Cooking Oil',
            quantity: '3 tbsp',
            linkedProduct: findProduct('Oil'),
          ),
        ],
        instructions: [
          'Boil 3 cups of water in a heavy pot.',
          'Gradually add maize flour while stirring continuously.',
          'Keep stirring until mixture thickens and pulls away from pot sides.',
          'For sukuma: heat oil and sauté onions until translucent.',
          'Add diced tomatoes and cook for 3 minutes.',
          'Add chopped sukuma wiki and stir-fry for 5-7 minutes.',
          'Season with salt and serve alongside ugali.',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Recipe(
        id: '4',
        name: 'Chicken Tikka Masala',
        description:
            'Creamy, spiced tomato-based curry with tender chicken pieces. A family favorite.',
        image: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800',
        authorName: 'Chef Patel',
        prepTime: 25,
        cookTime: 35,
        servings: 4,
        difficulty: 'Medium',
        rating: 4.8,
        reviewCount: 276,
        tags: ['Indian', 'Curry', 'Chicken', 'Creamy'],
        ingredients: [
          RecipeIngredient(
            id: '1',
            name: 'Chicken Breast',
            quantity: '600g',
            linkedProduct: findProduct('Chicken'),
          ),
          RecipeIngredient(
            id: '2',
            name: 'Yogurt',
            quantity: '1 cup',
            linkedProduct: findProduct('Yogurt'),
          ),
          RecipeIngredient(
            id: '3',
            name: 'Tomatoes',
            quantity: '400g canned',
            linkedProduct: findProduct('Tomato'),
          ),
          RecipeIngredient(
            id: '4',
            name: 'Heavy Cream',
            quantity: '200ml',
            linkedProduct: findProduct('Cream'),
          ),
          RecipeIngredient(
            id: '5',
            name: 'Onion',
            quantity: '1 large',
            linkedProduct: findProduct('Onion'),
          ),
          RecipeIngredient(
            id: '6',
            name: 'Garlic',
            quantity: '4 cloves',
            linkedProduct: findProduct('Garlic'),
          ),
        ],
        instructions: [
          'Marinate chicken in yogurt and spices for at least 2 hours.',
          'Grill or pan-fry chicken until cooked through. Set aside.',
          'Sauté onions until golden, add garlic and ginger.',
          'Add tomato puree and cook for 10 minutes.',
          'Stir in cream and simmer for 5 minutes.',
          'Add chicken pieces and heat through.',
          'Garnish with fresh coriander and serve with naan or rice.',
        ],
        isFavorite: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Recipe(
        id: '5',
        name: 'Avocado Toast',
        description:
            'Simple, nutritious breakfast with creamy avocado on crusty bread. Quick and delicious.',
        image: 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=800',
        authorName: 'Chef Sarah',
        prepTime: 5,
        cookTime: 5,
        servings: 2,
        difficulty: 'Easy',
        rating: 4.5,
        reviewCount: 156,
        tags: ['Breakfast', 'Quick', 'Healthy', 'Vegetarian'],
        ingredients: [
          RecipeIngredient(
            id: '1',
            name: 'Avocado',
            quantity: '2 ripe',
            linkedProduct: findProduct('Avocado'),
          ),
          RecipeIngredient(
            id: '2',
            name: 'Bread',
            quantity: '4 slices',
            linkedProduct: findProduct('Bread'),
          ),
          RecipeIngredient(
            id: '3',
            name: 'Eggs',
            quantity: '2',
            linkedProduct: findProduct('Egg'),
            isOptional: true,
          ),
          RecipeIngredient(
            id: '4',
            name: 'Cherry Tomatoes',
            quantity: '1 cup',
            linkedProduct: findProduct('Tomato'),
            isOptional: true,
          ),
        ],
        instructions: [
          'Toast bread slices until golden and crispy.',
          'Cut avocados in half and remove the pit.',
          'Scoop out flesh and mash with a fork.',
          'Season with salt, pepper, and a squeeze of lemon.',
          'Spread mashed avocado on toast.',
          'Top with poached egg and cherry tomatoes if desired.',
          'Sprinkle with chili flakes and serve immediately.',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Recipe(
        id: '6',
        name: 'Chapati',
        description:
            'Soft, layered flatbread perfect for scooping up stews and curries. A Kenyan staple.',
        image: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800',
        authorName: 'Mama Njeri',
        prepTime: 40,
        cookTime: 30,
        servings: 8,
        difficulty: 'Medium',
        rating: 4.6,
        reviewCount: 198,
        tags: ['Kenyan', 'Bread', 'Traditional', 'Vegetarian'],
        ingredients: [
          RecipeIngredient(
            id: '1',
            name: 'All-Purpose Flour',
            quantity: '3 cups',
            linkedProduct: findProduct('Flour'),
          ),
          RecipeIngredient(
            id: '2',
            name: 'Cooking Oil',
            quantity: '1/2 cup',
            linkedProduct: findProduct('Oil'),
          ),
          RecipeIngredient(
            id: '3',
            name: 'Salt',
            quantity: '1 tsp',
          ),
          RecipeIngredient(
            id: '4',
            name: 'Warm Water',
            quantity: '1 cup',
          ),
        ],
        instructions: [
          'Mix flour and salt in a large bowl.',
          'Add oil and mix until crumbly.',
          'Gradually add warm water and knead into soft dough.',
          'Cover and rest for 30 minutes.',
          'Divide into 8 balls and roll each into a thin circle.',
          'Brush with oil, fold, and roll again.',
          'Cook on hot pan, turning and brushing with oil until golden.',
          'Stack and cover to keep warm.',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Recipe(
        id: '7',
        name: 'Fruit Smoothie Bowl',
        description:
            'Refreshing blend of tropical fruits topped with granola and fresh fruits. Perfect breakfast.',
        image: 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=800',
        authorName: 'Chef Lisa',
        prepTime: 10,
        cookTime: 0,
        servings: 2,
        difficulty: 'Easy',
        rating: 4.7,
        reviewCount: 142,
        tags: ['Breakfast', 'Healthy', 'Quick', 'Vegetarian'],
        ingredients: [
          RecipeIngredient(
            id: '1',
            name: 'Bananas',
            quantity: '2 frozen',
            linkedProduct: findProduct('Banana'),
          ),
          RecipeIngredient(
            id: '2',
            name: 'Mixed Berries',
            quantity: '1 cup',
            linkedProduct: findProduct('Berries'),
          ),
          RecipeIngredient(
            id: '3',
            name: 'Yogurt',
            quantity: '1/2 cup',
            linkedProduct: findProduct('Yogurt'),
          ),
          RecipeIngredient(
            id: '4',
            name: 'Honey',
            quantity: '2 tbsp',
            linkedProduct: findProduct('Honey'),
          ),
          RecipeIngredient(
            id: '5',
            name: 'Granola',
            quantity: '1/4 cup',
            isOptional: true,
          ),
        ],
        instructions: [
          'Add frozen bananas and berries to a blender.',
          'Add yogurt and blend until thick and smooth.',
          'Pour into bowls.',
          'Top with fresh fruit slices, granola, and a drizzle of honey.',
          'Serve immediately.',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Recipe(
        id: '8',
        name: 'Beef Stir Fry',
        description:
            'Quick and flavorful beef with colorful vegetables. Ready in under 30 minutes.',
        image: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=800',
        authorName: 'Chef Chen',
        prepTime: 15,
        cookTime: 10,
        servings: 4,
        difficulty: 'Easy',
        rating: 4.6,
        reviewCount: 167,
        tags: ['Asian', 'Quick', 'Meat', 'Healthy'],
        ingredients: [
          RecipeIngredient(
            id: '1',
            name: 'Beef Sirloin',
            quantity: '500g',
            linkedProduct: findProduct('Beef'),
          ),
          RecipeIngredient(
            id: '2',
            name: 'Bell Peppers',
            quantity: '2 mixed colors',
            linkedProduct: findProduct('Pepper'),
          ),
          RecipeIngredient(
            id: '3',
            name: 'Broccoli',
            quantity: '1 head',
            linkedProduct: findProduct('Broccoli'),
          ),
          RecipeIngredient(
            id: '4',
            name: 'Soy Sauce',
            quantity: '3 tbsp',
          ),
          RecipeIngredient(
            id: '5',
            name: 'Garlic',
            quantity: '3 cloves',
            linkedProduct: findProduct('Garlic'),
          ),
          RecipeIngredient(
            id: '6',
            name: 'Ginger',
            quantity: '1 inch piece',
          ),
        ],
        instructions: [
          'Slice beef thinly against the grain.',
          'Cut vegetables into bite-sized pieces.',
          'Heat oil in a wok over high heat.',
          'Stir-fry beef for 2 minutes. Remove and set aside.',
          'Add vegetables and stir-fry for 3-4 minutes.',
          'Return beef to wok with garlic and ginger.',
          'Add soy sauce and toss everything together.',
          'Serve hot over steamed rice.',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
