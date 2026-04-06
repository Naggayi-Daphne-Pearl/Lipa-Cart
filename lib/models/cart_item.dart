import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  double quantity;
  String? specialInstructions;
  bool? found;
  double? actualPrice;
  String? shopperNotes;
  bool? substitutionApproved;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.specialInstructions,
    this.found,
    this.actualPrice,
    this.shopperNotes,
    this.substitutionApproved,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    String? id,
    Product? product,
    double? quantity,
    String? specialInstructions,
    bool? found,
    double? actualPrice,
    String? shopperNotes,
    bool? substitutionApproved,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      found: found ?? this.found,
      actualPrice: actualPrice ?? this.actualPrice,
      shopperNotes: shopperNotes ?? this.shopperNotes,
      substitutionApproved: substitutionApproved ?? this.substitutionApproved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'specialInstructions': specialInstructions,
      if (found != null) 'found': found,
      if (actualPrice != null) 'actualPrice': actualPrice,
      if (shopperNotes != null) 'shopperNotes': shopperNotes,
      if (substitutionApproved != null)
        'substitutionApproved': substitutionApproved,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toDouble(),
      specialInstructions: json['specialInstructions'] as String?,
      found: json['found'] as bool?,
      actualPrice: (json['actualPrice'] as num?)?.toDouble(),
      shopperNotes: json['shopperNotes'] as String?,
      substitutionApproved: json['substitutionApproved'] as bool?,
    );
  }
}
