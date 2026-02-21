import 'cart_item.dart';
import 'user.dart';
import 'rating.dart';

enum OrderStatus {
  pending,
  confirmed,
  shopping,
  readyForDelivery,
  inTransit,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.shopping:
        return 'Shopping in Progress';
      case OrderStatus.readyForDelivery:
        return 'Ready for Delivery';
      case OrderStatus.inTransit:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Your order has been received';
      case OrderStatus.confirmed:
        return 'A shopper will start shopping soon';
      case OrderStatus.shopping:
        return 'Your shopper is picking items';
      case OrderStatus.readyForDelivery:
        return 'Your order is ready for pickup';
      case OrderStatus.inTransit:
        return 'Your order is on the way';
      case OrderStatus.delivered:
        return 'Your order has been delivered';
      case OrderStatus.cancelled:
        return 'Your order was cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.shopping:
        return 2;
      case OrderStatus.readyForDelivery:
        return 3;
      case OrderStatus.inTransit:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return -1;
    }
  }
}

class Order {
  final String id;
  final String orderNumber;
  final List<CartItem> items;
  final Address deliveryAddress;
  final double subtotal;
  final double serviceFee;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final String? shopperId;
  final String? shopperName;
  final String? shopperPhone;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;
  final String? cancellationReason;
  final PaymentMethod paymentMethod;
  final bool isPaid;
  final Rating? rating;
  final bool hasBeenRated;

  Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.deliveryAddress,
    required this.subtotal,
    required this.serviceFee,
    required this.deliveryFee,
    required this.total,
    required this.status,
    this.shopperId,
    this.shopperName,
    this.shopperPhone,
    this.riderId,
    this.riderName,
    this.riderPhone,
    required this.createdAt,
    this.estimatedDelivery,
    this.deliveredAt,
    this.cancellationReason,
    required this.paymentMethod,
    this.isPaid = false,
    this.rating,
    this.hasBeenRated = false,
  });

  int get itemCount =>
      items.fold(0, (sum, item) => sum + item.quantity.toInt());

  // Convenience getters
  String get statusLabel => status.displayName;
  double get discount => 0.0; // Calculate from items or promotions if needed
  bool get isPending => status == OrderStatus.pending;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;

  Order copyWith({
    String? id,
    String? orderNumber,
    List<CartItem>? items,
    Address? deliveryAddress,
    double? subtotal,
    double? serviceFee,
    double? deliveryFee,
    double? total,
    OrderStatus? status,
    String? shopperId,
    String? shopperName,
    String? shopperPhone,
    String? riderId,
    String? riderName,
    String? riderPhone,
    DateTime? createdAt,
    DateTime? estimatedDelivery,
    DateTime? deliveredAt,
    String? cancellationReason,
    PaymentMethod? paymentMethod,
    bool? isPaid,
    Rating? rating,
    bool? hasBeenRated,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      subtotal: subtotal ?? this.subtotal,
      serviceFee: serviceFee ?? this.serviceFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      status: status ?? this.status,
      shopperId: shopperId ?? this.shopperId,
      shopperName: shopperName ?? this.shopperName,
      shopperPhone: shopperPhone ?? this.shopperPhone,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      createdAt: createdAt ?? this.createdAt,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      rating: rating ?? this.rating,
      hasBeenRated: hasBeenRated ?? this.hasBeenRated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'items': items.map((i) => i.toJson()).toList(),
      'deliveryAddress': deliveryAddress.toJson(),
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'deliveryFee': deliveryFee,
      'total': total,
      'status': status.name,
      'shopperId': shopperId,
      'shopperName': shopperName,
      'shopperPhone': shopperPhone,
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'createdAt': createdAt.toIso8601String(),
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'paymentMethod': paymentMethod.name,
      'isPaid': isPaid,
      'rating': rating?.toJson(),
      'hasBeenRated': hasBeenRated,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      items: (json['items'] as List<dynamic>)
          .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      deliveryAddress: Address.fromJson(
        json['deliveryAddress'] as Map<String, dynamic>,
      ),
      subtotal: (json['subtotal'] as num).toDouble(),
      serviceFee: (json['serviceFee'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      shopperId: json['shopperId'] as String?,
      shopperName: json['shopperName'] as String?,
      shopperPhone: json['shopperPhone'] as String?,
      riderId: json['riderId'] as String?,
      riderName: json['riderName'] as String?,
      riderPhone: json['riderPhone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.parse(json['estimatedDelivery'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      paymentMethod: PaymentMethod.values.firstWhere(
        (p) => p.name == json['paymentMethod'],
        orElse: () => PaymentMethod.mobileMoney,
      ),
      isPaid: json['isPaid'] as bool? ?? false,
      rating: json['rating'] != null
          ? Rating.fromJson(json['rating'] as Map<String, dynamic>)
          : null,
      hasBeenRated: json['hasBeenRated'] as bool? ?? false,
    );
  }
}

enum PaymentMethod { mobileMoney, card, cashOnDelivery }

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.card:
        return 'Card Payment';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.mobileMoney:
        return 'mobile';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.cashOnDelivery:
        return 'cash';
    }
  }
}
