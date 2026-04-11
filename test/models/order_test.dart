import 'package:flutter_test/flutter_test.dart';
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

CartItem _makeCartItem({String id = 'ci-1', double quantity = 2}) {
  return CartItem(
    id: id,
    product: _makeProduct(),
    quantity: quantity,
  );
}

Order _makeOrder({
  OrderStatus status = OrderStatus.pending,
  List<CartItem>? items,
}) {
  return Order(
    id: 'order-1',
    documentId: 'doc-1',
    orderNumber: 'LC12345678',
    items: items ?? [_makeCartItem()],
    deliveryAddress: Address(
      id: 'addr-1',
      label: 'Home',
      fullAddress: 'Plot 42, Kampala Road',
      latitude: 0.347596,
      longitude: 32.582520,
    ),
    subtotal: 10000,
    serviceFee: 500,
    deliveryFee: 3000,
    total: 13500,
    status: status,
    createdAt: DateTime(2026, 4, 10, 14, 30),
    paymentMethod: PaymentMethod.mobileMoney,
  );
}

void main() {
  group('OrderStatus.displayName', () {
    test('all statuses have human-readable names', () {
      expect(OrderStatus.pending.displayName, 'Order Placed');
      expect(OrderStatus.paymentProcessing.displayName, 'Payment Processing');
      expect(OrderStatus.confirmed.displayName, 'Payment Confirmed');
      expect(OrderStatus.shopperAssigned.displayName, 'Shopper Assigned');
      expect(OrderStatus.shopping.displayName, 'Shopping in Progress');
      expect(OrderStatus.readyForDelivery.displayName, 'Ready for Delivery');
      expect(OrderStatus.riderAssigned.displayName, 'Rider Assigned');
      expect(OrderStatus.inTransit.displayName, 'On the Way');
      expect(OrderStatus.delivered.displayName, 'Delivered');
      expect(OrderStatus.cancelled.displayName, 'Cancelled');
      expect(OrderStatus.refunded.displayName, 'Refunded');
    });
  });

  group('OrderStatus.description', () {
    test('all statuses have descriptions', () {
      for (final status in OrderStatus.values) {
        expect(status.description, isNotEmpty);
      }
    });

    test('paymentProcessing has correct description', () {
      expect(
        OrderStatus.paymentProcessing.description,
        'Your payment is being processed',
      );
    });

    test('refunded has correct description', () {
      expect(
        OrderStatus.refunded.description,
        'Your order has been refunded',
      );
    });
  });

  group('OrderStatus.stepIndex', () {
    test('happy path statuses are in ascending order', () {
      final happyPath = [
        OrderStatus.pending,
        OrderStatus.confirmed,
        OrderStatus.shopperAssigned,
        OrderStatus.shopping,
        OrderStatus.readyForDelivery,
        OrderStatus.riderAssigned,
        OrderStatus.inTransit,
        OrderStatus.delivered,
      ];

      for (int i = 1; i < happyPath.length; i++) {
        expect(
          happyPath[i].stepIndex,
          greaterThan(happyPath[i - 1].stepIndex),
          reason:
              '${happyPath[i].name} should be after ${happyPath[i - 1].name}',
        );
      }
    });

    test('cancelled and refunded have negative stepIndex', () {
      expect(OrderStatus.cancelled.stepIndex, -1);
      expect(OrderStatus.refunded.stepIndex, -1);
    });

    test('paymentProcessing shares stepIndex with pending', () {
      expect(
        OrderStatus.paymentProcessing.stepIndex,
        OrderStatus.pending.stepIndex,
      );
    });
  });

  group('PaymentMethod', () {
    test('displayName returns user-facing labels', () {
      expect(PaymentMethod.mobileMoney.displayName, 'Mobile Money');
      expect(PaymentMethod.card.displayName, 'Card Payment');
      expect(PaymentMethod.cashOnDelivery.displayName, 'Cash on Delivery');
    });

    test('icon returns icon identifiers', () {
      expect(PaymentMethod.mobileMoney.icon, 'mobile');
      expect(PaymentMethod.card.icon, 'card');
      expect(PaymentMethod.cashOnDelivery.icon, 'cash');
    });
  });

  group('Order convenience getters', () {
    test('statusLabel delegates to displayName', () {
      final order = _makeOrder(status: OrderStatus.shopping);
      expect(order.statusLabel, 'Shopping in Progress');
    });

    test('isPending / isDelivered / isCancelled', () {
      expect(_makeOrder(status: OrderStatus.pending).isPending, true);
      expect(_makeOrder(status: OrderStatus.pending).isDelivered, false);
      expect(_makeOrder(status: OrderStatus.delivered).isDelivered, true);
      expect(_makeOrder(status: OrderStatus.cancelled).isCancelled, true);
    });

    test('itemCount sums quantities', () {
      final order = _makeOrder(
        items: [
          _makeCartItem(id: 'a', quantity: 3),
          _makeCartItem(id: 'b', quantity: 2),
        ],
      );
      expect(order.itemCount, 5);
    });

    test('itemCount falls back to items.length when quantities are zero', () {
      final order = _makeOrder(
        items: [
          _makeCartItem(id: 'a', quantity: 0),
          _makeCartItem(id: 'b', quantity: 0),
        ],
      );
      expect(order.itemCount, 2);
    });
  });

  group('Order serialization', () {
    test('fromJson / toJson roundtrip preserves core fields', () {
      final original = _makeOrder();
      final json = original.toJson();
      final restored = Order.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.orderNumber, original.orderNumber);
      expect(restored.items.length, original.items.length);
      expect(restored.deliveryAddress.label, original.deliveryAddress.label);
      expect(restored.subtotal, original.subtotal);
      expect(restored.serviceFee, original.serviceFee);
      expect(restored.deliveryFee, original.deliveryFee);
      expect(restored.total, original.total);
      expect(restored.status, original.status);
      expect(restored.paymentMethod, original.paymentMethod);
      expect(restored.isPaid, original.isPaid);
    });

    test('fromJson / toJson roundtrip preserves timestamps', () {
      final original = Order(
        id: 'order-ts',
        orderNumber: 'LC99999999',
        items: [_makeCartItem()],
        deliveryAddress: Address(
          id: 'a1',
          label: 'Home',
          fullAddress: '123 St',
          latitude: 0,
          longitude: 0,
        ),
        subtotal: 10000,
        serviceFee: 500,
        deliveryFee: 3000,
        total: 13500,
        status: OrderStatus.delivered,
        createdAt: DateTime(2026, 4, 10, 14, 30),
        paymentMethod: PaymentMethod.mobileMoney,
        paymentConfirmedAt: DateTime(2026, 4, 10, 14, 31),
        shopperAssignedAt: DateTime(2026, 4, 10, 14, 35),
        shoppingStartedAt: DateTime(2026, 4, 10, 14, 40),
        shoppingCompletedAt: DateTime(2026, 4, 10, 15, 0),
        riderAssignedAt: DateTime(2026, 4, 10, 15, 5),
        pickedUpAt: DateTime(2026, 4, 10, 15, 10),
        deliveredAt: DateTime(2026, 4, 10, 15, 30),
        cancelledAt: null,
      );

      final json = original.toJson();
      final restored = Order.fromJson(json);

      expect(restored.paymentConfirmedAt, original.paymentConfirmedAt);
      expect(restored.shopperAssignedAt, original.shopperAssignedAt);
      expect(restored.shoppingStartedAt, original.shoppingStartedAt);
      expect(restored.shoppingCompletedAt, original.shoppingCompletedAt);
      expect(restored.riderAssignedAt, original.riderAssignedAt);
      expect(restored.pickedUpAt, original.pickedUpAt);
      expect(restored.deliveredAt, original.deliveredAt);
      expect(restored.cancelledAt, isNull);
    });

    test('fromJson handles all status enum values', () {
      for (final status in OrderStatus.values) {
        final json = _makeOrder(status: status).toJson();
        final restored = Order.fromJson(json);
        expect(restored.status, status);
      }
    });

    test('fromJson defaults unknown status to pending', () {
      final json = _makeOrder().toJson();
      json['status'] = 'unknown_status';
      final restored = Order.fromJson(json);
      expect(restored.status, OrderStatus.pending);
    });

    test('fromJson defaults unknown paymentMethod to mobileMoney', () {
      final json = _makeOrder().toJson();
      json['paymentMethod'] = 'bitcoin';
      final restored = Order.fromJson(json);
      expect(restored.paymentMethod, PaymentMethod.mobileMoney);
    });
  });

  group('Order.copyWith', () {
    test('returns new order with updated fields', () {
      final order = _makeOrder();
      final updated = order.copyWith(
        status: OrderStatus.delivered,
        deliveredAt: DateTime(2026, 4, 10, 16, 0),
        paymentConfirmedAt: DateTime(2026, 4, 10, 14, 31),
      );

      expect(updated.status, OrderStatus.delivered);
      expect(updated.deliveredAt, isNotNull);
      expect(updated.paymentConfirmedAt, isNotNull);
      expect(updated.id, order.id);
      expect(updated.orderNumber, order.orderNumber);
      expect(updated.total, order.total);
    });

    test('copyWith with no arguments returns equivalent order', () {
      final order = _makeOrder();
      final copy = order.copyWith();
      expect(copy.id, order.id);
      expect(copy.status, order.status);
      expect(copy.total, order.total);
    });
  });
}
