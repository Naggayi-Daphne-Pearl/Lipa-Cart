import 'package:flutter_test/flutter_test.dart';
import 'package:lipa_cart/models/cart_item.dart';
import 'package:lipa_cart/models/product.dart';

Product _makeProduct({
  String id = 'p1',
  String name = 'Bananas',
  double price = 5000,
  String unit = 'bunch',
}) {
  return Product(
    id: id,
    name: name,
    description: 'Test product',
    image: 'https://example.com/img.png',
    price: price,
    unit: unit,
    categoryId: 'cat1',
    categoryName: 'Fruits',
  );
}

void main() {
  group('CartItem', () {
    test('totalPrice multiplies price by quantity', () {
      final item = CartItem(
        id: '1',
        product: _makeProduct(price: 3000),
        quantity: 2,
      );
      expect(item.totalPrice, 6000);
    });

    test('totalPrice handles fractional quantities', () {
      final item = CartItem(
        id: '1',
        product: _makeProduct(price: 10000),
        quantity: 0.5,
      );
      expect(item.totalPrice, 5000);
    });
  });

  group('CartItem serialization', () {
    test('fromJson / toJson roundtrip preserves all fields', () {
      final original = CartItem(
        id: 'item-1',
        product: _makeProduct(),
        quantity: 3,
        specialInstructions: 'Pick ripe ones',
        found: true,
        actualPrice: 5500,
        shopperNotes: 'Got the big bunch',
        substitutionApproved: true,
        isSubstituted: true,
        substituteName: 'Plantains',
        substitutePrice: 4000,
        substitutePhotoUrl: 'https://example.com/photo.jpg',
        substituteForItemId: 'item-0',
      );

      final json = original.toJson();
      final restored = CartItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.product.name, original.product.name);
      expect(restored.quantity, original.quantity);
      expect(restored.specialInstructions, original.specialInstructions);
      expect(restored.found, original.found);
      expect(restored.actualPrice, original.actualPrice);
      expect(restored.shopperNotes, original.shopperNotes);
      expect(restored.substitutionApproved, original.substitutionApproved);
      expect(restored.isSubstituted, original.isSubstituted);
      expect(restored.substituteName, original.substituteName);
      expect(restored.substitutePrice, original.substitutePrice);
      expect(restored.substitutePhotoUrl, original.substitutePhotoUrl);
      expect(restored.substituteForItemId, original.substituteForItemId);
    });

    test('fromJson handles minimal fields', () {
      final json = {
        'id': 'item-2',
        'product': _makeProduct().toJson(),
        'quantity': 1,
      };

      final item = CartItem.fromJson(json);
      expect(item.id, 'item-2');
      expect(item.quantity, 1);
      expect(item.found, isNull);
      expect(item.actualPrice, isNull);
      expect(item.substituteName, isNull);
      expect(item.substitutePrice, isNull);
      expect(item.substitutePhotoUrl, isNull);
      expect(item.isSubstituted, isNull);
    });

    test('toJson omits null optional fields', () {
      final item = CartItem(
        id: 'item-3',
        product: _makeProduct(),
        quantity: 1,
      );

      final json = item.toJson();
      expect(json.containsKey('found'), false);
      expect(json.containsKey('actualPrice'), false);
      expect(json.containsKey('shopperNotes'), false);
      expect(json.containsKey('substitutionApproved'), false);
      expect(json.containsKey('isSubstituted'), false);
      expect(json.containsKey('substituteName'), false);
      expect(json.containsKey('substitutePrice'), false);
      expect(json.containsKey('substitutePhotoUrl'), false);
      expect(json.containsKey('substituteForItemId'), false);
    });
  });

  group('CartItem legacy substitution parsing', () {
    test('fromJson populates substituteName from SUBSTITUTE: notes', () {
      final json = {
        'id': 'item-4',
        'product': _makeProduct().toJson(),
        'quantity': 1,
        'shopperNotes': 'SUBSTITUTE: Organic Milk (UGX 8000)',
      };

      final item = CartItem.fromJson(json);
      expect(item.substituteName, 'Organic Milk');
      expect(item.substitutePrice, 8000);
    });

    test('fromJson parses substitute name without price', () {
      final json = {
        'id': 'item-5',
        'product': _makeProduct().toJson(),
        'quantity': 1,
        'shopperNotes': 'SUBSTITUTE: Brown Rice',
      };

      final item = CartItem.fromJson(json);
      expect(item.substituteName, 'Brown Rice');
      expect(item.substitutePrice, isNull);
    });

    test('fromJson structured fields take priority over notes parsing', () {
      final json = {
        'id': 'item-6',
        'product': _makeProduct().toJson(),
        'quantity': 1,
        'shopperNotes': 'SUBSTITUTE: Old Name (UGX 1000)',
        'substituteName': 'Correct Name',
        'substitutePrice': 2000,
      };

      final item = CartItem.fromJson(json);
      expect(item.substituteName, 'Correct Name');
      expect(item.substitutePrice, 2000);
    });

    test('fromJson does not parse notes without SUBSTITUTE: prefix', () {
      final json = {
        'id': 'item-7',
        'product': _makeProduct().toJson(),
        'quantity': 1,
        'shopperNotes': 'Got the bigger size',
      };

      final item = CartItem.fromJson(json);
      expect(item.substituteName, isNull);
      expect(item.substitutePrice, isNull);
    });

    test('parseSubstituteNameFromNotes returns null for null input', () {
      expect(CartItem.parseSubstituteNameFromNotes(null), isNull);
    });

    test('parseSubstitutePriceFromNotes parses comma-separated amounts', () {
      expect(
        CartItem.parseSubstitutePriceFromNotes(
          'SUBSTITUTE: Cheese (UGX 15,000)',
        ),
        15000,
      );
    });
  });

  group('CartItem.copyWith', () {
    test('creates modified copy leaving unchanged fields', () {
      final item = CartItem(
        id: 'item-8',
        product: _makeProduct(),
        quantity: 2,
        found: false,
      );

      final updated = item.copyWith(found: true, actualPrice: 6000);
      expect(updated.found, true);
      expect(updated.actualPrice, 6000);
      expect(updated.id, 'item-8');
      expect(updated.quantity, 2);
    });

    test('copyWith can set substitution fields', () {
      final item = CartItem(
        id: 'item-9',
        product: _makeProduct(),
        quantity: 1,
      );

      final updated = item.copyWith(
        isSubstituted: true,
        substituteName: 'Alt Item',
        substitutePrice: 7000,
        substitutePhotoUrl: 'https://example.com/alt.jpg',
        substituteForItemId: 'item-0',
      );

      expect(updated.isSubstituted, true);
      expect(updated.substituteName, 'Alt Item');
      expect(updated.substitutePrice, 7000);
      expect(updated.substitutePhotoUrl, 'https://example.com/alt.jpg');
      expect(updated.substituteForItemId, 'item-0');
    });
  });

  group('CartItem.hasSubstituteSuggestion', () {
    test('returns true when substituted and pending approval', () {
      final item = CartItem(
        id: '1',
        product: _makeProduct(),
        quantity: 1,
        isSubstituted: true,
        substituteName: 'Alt',
        substitutionApproved: null,
      );
      expect(item.hasSubstituteSuggestion, true);
    });

    test('returns false when substitution already approved', () {
      final item = CartItem(
        id: '1',
        product: _makeProduct(),
        quantity: 1,
        isSubstituted: true,
        substituteName: 'Alt',
        substitutionApproved: true,
      );
      expect(item.hasSubstituteSuggestion, false);
    });

    test('returns false when no substitution', () {
      final item = CartItem(
        id: '1',
        product: _makeProduct(),
        quantity: 1,
      );
      expect(item.hasSubstituteSuggestion, false);
    });
  });
}
