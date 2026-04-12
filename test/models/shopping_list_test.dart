import 'package:flutter_test/flutter_test.dart';
import 'package:lipa_cart/models/shopping_list.dart';

void main() {
  group('ShoppingListItem model', () {
    test('fromStrapi parses is_checked flag', () {
      final item = ShoppingListItem.fromStrapi({
        'id': 10,
        'name': 'Tomatoes',
        'quantity': 2,
        'unit': 'kg',
        'is_checked': true,
      });

      expect(item.id, '10');
      expect(item.name, 'Tomatoes');
      expect(item.isChecked, isTrue);
    });

    test('fromStrapi defaults is_checked to false', () {
      final item = ShoppingListItem.fromStrapi({
        'id': 11,
        'name': 'Onions',
        'quantity': 1,
      });

      expect(item.isChecked, isFalse);
    });
  });
}
