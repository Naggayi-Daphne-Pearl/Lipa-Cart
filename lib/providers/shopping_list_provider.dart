import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/shopping_list.dart';
import '../models/product.dart';
import '../services/strapi_service.dart';
import '../core/constants/app_constants.dart';

class ShoppingListProvider extends ChangeNotifier {
  static const int freeTierListLimit = 3;

  List<ShoppingList> _lists = [];
  bool _isLoading = false;
  bool _didBootstrap = false;

  ShoppingListProvider() {
    _bootstrap();
  }

  List<ShoppingList> get lists => _lists;
  bool get isLoading => _isLoading;

  Future<void> _bootstrap() async {
    if (_didBootstrap) return;
    _didBootstrap = true;
    await _restoreLists();
  }

  Future<void> _restoreLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.shoppingListsKey);
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw) as List<dynamic>;
      _lists = data
          .map((e) => ShoppingList.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {
      // Ignore corrupted cache
    }
  }

  Future<void> _persistLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(_lists.map((l) => l.toJson()).toList());
      await prefs.setString(AppConstants.shoppingListsKey, payload);
    } catch (_) {
      // Ignore persistence errors
    }
  }

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
    '🛒',
    '🥗',
    '🍳',
    '🎉',
    '🏠',
    '💪',
    '🌱',
    '❤️',
    '🍎',
    '🥩',
    '🥛',
    '🍞',
    '☕',
    '🍕',
    '🎂',
    '🧺',
  ];

  Future<void> loadLists({String? authToken}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _lists = await StrapiService.getShoppingLists(authToken: authToken);
    } catch (e) {
      debugPrint('Strapi fetch failed, using sample data: $e');
      _lists = _getSampleLists();
    }

    _isLoading = false;
    _persistLists();
    notifyListeners();
  }

  ShoppingList? getListById(String id) {
    try {
      return _lists.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  bool canCreateList({required bool isPremium}) {
    if (isPremium) return true;
    return _lists.length < freeTierListLimit;
  }

  Future<bool> createList({
    required String name,
    String? description,
    String emoji = '🛒',
    String color = '#15874B',
    bool isPremium = false,
    String? authToken,
  }) async {
    if (!canCreateList(isPremium: isPremium)) {
      return false;
    }

    if (authToken == null || authToken.isEmpty) {
      throw Exception('Authentication required to create shopping lists');
    }

    final newList = await StrapiService.createShoppingList(
      name: name,
      description: description,
      emoji: emoji,
      color: color,
      authToken: authToken,
    );

    _lists.insert(0, newList);
    await _persistLists();
    notifyListeners();
    return true;
  }

  Future<bool> updateList(ShoppingList updatedList, {String? authToken}) async {
    final index = _lists.indexWhere((l) => l.id == updatedList.id);
    if (index == -1) {
      return false;
    }

    if (authToken == null || authToken.isEmpty) {
      throw Exception('Authentication required to update shopping lists');
    }

    final savedList = await StrapiService.updateShoppingList(
      listId: updatedList.id,
      name: updatedList.name,
      description: updatedList.description,
      emoji: updatedList.emoji ?? '🛒',
      color: updatedList.color,
      items: updatedList.items,
      authToken: authToken,
    );

    _lists[index] = savedList;
    await _persistLists();
    notifyListeners();
    return true;
  }

  Future<void> _syncListItemsToBackend({
    required ShoppingList list,
    String? authToken,
  }) async {
    if (authToken == null || authToken.isEmpty) return;

    try {
      final savedList = await StrapiService.updateShoppingList(
        listId: list.id,
        name: list.name,
        description: list.description,
        emoji: list.emoji ?? '🛒',
        color: list.color,
        items: list.items,
        authToken: authToken,
      );

      final refreshedIndex = _lists.indexWhere((l) => l.id == savedList.id);
      if (refreshedIndex != -1) {
        _lists[refreshedIndex] = savedList;
        await _persistLists();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to sync shopping list items: $e');
    }
  }

  Future<bool> deleteList(String listId, {String? authToken}) async {
    final index = _lists.indexWhere((l) => l.id == listId);
    if (index == -1) {
      return false;
    }

    if (authToken == null || authToken.isEmpty) {
      throw Exception('Authentication required to delete shopping lists');
    }

    await StrapiService.deleteShoppingList(
      listId: listId,
      authToken: authToken,
    );

    _lists.removeWhere((l) => l.id == listId);
    await _persistLists();
    notifyListeners();
    return true;
  }

  Future<bool> addItemToList(
    String listId,
    ShoppingListItem item, {
    String? authToken,
  }) async {
    final index = _lists.indexWhere((l) => l.id == listId);
    if (index == -1) {
      return false;
    }

    final list = _lists[index];
    final normalizedName = item.name.trim().toLowerCase();
    final incomingProductId = item.linkedProduct?.strapiId ?? item.linkedProduct?.id;

    final duplicateIndex = list.items.indexWhere((existing) {
      final existingName = existing.name.trim().toLowerCase();
      final existingProductId = existing.linkedProduct?.strapiId ?? existing.linkedProduct?.id;
      final sameProduct = existingProductId == incomingProductId;
      final bothUnlinked = existingProductId == null && incomingProductId == null;
      return existingName == normalizedName && (sameProduct || bothUnlinked);
    });

    final bool mergedExisting;
    List<ShoppingListItem> updatedItems;

    if (duplicateIndex != -1) {
      mergedExisting = true;
      final existing = list.items[duplicateIndex];
      final mergedItem = existing.copyWith(
        quantity: existing.quantity + item.quantity,
        description: (existing.description == null || existing.description!.trim().isEmpty)
            ? item.description
            : existing.description,
        unitPrice: existing.unitPrice ?? item.unitPrice,
        budgetAmount: existing.budgetAmount ?? item.budgetAmount,
      );

      updatedItems = [...list.items];
      updatedItems[duplicateIndex] = mergedItem;
    } else {
      mergedExisting = false;
      updatedItems = [...list.items, item];
    }

      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
    _lists[index] = updatedList;
    await _persistLists();
    notifyListeners();
    await _syncListItemsToBackend(list: updatedList, authToken: authToken);

    return mergedExisting;
  }

  Future<void> addProductToList(
    String listId,
    Product product, {
    int quantity = 1,
    String? authToken,
  }) async {
    final item = ShoppingListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: product.name,
      quantity: quantity,
      unit: product.unit,
      unitPrice: product.price,
      linkedProduct: product,
    );
    await addItemToList(listId, item, authToken: authToken);
  }

  Future<void> removeItemFromList(
    String listId,
    String itemId, {
    String? authToken,
  }) async {
    final index = _lists.indexWhere((l) => l.id == listId);
    if (index != -1) {
      final list = _lists[index];
      final updatedItems = list.items.where((i) => i.id != itemId).toList();
      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      _lists[index] = updatedList;
      await _persistLists();
      notifyListeners();
      await _syncListItemsToBackend(list: updatedList, authToken: authToken);
    }
  }

  Future<void> toggleItemChecked(
    String listId,
    String itemId, {
    String? authToken,
  }) async {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = _lists[listIndex];
      final updatedItems = list.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isChecked: !item.isChecked);
        }
        return item;
      }).toList();
      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      _lists[listIndex] = updatedList;
      await _persistLists();
      notifyListeners();
      await _syncListItemsToBackend(list: updatedList, authToken: authToken);
    }
  }

  Future<void> updateItemQuantity(
    String listId,
    String itemId,
    int quantity, {
    String? authToken,
  }) async {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = _lists[listIndex];
      final updatedItems = list.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();
      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      _lists[listIndex] = updatedList;
      await _persistLists();
      notifyListeners();
      await _syncListItemsToBackend(list: updatedList, authToken: authToken);
    }
  }

  Future<void> updateItemDescription(
    String listId,
    String itemId,
    String? description, {
    String? authToken,
  }) async {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = _lists[listIndex];
      final updatedItems = list.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(description: description);
        }
        return item;
      }).toList();
      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      _lists[listIndex] = updatedList;
      await _persistLists();
      notifyListeners();
      await _syncListItemsToBackend(list: updatedList, authToken: authToken);
    }
  }

  Future<void> updateItemUnitPrice(
    String listId,
    String itemId,
    double? unitPrice, {
    String? authToken,
  }) async {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = _lists[listIndex];
      final updatedItems = list.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(unitPrice: unitPrice);
        }
        return item;
      }).toList();
      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      _lists[listIndex] = updatedList;
      await _persistLists();
      notifyListeners();
      await _syncListItemsToBackend(list: updatedList, authToken: authToken);
    }
  }

  Future<void> clearCheckedItems(String listId, {String? authToken}) async {
    final index = _lists.indexWhere((l) => l.id == listId);
    if (index != -1) {
      final list = _lists[index];
      final updatedItems = list.items.where((i) => !i.isChecked).toList();
      final updatedList = list.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      _lists[index] = updatedList;
      await _persistLists();
      notifyListeners();
      await _syncListItemsToBackend(list: updatedList, authToken: authToken);
    }
  }

  Future<void> clearAll() async {
    _lists.clear();
    _isLoading = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.shoppingListsKey);
    } catch (_) {
      // Ignore persistence errors
    }
    notifyListeners();
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
            description:
                'Full cream, not skimmed. Check expiry date - at least 5 days',
            quantity: 2,
            unit: 'liters',
            linkedProduct: sampleProducts.firstWhere(
              (p) => p.name.contains('Milk'),
              orElse: () => sampleProducts.first,
            ),
          ),
          ShoppingListItem(
            id: '2',
            name: 'Brown Bread',
            description: 'Whole wheat, soft texture. Not the seeded one',
            quantity: 1,
            unit: 'loaf',
            linkedProduct: sampleProducts.firstWhere(
              (p) => p.name.contains('Bread'),
              orElse: () => sampleProducts.first,
            ),
          ),
          ShoppingListItem(
            id: '3',
            name: 'Eggs',
            description: 'Large size, brown eggs preferred',
            quantity: 1,
            unit: 'tray',
            linkedProduct: sampleProducts.firstWhere(
              (p) => p.name.contains('Egg'),
              orElse: () => sampleProducts.first,
            ),
          ),
          ShoppingListItem(
            id: '4',
            name: 'Tomatoes',
            description: 'Firm, slightly ripe. Not too soft',
            budgetAmount: 3000,
            quantity: 1,
            linkedProduct: sampleProducts.firstWhere(
              (p) => p.name.contains('Tomato'),
              orElse: () => sampleProducts.first,
            ),
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
            linkedProduct: sampleProducts.firstWhere(
              (p) => p.name.contains('Chicken'),
              orElse: () => sampleProducts.first,
            ),
          ),
          ShoppingListItem(
            id: '6',
            name: 'Beef Steak',
            description: 'Well-marbled, ribeye or sirloin cut. About 2cm thick',
            budgetAmount: 25000,
            quantity: 1,
            linkedProduct: sampleProducts.firstWhere(
              (p) => p.name.contains('Beef'),
              orElse: () => sampleProducts.first,
            ),
          ),
          ShoppingListItem(
            id: '7',
            name: 'Onions',
            description: 'Red onions, medium size',
            quantity: 4,
            unit: 'pieces',
            linkedProduct: sampleProducts.firstWhere(
              (p) => p.name.contains('Onion'),
              orElse: () => sampleProducts.first,
            ),
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
            description:
                'Ripe, ready to eat. Should yield slightly to gentle pressure',
            quantity: 4,
            unit: 'pieces',
            linkedProduct: sampleProducts.firstWhere(
              (p) => p.name.contains('Avocado'),
              orElse: () => sampleProducts.first,
            ),
          ),
          ShoppingListItem(
            id: '9',
            name: 'Spinach',
            description: 'Fresh leaves, bright green. No wilting or yellowing',
            quantity: 2,
            unit: 'bunches',
            linkedProduct: sampleProducts.firstWhere(
              (p) => p.name.contains('Spinach'),
              orElse: () => sampleProducts.first,
            ),
          ),
        ],
        createdAt: DateTime.now(),
      ),
    ];
  }

  void linkProductToItem(String listId, String itemId, Product product) {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex < 0) return;

    final list = _lists[listIndex];
    final itemIndex = list.items.indexWhere((i) => i.id == itemId);
    if (itemIndex < 0) return;

    final updatedItem = list.items[itemIndex].copyWith(linkedProduct: product);
    final updatedItems = List<ShoppingListItem>.from(list.items);
    updatedItems[itemIndex] = updatedItem;
    _lists[listIndex] = list.copyWith(items: updatedItems);

    _persistLists();
    notifyListeners();
  }
}
