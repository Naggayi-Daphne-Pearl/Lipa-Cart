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
  bool? isSubstituted;
  String? substituteName;
  double? substitutePrice;
  String? substitutePhotoUrl;
  String? substituteForItemId;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.specialInstructions,
    this.found,
    this.actualPrice,
    this.shopperNotes,
    this.substitutionApproved,
    this.isSubstituted,
    this.substituteName,
    this.substitutePrice,
    this.substitutePhotoUrl,
    this.substituteForItemId,
  });

  /// Parse substitute name from legacy "SUBSTITUTE: Name (UGX Price)" notes.
  static String? parseSubstituteNameFromNotes(String? notes) {
    if (notes == null || !notes.startsWith('SUBSTITUTE:')) return null;
    return notes.replaceFirst('SUBSTITUTE: ', '').replaceFirst(RegExp(r'\s*\(UGX\s*[\d,]+\)\s*$'), '').trim();
  }

  /// Parse substitute price from legacy "SUBSTITUTE: ... (UGX Price)" notes.
  static double? parseSubstitutePriceFromNotes(String? notes) {
    if (notes == null || !notes.startsWith('SUBSTITUTE:')) return null;
    final match = RegExp(r'UGX\s*([\d,]+)').firstMatch(notes);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', ''));
  }

  /// Whether this item has a pending substitute suggestion.
  bool get hasSubstituteSuggestion =>
      (isSubstituted == true || substituteName != null) &&
      substitutionApproved == null;

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
    bool? isSubstituted,
    String? substituteName,
    double? substitutePrice,
    String? substitutePhotoUrl,
    String? substituteForItemId,
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
      isSubstituted: isSubstituted ?? this.isSubstituted,
      substituteName: substituteName ?? this.substituteName,
      substitutePrice: substitutePrice ?? this.substitutePrice,
      substitutePhotoUrl: substitutePhotoUrl ?? this.substitutePhotoUrl,
      substituteForItemId: substituteForItemId ?? this.substituteForItemId,
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
      if (isSubstituted != null) 'isSubstituted': isSubstituted,
      if (substituteName != null) 'substituteName': substituteName,
      if (substitutePrice != null) 'substitutePrice': substitutePrice,
      if (substitutePhotoUrl != null) 'substitutePhotoUrl': substitutePhotoUrl,
      if (substituteForItemId != null)
        'substituteForItemId': substituteForItemId,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final shopperNotes = json['shopperNotes'] as String?;

    // Structured substitution fields take priority over legacy notes parsing
    final structuredName = json['substituteName'] as String?;
    final structuredPrice = (json['substitutePrice'] as num?)?.toDouble();
    final substituteName = structuredName ?? parseSubstituteNameFromNotes(shopperNotes);
    final substitutePrice = structuredPrice ?? parseSubstitutePriceFromNotes(shopperNotes);

    return CartItem(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toDouble(),
      specialInstructions: json['specialInstructions'] as String?,
      found: json['found'] as bool?,
      actualPrice: (json['actualPrice'] as num?)?.toDouble(),
      shopperNotes: shopperNotes,
      substitutionApproved: json['substitutionApproved'] as bool?,
      isSubstituted: json['isSubstituted'] as bool?,
      substituteName: substituteName,
      substitutePrice: substitutePrice,
      substitutePhotoUrl: json['substitutePhotoUrl'] as String?,
      substituteForItemId: json['substituteForItemId'] as String?,
    );
  }
}
