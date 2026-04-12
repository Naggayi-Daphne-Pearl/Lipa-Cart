import 'package:flutter_test/flutter_test.dart';
import 'package:lipa_cart/models/product.dart';
import 'package:lipa_cart/models/recipe.dart';

void main() {
  group('Recipe model', () {
    test('estimatedCost excludes optional ingredients', () {
      final tomato = Product(
        id: 'p1',
        name: 'Tomatoes',
        description: '',
        image: '',
        price: 3000,
        unit: 'kg',
        categoryId: 'c1',
        categoryName: 'Vegetables',
      );

      final spice = Product(
        id: 'p2',
        name: 'Spice Mix',
        description: '',
        image: '',
        price: 1500,
        unit: 'pack',
        categoryId: 'c1',
        categoryName: 'Vegetables',
      );

      final recipe = Recipe(
        id: 'r1',
        name: 'Test Recipe',
        description: 'desc',
        image: '',
        prepTime: 10,
        cookTime: 20,
        servings: 2,
        ingredients: [
          RecipeIngredient(
            id: 'i1',
            name: 'Tomatoes',
            quantity: '1 kg',
            linkedProduct: tomato,
            isOptional: false,
          ),
          RecipeIngredient(
            id: 'i2',
            name: 'Spice Mix',
            quantity: '1 pack',
            linkedProduct: spice,
            isOptional: true,
          ),
        ],
        createdAt: DateTime.now(),
      );

      expect(recipe.estimatedCost, 3000);
    });

    test('fromStrapi parses is_optional flag', () {
      final recipe = Recipe.fromStrapi({
        'documentId': 'rec_1',
        'name': 'Optional Ingredient Recipe',
        'description': 'desc',
        'prep_time': 5,
        'cook_time': 10,
        'servings': 1,
        'difficulty': 'easy',
        'ingredients': [
          {
            'id': 1,
            'name': 'Salt',
            'quantity': 1,
            'unit': 'tsp',
            'is_optional': true,
          },
        ],
        'instructions': const [],
        'tags': const [],
      });

      expect(recipe.ingredients.length, 1);
      expect(recipe.ingredients.first.isOptional, isTrue);
    });
  });
}
