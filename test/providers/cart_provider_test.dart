import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lipa_cart/providers/cart_provider.dart';
import 'package:lipa_cart/models/product.dart';

Product _makeProduct({
  String id = 'p1',
  String name = 'Bananas',
  double price = 5000,
  double minQuantity = 1,
  double maxQuantity = 100,
}) {
  return Product(
    id: id,
    name: name,
    description: 'Test product',
    image: 'https://example.com/img.png',
    price: price,
    unit: 'bunch',
    categoryId: 'cat1',
    categoryName: 'Fruits',
    minQuantity: minQuantity,
    maxQuantity: maxQuantity,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CartProvider add/remove', () {
    test('addToCart adds new item', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct());

      expect(cart.items.length, 1);
      expect(cart.items.first.product.name, 'Bananas');
      expect(cart.items.first.quantity, 1);
    });

    test('addToCart increments existing item quantity', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1'));
      cart.addToCart(_makeProduct(id: 'p1'));

      expect(cart.items.length, 1);
      expect(cart.items.first.quantity, 2);
    });

    test('addToCart with custom quantity', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(), quantity: 5);

      expect(cart.items.first.quantity, 5);
    });

    test('removeFromCart removes item', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1'));
      cart.addToCart(_makeProduct(id: 'p2', name: 'Apples'));

      cart.removeFromCart('p1');

      expect(cart.items.length, 1);
      expect(cart.items.first.product.name, 'Apples');
    });
  });

  group('CartProvider quantity management', () {
    test('incrementQuantity increases by 1', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1'), quantity: 3);
      cart.incrementQuantity('p1');

      expect(cart.items.first.quantity, 4);
    });

    test('incrementQuantity respects maxQuantity', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1', maxQuantity: 3), quantity: 3);
      cart.incrementQuantity('p1');

      expect(cart.items.first.quantity, 3); // didn't exceed max
    });

    test('decrementQuantity decreases by 1', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1'), quantity: 3);
      cart.decrementQuantity('p1');

      expect(cart.items.first.quantity, 2);
    });

    test('decrementQuantity removes item at minQuantity', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1', minQuantity: 1), quantity: 1);
      cart.decrementQuantity('p1');

      expect(cart.items, isEmpty);
    });

    test('updateQuantity sets exact value', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1'));
      cart.updateQuantity('p1', 7);

      expect(cart.items.first.quantity, 7);
    });

    test('updateQuantity with 0 removes item', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1'));
      cart.updateQuantity('p1', 0);

      expect(cart.items, isEmpty);
    });
  });

  group('CartProvider totals', () {
    test('subtotal sums item totals', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1', price: 3000), quantity: 2);
      cart.addToCart(_makeProduct(id: 'p2', price: 5000), quantity: 1);

      expect(cart.subtotal, 11000); // 6000 + 5000
    });

    test('serviceFee is 5% of subtotal', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1', price: 10000), quantity: 1);

      expect(cart.serviceFee, 500); // 10000 * 0.05
    });

    test('deliveryFee is constant base', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cart.deliveryFee, 3000);
    });

    test('isEmpty / isNotEmpty', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cart.isEmpty, true);
      expect(cart.isNotEmpty, false);

      cart.addToCart(_makeProduct());

      expect(cart.isEmpty, false);
      expect(cart.isNotEmpty, true);
    });
  });

  group('CartProvider clearCart', () {
    test('clearCart empties items', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1'));
      cart.addToCart(_makeProduct(id: 'p2', name: 'Apples'));

      cart.clearCart();

      expect(cart.items, isEmpty);
      expect(cart.subtotal, 0);
    });
  });

  group('CartProvider.isInCart / getCartItem', () {
    test('isInCart returns true for items in cart', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1'));

      expect(cart.isInCart('p1'), true);
      expect(cart.isInCart('p2'), false);
    });

    test('getCartItem returns matching item', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1'));

      expect(cart.getCartItem('p1'), isNotNull);
      expect(cart.getCartItem('p2'), isNull);
    });
  });

  group('CartProvider.updateSpecialInstructions', () {
    test('sets instructions on item', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      cart.addToCart(_makeProduct(id: 'p1'));
      cart.updateSpecialInstructions('p1', 'Pick ripe ones');

      expect(cart.items.first.specialInstructions, 'Pick ripe ones');
    });
  });
}
