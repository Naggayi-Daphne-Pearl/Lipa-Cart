import 'package:flutter/foundation.dart';
import '../models/shopping_list.dart';
import '../models/product.dart';
import '../services/strapi_service.dart';

class ShoppingListProvider extends ChangeNotifier {
  List<ShoppingList> _lists = [];
  bool _isLoading = false;

  List<ShoppingList> get lists => _lists;
  bool get isLoading => _isLoading;

  // Predefined colors and emojis for lists
  static const List<String> listColors = [
    '#15874B', // Primary green
    '#EA7702', // Accent orange
    '#6366F1', // Indigo
    '#EC4899', // Pink
    '#14B8A6', // Teal
    '#F59E0B', // Amber
    '#8B5CF6', // Purple
    '#EF4444', // Red
  ];

  static const List<String> listEmojis = [
    '🛒', '🥗', '🍳', '🎉', '🏠', '💪', '🌱', '❤️',
    '🍎', '🥩', '🥛', '🍞', '☕', '🍕', '🎂', '🧺',
  ];

  Future<void> loadLists() async {
    _isLoading = true;
    notifyListeners();

    try {
      _lists = await StrapiService.getShoppingLists();
    } catch (e) {
      debugPrint('Strapi fetch failed, using sample data: $e');
      _lists = _getSampleLists();
    }

    _isLoading = false;
    notifyListeners();
  }

  ShoppingList? getListById(String id) {
    try {
      return _lists.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  void createList({
    required String name,
    String? description,
    String emoji = '🛒',
    String color = '#15874B',
  }) {
    final newList = ShoppingList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      emoji: emoji,
      color: color,
      items: [],
      createdAt: DateTime.now(),
    );
    _lists.insert(0, newList);
    notifyListeners();
  }

  void updateList(ShoppingList updatedList) {
    final index = _lists.indexWhere((l) => l.id == updatedList.id);
    if (index != -1) {
      _lists[index] = updatedList.copyWith(updatedAt: DateTime.now());
      notifyListeners();
    }
  }

  void deleteList(String listId) {
    _lists.removeWhere((l) => l.id == listId);
    notifyListeners();
  }

  void addItemToList(String listId, ShoppingListItem item) {
    final index = _lists.indexWhere((l) => l.id == listId);
    if (index != -1) {
      final list = _lists[index];
      final updatedItems = [...list.items, item];
      _lists[index] = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void addProductToList(String listId, Product product, {int quantity = 1}) {
    final item = ShoppingListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: product.name,
      quantity: quantity,
      unit: product.unit,
      linkedProduct: product,
    );
    addItemToList(listId, item);
  }

  void removeItemFromList(String listId, String itemId) {
    final index = _lists.indexWhere((l) => l.id == listId);
    if (index != -1) {
      final list = _lists[index];
      final updatedItems = list.items.where((i) => i.id != itemId).toList();
      _lists[index] = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void toggleItemChecked(String listId, String itemId) {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = _lists[listIndex];
      final updatedItems = list.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isChecked: !item.isChecked);
        }
        return item;
      }).toList();
      _lists[listIndex] = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void updateItemQuantity(String listId, String itemId, int quantity) {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = _lists[listIndex];
      final updatedItems = list.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();
      _lists[listIndex] = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void updateItemDescription(String listId, String itemId, String? description) {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = _lists[listIndex];
      final updatedItems = list.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(description: description);
        }
        return item;
      }).toList();
      _lists[listIndex] = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void clearCheckedItems(String listId) {
    final index = _lists.indexWhere((l) => l.id == listId);
    if (index != -1) {
      final list = _lists[index];
      final updatedItems = list.items.where((i) => !i.isChecked).toList();
      _lists[index] = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Sample data
  List<ShoppingList> _getSampleLists() {
    final sampleProducts = Product.getSampleProducts();

    return [
      ShoppingList(
        id: '1',
        name: 'Weekly Groceries',
        description: 'Regular household essentials',
        emoji: '🛒',
        color: '#15874B',
        items: [
          ShoppingListItem(
            id: '1',
            name: 'Fresh Milk',
            description: 'Full cream, not skimmed. Check expiry date - at least 5 days',
            quantity: 2,
            unit: 'liters',
            linkedProduct: sampleProducts.firstWhere((p) => p.name.contains('Milk'), orElse: () => sampleProducts.first),
          ),
          ShoppingListItem(
            id: '2',
            name: 'Brown Bread',
            description: 'Whole wheat, soft texture. Not the seeded one',
            quantity: 1,
            unit: 'loaf',
            linkedProduct: sampleProducts.firstWhere((p) => p.name.contains('Bread'), orElse: () => sampleProducts.first),
          ),
          ShoppingListItem(
            id: '3',
            name: 'Eggs',
            description: 'Large size, brown eggs preferred',
            quantity: 1,
            unit: 'tray',
            linkedProduct: sampleProducts.firstWhere((p) => p.name.contains('Egg'), orElse: () => sampleProducts.first),
          ),
          ShoppingListItem(
            id: '4',
            name: 'Tomatoes',
            description: 'Firm, slightly ripe. Not too soft',
            budgetAmount: 3000,
            quantity: 1,
            linkedProduct: sampleProducts.firstWhere((p) => p.name.contains('Tomato'), orElse: () => sampleProducts.first),
            isChecked: true,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ShoppingList(
        id: '2',
        name: 'BBQ Weekend',
        description: 'Meat and sides for the grill',
        emoji: '🥩',
        color: '#EA7702',
        items: [
          ShoppingListItem(
            id: '5',
            name: 'Chicken Wings',
            description: 'Fresh, not frozen. Medium-sized wings',
            quantity: 2,
            unit: 'kg',
            linkedProduct: sampleProducts.firstWhere((p) => p.name.contains('Chicken'), orElse: () => sampleProducts.first),
          ),
          ShoppingListItem(
            id: '6',
            name: 'Beef Steak',
            description: 'Well-marbled, ribeye or sirloin cut. About 2cm thick',
            budgetAmount: 25000,
            quantity: 1,
            linkedProduct: sampleProducts.firstWhere((p) => p.name.contains('Beef'), orElse: () => sampleProducts.first),
          ),
          ShoppingListItem(
            id: '7',
            name: 'Onions',
            description: 'Red onions, medium size',
            quantity: 4,
            unit: 'pieces',
            linkedProduct: sampleProducts.firstWhere((p) => p.name.contains('Onion'), orElse: () => sampleProducts.first),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ShoppingList(
        id: '3',
        name: 'Healthy Week',
        description: 'Fresh fruits and vegetables',
        emoji: '🥗',
        color: '#14B8A6',
        items: [
          ShoppingListItem(
            id: '8',
            name: 'Avocados',
            description: 'Ripe, ready to eat. Should yield slightly to gentle pressure',
            quantity: 4,
            unit: 'pieces',
            linkedProduct: sampleProducts.firstWhere((p) => p.name.contains('Avocado'), orElse: () => sampleProducts.first),
          ),
          ShoppingListItem(
            id: '9',
            name: 'Spinach',
            description: 'Fresh leaves, bright green. No wilting or yellowing',
            quantity: 2,
            unit: 'bunches',
            linkedProduct: sampleProducts.firstWhere((p) => p.name.contains('Spinach'), orElse: () => sampleProducts.first),
          ),
        ],
        createdAt: DateTime.now(),
      ),
    ];
  }
}
