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
  String? _activeUserId;

  ShoppingListProvider();

  List<ShoppingList> get lists => _lists;
  bool get isLoading => _isLoading;

  String _storageKeyForUser(String? userId) {
    if (userId == null || userId.isEmpty) {
      return AppConstants.shoppingListsKey;
    }
    return '${AppConstants.shoppingListsKey}_$userId';
  }

  Future<void> restoreListsForUser(String? userId) async {
    _activeUserId = userId;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = _storageKeyForUser(userId);
      var raw = prefs.getString(storageKey);

      if ((raw == null || raw.isEmpty) && userId != null && userId.isNotEmpty) {
        raw = prefs.getString(AppConstants.shoppingListsKey);
        if (raw != null && raw.isNotEmpty) {
          await prefs.setString(storageKey, raw);
          await prefs.remove(AppConstants.shoppingListsKey);
        }
      }

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
      await prefs.setString(_storageKeyForUser(_activeUserId), payload);
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

  Future<void> loadLists({String? authToken, String? userId}) async {
    if (_activeUserId != userId) {
      _lists = [];
      await restoreListsForUser(userId);
    }

    _isLoading = true;
    notifyListeners();

    if (authToken == null || authToken.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _lists = await StrapiService.getShoppingLists(authToken: authToken);
      await _persistLists();
    } catch (e) {
      debugPrint('Shopping list sync failed, keeping cached data: $e');
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

  bool canCreateList({required bool isPremium}) {
    if (isPremium) return true;
    return _lists.length < freeTierListLimit;
  }

  Future<bool> createList({
    required String name,
    String? description,
    String emoji = '🛒',
    String color = '#15874B',
    List<ShoppingListItem>? items,
    bool isPremium = false,
    String? authToken,
  }) async {
    if (!canCreateList(isPremium: isPremium)) {
      return false;
    }

    if (authToken == null || authToken.isEmpty) {
      throw Exception('Authentication required to create shopping lists');
    }

    try {
      debugPrint(
        'DEBUG: Creating shopping list - name: $name, authToken: ${authToken.substring(0, 20)}...',
      );
      final newList = await StrapiService.createShoppingList(
        name: name,
        description: description,
        emoji: emoji,
        color: color,
        items: items,
        authToken: authToken,
      );

      // Some create responses can omit populated component items; keep
      // user-provided template items immediately to avoid empty-list flicker.
      final hydratedList =
          (newList.items.isNotEmpty || items == null || items.isEmpty)
          ? newList
          : newList.copyWith(items: items);

      debugPrint(
        'DEBUG: Shopping list created successfully - ID: ${newList.id}',
      );
      _lists.insert(0, hydratedList);
      await _persistLists();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ERROR: Failed to create shopping list: $e');
      rethrow;
    }
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
    final incomingProductId =
        item.linkedProduct?.strapiId ?? item.linkedProduct?.id;

    final duplicateIndex = list.items.indexWhere((existing) {
      final existingName = existing.name.trim().toLowerCase();
      final existingProductId =
          existing.linkedProduct?.strapiId ?? existing.linkedProduct?.id;
      final sameProduct = existingProductId == incomingProductId;
      final bothUnlinked =
          existingProductId == null && incomingProductId == null;
      return existingName == normalizedName && (sameProduct || bothUnlinked);
    });

    final bool mergedExisting;
    List<ShoppingListItem> updatedItems;

    if (duplicateIndex != -1) {
      mergedExisting = true;
      final existing = list.items[duplicateIndex];
      final mergedItem = existing.copyWith(
        quantity: existing.quantity + item.quantity,
        description:
            (existing.description == null ||
                existing.description!.trim().isEmpty)
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

  Future<void> updateItem(
    String listId,
    String itemId,
    ShoppingListItem updatedItem, {
    String? authToken,
  }) async {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = _lists[listIndex];
      final updatedItems = list.items.map((item) {
        if (item.id == itemId) {
          return updatedItem.copyWith(id: item.id);
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

  Future<void> clearAll({bool clearPersisted = true}) async {
    _lists.clear();
    _isLoading = false;
    try {
      if (clearPersisted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_storageKeyForUser(_activeUserId));
        if (_activeUserId == null || _activeUserId!.isEmpty) {
          await prefs.remove(AppConstants.shoppingListsKey);
        }
      }
    } catch (_) {
      // Ignore persistence errors
    }
    _activeUserId = null;
    notifyListeners();
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
