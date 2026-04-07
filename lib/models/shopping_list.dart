import 'product.dart';

class ShoppingListItem {
  static const Object _unset = Object();

  final String id;
  final String name;
  final String? description; // Personal notes/preferences for the item
  final int quantity;
  final String? unit;
  final double? unitPrice; // Expected price per unit (UGX)
  final double? budgetAmount; // Budget in UGX - "Give me 5000 worth"
  final Product? linkedProduct; // Optional link to actual product
  final bool isChecked;

  ShoppingListItem({
    required this.id,
    required this.name,
    this.description,
    this.quantity = 1,
    this.unit,
    this.unitPrice,
    this.budgetAmount,
    this.linkedProduct,
    this.isChecked = false,
  });

  ShoppingListItem copyWith({
    String? id,
    String? name,
    Object? description = _unset,
    int? quantity,
    Object? unit = _unset,
    Object? unitPrice = _unset,
    Object? budgetAmount = _unset,
    Object? linkedProduct = _unset,
    bool? isChecked,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      quantity: quantity ?? this.quantity,
      unit: identical(unit, _unset) ? this.unit : unit as String?,
      unitPrice: identical(unitPrice, _unset)
          ? this.unitPrice
          : unitPrice as double?,
      budgetAmount: identical(budgetAmount, _unset)
          ? this.budgetAmount
          : budgetAmount as double?,
      linkedProduct: identical(linkedProduct, _unset)
          ? this.linkedProduct
          : linkedProduct as Product?,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  factory ShoppingListItem.fromStrapi(Map<String, dynamic> json) {
    Product? linkedProduct;
    final attributes = (json['attributes'] as Map<String, dynamic>?) ?? json;
    final productData = attributes['product'];
    if (productData is Map<String, dynamic>) {
      final resolvedProduct =
          (productData['data'] as Map<String, dynamic>?) ?? productData;
      linkedProduct = Product.fromStrapi(resolvedProduct);
    }

    return ShoppingListItem(
      id: (json['id'] ?? '').toString(),
      name: attributes['name'] as String? ?? '',
      description: attributes['notes'] as String?,
      quantity: (attributes['quantity'] as num?)?.toInt() ?? 1,
      unit: attributes['unit'] as String?,
      unitPrice:
          (attributes['unit_price'] as num?)?.toDouble() ??
          (attributes['expected_price'] as num?)?.toDouble(),
      budgetAmount: (attributes['budget_amount'] as num?)?.toDouble(),
      linkedProduct: linkedProduct,
    );
  }

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    Product? linkedProduct;
    final linkedProductJson = json['linkedProduct'] as Map<String, dynamic>?;
    if (linkedProductJson != null) {
      linkedProduct = Product.fromJson(linkedProductJson);
    }

    return ShoppingListItem(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble(),
      linkedProduct: linkedProduct,
      isChecked: json['isChecked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'budgetAmount': budgetAmount,
      'linkedProductId': linkedProduct?.id,
      'linkedProduct': linkedProduct?.toJson(),
      'isChecked': isChecked,
    };
  }
}

class ShoppingList {
  final String id;
  final String name;
  final String? description;
  final String? emoji; // Visual emoji icon for the list
  final String color; // Hex color for visual distinction
  final List<ShoppingListItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ShoppingList({
    required this.id,
    required this.name,
    this.description,
    this.emoji = '🛒',
    this.color = '#15874B',
    this.items = const [],
    required this.createdAt,
    this.updatedAt,
  });

  int get totalItems => items.length;
  int get checkedItems => items.where((i) => i.isChecked).length;
  double get progress => totalItems > 0 ? checkedItems / totalItems : 0;
  bool get isComplete => totalItems > 0 && checkedItems == totalItems;

  // Get items that have linked products (can be added to cart)
  List<ShoppingListItem> get purchasableItems =>
      items.where((i) => i.linkedProduct != null && !i.isChecked).toList();

  // Get items that don't have linked products yet
  List<ShoppingListItem> get itemsWithoutProducts =>
      items.where((i) => i.linkedProduct == null && !i.isChecked).toList();

  ShoppingList copyWith({
    String? id,
    String? name,
    String? description,
    String? emoji,
    String? color,
    List<ShoppingListItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ShoppingList.fromStrapi(Map<String, dynamic> json) {
    final attributes = (json['attributes'] as Map<String, dynamic>?) ?? json;
    final itemsData = attributes['items'] as List<dynamic>? ?? [];
    final items = itemsData
        .map(
          (item) => ShoppingListItem.fromStrapi(item as Map<String, dynamic>),
        )
        .toList();

    return ShoppingList(
      id: (json['documentId'] ?? json['id']).toString(),
      name: attributes['name'] as String? ?? '',
      description: attributes['description'] as String?,
      emoji: attributes['emoji'] as String?,
      color: attributes['color'] as String? ?? '#15874B',
      items: items,
      createdAt:
          DateTime.tryParse(attributes['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(attributes['updatedAt'] as String? ?? ''),
    );
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      emoji: json['emoji'] as String? ?? '🛒',
      color: json['color'] as String? ?? '#15874B',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => ShoppingListItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emoji': emoji,
      'color': color,
      'items': items.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
