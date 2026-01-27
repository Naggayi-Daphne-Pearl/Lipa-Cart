import 'product.dart';

class ShoppingListItem {
  final String id;
  final String name;
  final String? description; // Personal notes/preferences for the item
  final int quantity;
  final String? unit;
  final double? budgetAmount; // Budget in UGX - "Give me 5000 worth"
  final Product? linkedProduct; // Optional link to actual product
  final bool isChecked;

  ShoppingListItem({
    required this.id,
    required this.name,
    this.description,
    this.quantity = 1,
    this.unit,
    this.budgetAmount,
    this.linkedProduct,
    this.isChecked = false,
  });

  ShoppingListItem copyWith({
    String? id,
    String? name,
    String? description,
    int? quantity,
    String? unit,
    double? budgetAmount,
    Product? linkedProduct,
    bool? isChecked,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      linkedProduct: linkedProduct ?? this.linkedProduct,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  factory ShoppingListItem.fromStrapi(Map<String, dynamic> json) {
    Product? linkedProduct;
    final productData = json['product'];
    if (productData != null && productData is Map<String, dynamic>) {
      linkedProduct = Product.fromStrapi(productData);
    }

    return ShoppingListItem(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      description: json['notes'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String?,
      budgetAmount: (json['budget_amount'] as num?)?.toDouble(),
      linkedProduct: linkedProduct,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'budgetAmount': budgetAmount,
      'linkedProductId': linkedProduct?.id,
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
    final itemsData = json['items'] as List<dynamic>? ?? [];
    final items = itemsData
        .map((item) => ShoppingListItem.fromStrapi(item as Map<String, dynamic>))
        .toList();

    return ShoppingList(
      id: (json['documentId'] ?? json['id']).toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      emoji: json['emoji'] as String?,
      color: json['color'] as String? ?? '#15874B',
      items: items,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
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
