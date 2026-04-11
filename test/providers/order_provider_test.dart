import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lipa_cart/providers/order_provider.dart';
import 'package:lipa_cart/models/order.dart';
import 'package:lipa_cart/models/cart_item.dart';
import 'package:lipa_cart/models/product.dart';
import 'package:lipa_cart/models/user.dart';

Product _makeProduct({String id = 'p1', double price = 5000}) {
  return Product(
    id: id,
    name: 'Bananas',
    description: 'Fresh bananas',
    image: 'https://example.com/img.png',
    price: price,
    unit: 'bunch',
    categoryId: 'cat1',
    categoryName: 'Fruits',
  );
}

Order _makeOrder({
  String id = 'order-1',
  OrderStatus status = OrderStatus.pending,
}) {
  return Order(
    id: id,
    orderNumber: 'LC12345678',
    items: [
      CartItem(id: 'ci-1', product: _makeProduct(), quantity: 2),
    ],
    deliveryAddress: Address(
      id: 'a1',
      label: 'Home',
      fullAddress: '123 Street',
      latitude: 0,
      longitude: 0,
    ),
    subtotal: 10000,
    serviceFee: 500,
    deliveryFee: 3000,
    total: 13500,
    status: status,
    createdAt: DateTime(2026, 4, 10),
    paymentMethod: PaymentMethod.mobileMoney,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OrderProvider.activeOrders', () {
    test('excludes delivered, cancelled, refunded', () async {
      final provider = OrderProvider();
      // Wait for bootstrap
      await Future.delayed(const Duration(milliseconds: 50));

      final orders = [
        _makeOrder(id: '1', status: OrderStatus.pending),
        _makeOrder(id: '2', status: OrderStatus.delivered),
        _makeOrder(id: '3', status: OrderStatus.cancelled),
        _makeOrder(id: '4', status: OrderStatus.shopping),
        _makeOrder(id: '5', status: OrderStatus.refunded),
      ];

      provider.syncOrdersFromService(orders);

      expect(provider.activeOrders.length, 2);
      expect(
        provider.activeOrders.map((o) => o.id).toList(),
        containsAll(['1', '4']),
      );
    });
  });

  group('OrderProvider.pastOrders', () {
    test('includes delivered, cancelled, refunded', () async {
      final provider = OrderProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final orders = [
        _makeOrder(id: '1', status: OrderStatus.pending),
        _makeOrder(id: '2', status: OrderStatus.delivered),
        _makeOrder(id: '3', status: OrderStatus.cancelled),
        _makeOrder(id: '4', status: OrderStatus.refunded),
      ];

      provider.syncOrdersFromService(orders);

      expect(provider.pastOrders.length, 3);
      expect(
        provider.pastOrders.map((o) => o.id).toList(),
        containsAll(['2', '3', '4']),
      );
    });
  });

  group('OrderProvider.cancelOrder', () {
    test('updates order status to cancelled', () async {
      final provider = OrderProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      provider.syncOrdersFromService([
        _makeOrder(id: 'order-1', status: OrderStatus.shopping),
      ]);

      provider.cancelOrder('order-1', 'Changed my mind');

      expect(provider.orders.first.status, OrderStatus.cancelled);
      expect(provider.orders.first.cancellationReason, 'Changed my mind');
    });

    test('no-op for non-existent order', () async {
      final provider = OrderProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      provider.syncOrdersFromService([
        _makeOrder(id: 'order-1'),
      ]);

      provider.cancelOrder('nonexistent', 'Reason');
      expect(provider.orders.first.status, OrderStatus.pending);
    });
  });

  group('OrderProvider.createOrder', () {
    test('generates order number starting with LC', () async {
      final provider = OrderProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final order = await provider.createOrder(
        items: [CartItem(id: 'ci-1', product: _makeProduct(), quantity: 1)],
        deliveryAddress: Address(
          id: 'a1',
          label: 'Home',
          fullAddress: '123 St',
          latitude: 0,
          longitude: 0,
        ),
        subtotal: 5000,
        serviceFee: 250,
        deliveryFee: 3000,
        paymentMethod: PaymentMethod.mobileMoney,
      );

      expect(order, isNotNull);
      expect(order!.orderNumber, startsWith('LC'));
      expect(order.status, OrderStatus.pending);
      expect(provider.orders.length, 1);
    });
  });

  group('OrderProvider.getOrderById', () {
    test('returns matching order', () async {
      final provider = OrderProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      provider.syncOrdersFromService([
        _makeOrder(id: 'order-1'),
        _makeOrder(id: 'order-2'),
      ]);

      final found = provider.getOrderById('order-2');
      expect(found?.id, 'order-2');
    });

    test('returns null for missing order', () async {
      final provider = OrderProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.getOrderById('missing'), isNull);
    });
  });

  group('OrderProvider.clearAll', () {
    test('clears all orders and current order', () async {
      final provider = OrderProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      provider.syncOrdersFromService([_makeOrder()]);
      provider.setCurrentOrder(_makeOrder());

      expect(provider.orders.isNotEmpty, true);
      expect(provider.currentOrder, isNotNull);

      await provider.clearAll();

      expect(provider.orders, isEmpty);
      expect(provider.currentOrder, isNull);
    });
  });
}
