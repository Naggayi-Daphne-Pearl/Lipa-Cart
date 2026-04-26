import 'cart_item.dart';
import 'user.dart';
import 'rating.dart';

enum OrderStatus {
  pending,
  paymentProcessing,
  confirmed,
  shopperAssigned,
  shopping,
  readyForDelivery,
  riderAssigned,
  inTransit,
  delivered,
  cancelled,
  refunded,
}

/// Backend uses snake_case names that don't all line up with our enum:
/// `payment_confirmed` → confirmed, `ready_for_pickup` → readyForDelivery.
/// Fall back to the firstWhere by enum name for everything else.
OrderStatus _statusFromBackend(String? raw) {
  switch (raw) {
    case 'payment_confirmed':
      return OrderStatus.confirmed;
    case 'ready_for_pickup':
      return OrderStatus.readyForDelivery;
    case 'payment_processing':
      return OrderStatus.paymentProcessing;
    case 'shopper_assigned':
      return OrderStatus.shopperAssigned;
    case 'rider_assigned':
      return OrderStatus.riderAssigned;
    case 'in_transit':
      return OrderStatus.inTransit;
    default:
      return OrderStatus.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => OrderStatus.pending,
      );
  }
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.paymentProcessing:
        return 'Payment Processing';
      case OrderStatus.confirmed:
        return 'Payment Confirmed';
      case OrderStatus.shopperAssigned:
        return 'Shopper Assigned';
      case OrderStatus.shopping:
        return 'Shopping in Progress';
      case OrderStatus.readyForDelivery:
        return 'Ready for Delivery';
      case OrderStatus.riderAssigned:
        return 'Rider Assigned';
      case OrderStatus.inTransit:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Your order has been received';
      case OrderStatus.paymentProcessing:
        return 'Your payment is being processed';
      case OrderStatus.confirmed:
        return 'Payment confirmed, awaiting shopper';
      case OrderStatus.shopperAssigned:
        return 'A shopper has been assigned to your order';
      case OrderStatus.shopping:
        return 'Your shopper is picking items';
      case OrderStatus.readyForDelivery:
        return 'Your order is ready for pickup';
      case OrderStatus.riderAssigned:
        return 'A rider has been assigned for delivery';
      case OrderStatus.inTransit:
        return 'Your order is on the way';
      case OrderStatus.delivered:
        return 'Your order has been delivered';
      case OrderStatus.cancelled:
        return 'Your order was cancelled';
      case OrderStatus.refunded:
        return 'Your order has been refunded';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.paymentProcessing:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.shopperAssigned:
        return 2;
      case OrderStatus.shopping:
        return 3;
      case OrderStatus.readyForDelivery:
        return 4;
      case OrderStatus.riderAssigned:
        return 5;
      case OrderStatus.inTransit:
        return 6;
      case OrderStatus.delivered:
        return 7;
      case OrderStatus.cancelled:
        return -1;
      case OrderStatus.refunded:
        return -1;
    }
  }
}

class Order {
  final String id;
  final String? documentId; // For Strapi v5 relations
  final String orderNumber;
  final List<CartItem> items;
  final Address deliveryAddress;
  final double subtotal;
  final double serviceFee;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final String? customerId;
  final User? customer;
  final String? shopperId;
  final String? shopperName;
  final String? shopperPhone;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final double? riderLatitude;
  final double? riderLongitude;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;
  final DateTime? paymentConfirmedAt;
  final DateTime? shopperAssignedAt;
  final DateTime? shoppingStartedAt;
  final DateTime? shoppingCompletedAt;
  final DateTime? riderAssignedAt;
  final DateTime? pickedUpAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final PaymentMethod paymentMethod;
  final bool isPaid;
  final Rating? rating;
  final bool hasBeenRated;
  final String? deliveryProofUrl;

  Order({
    required this.id,
    this.documentId,
    required this.orderNumber,
    required this.items,
    required this.deliveryAddress,
    required this.subtotal,
    required this.serviceFee,
    required this.deliveryFee,
    required this.total,
    required this.status,
    this.customerId,
    this.customer,
    this.shopperId,
    this.shopperName,
    this.shopperPhone,
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.riderLatitude,
    this.riderLongitude,
    required this.createdAt,
    this.estimatedDelivery,
    this.deliveredAt,
    this.paymentConfirmedAt,
    this.shopperAssignedAt,
    this.shoppingStartedAt,
    this.shoppingCompletedAt,
    this.riderAssignedAt,
    this.pickedUpAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.paymentMethod,
    this.isPaid = false,
    this.rating,
    this.hasBeenRated = false,
    this.deliveryProofUrl,
  });

  int get itemCount {
    final sum = items.fold(0, (sum, item) => sum + item.quantity.toInt());
    // If sum is 0 but items exist, return items count as fallback
    return sum > 0 ? sum : items.length;
  }

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
    String? customerId,
    User? customer,
    String? shopperId,
    String? shopperName,
    String? shopperPhone,
    String? riderId,
    String? riderName,
    String? riderPhone,
    double? riderLatitude,
    double? riderLongitude,
    DateTime? createdAt,
    DateTime? estimatedDelivery,
    DateTime? deliveredAt,
    DateTime? paymentConfirmedAt,
    DateTime? shopperAssignedAt,
    DateTime? shoppingStartedAt,
    DateTime? shoppingCompletedAt,
    DateTime? riderAssignedAt,
    DateTime? pickedUpAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    PaymentMethod? paymentMethod,
    bool? isPaid,
    Rating? rating,
    bool? hasBeenRated,
    String? deliveryProofUrl,
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
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      shopperId: shopperId ?? this.shopperId,
      shopperName: shopperName ?? this.shopperName,
      shopperPhone: shopperPhone ?? this.shopperPhone,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      riderLatitude: riderLatitude ?? this.riderLatitude,
      riderLongitude: riderLongitude ?? this.riderLongitude,
      createdAt: createdAt ?? this.createdAt,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      paymentConfirmedAt: paymentConfirmedAt ?? this.paymentConfirmedAt,
      shopperAssignedAt: shopperAssignedAt ?? this.shopperAssignedAt,
      shoppingStartedAt: shoppingStartedAt ?? this.shoppingStartedAt,
      shoppingCompletedAt: shoppingCompletedAt ?? this.shoppingCompletedAt,
      riderAssignedAt: riderAssignedAt ?? this.riderAssignedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      rating: rating ?? this.rating,
      hasBeenRated: hasBeenRated ?? this.hasBeenRated,
      deliveryProofUrl: deliveryProofUrl ?? this.deliveryProofUrl,
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
      'customerId': customerId,
      'customer': customer?.customerId,
      'shopperId': shopperId,
      'shopperName': shopperName,
      'shopperPhone': shopperPhone,
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'riderLatitude': riderLatitude,
      'riderLongitude': riderLongitude,
      'createdAt': createdAt.toIso8601String(),
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'paymentConfirmedAt': paymentConfirmedAt?.toIso8601String(),
      'shopperAssignedAt': shopperAssignedAt?.toIso8601String(),
      'shoppingStartedAt': shoppingStartedAt?.toIso8601String(),
      'shoppingCompletedAt': shoppingCompletedAt?.toIso8601String(),
      'riderAssignedAt': riderAssignedAt?.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'paymentMethod': paymentMethod.name,
      'isPaid': isPaid,
      'rating': rating?.toJson(),
      'hasBeenRated': hasBeenRated,
      'deliveryProofUrl': deliveryProofUrl,
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
      status: _statusFromBackend(json['status']?.toString()),
      customerId: json['customerId'] as String?,
      customer: json['customer'] != null
          ? User.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      shopperId: json['shopperId'] as String?,
      shopperName: json['shopperName'] as String?,
      shopperPhone: json['shopperPhone'] as String?,
      riderId: json['riderId'] as String?,
      riderName: json['riderName'] as String?,
      riderPhone: json['riderPhone'] as String?,
      riderLatitude: (json['riderLatitude'] as num?)?.toDouble(),
      riderLongitude: (json['riderLongitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.parse(json['estimatedDelivery'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      paymentConfirmedAt: json['paymentConfirmedAt'] != null
          ? DateTime.parse(json['paymentConfirmedAt'] as String)
          : null,
      shopperAssignedAt: json['shopperAssignedAt'] != null
          ? DateTime.parse(json['shopperAssignedAt'] as String)
          : null,
      shoppingStartedAt: json['shoppingStartedAt'] != null
          ? DateTime.parse(json['shoppingStartedAt'] as String)
          : null,
      shoppingCompletedAt: json['shoppingCompletedAt'] != null
          ? DateTime.parse(json['shoppingCompletedAt'] as String)
          : null,
      riderAssignedAt: json['riderAssignedAt'] != null
          ? DateTime.parse(json['riderAssignedAt'] as String)
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      paymentMethod: paymentMethodFromBackendValue(
        json['paymentMethod'] as String?,
      ),
      isPaid: json['isPaid'] as bool? ?? false,
      rating: json['rating'] != null
          ? Rating.fromJson(json['rating'] as Map<String, dynamic>)
          : null,
      hasBeenRated: json['hasBeenRated'] as bool? ??
          (() {
            final ratingData = json['rating'];
            if (ratingData == null) return false;
            if (ratingData is Map<String, dynamic>) {
              if (ratingData.containsKey('data')) {
                return ratingData['data'] != null;
              }
              return ratingData.containsKey('id') ||
                  ratingData.containsKey('documentId');
            }
            return false;
          }()),
      deliveryProofUrl: json['deliveryProofUrl'] as String?,
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

  /// Serialised value for the backend `order.payment_method` enum.
  ///
  /// These values match the Strapi schema at
  /// `Lipa-Cart-Backend/src/api/order/content-types/order/schema.json` —
  /// changing them requires a corresponding enum + data migration on the
  /// backend. Do NOT rely on Dart's enum `.name` for round-tripping.
  String get toBackendValue {
    switch (this) {
      case PaymentMethod.mobileMoney:
        return 'mobileMoney';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.cashOnDelivery:
        return 'cashOnDelivery';
    }
  }
}

/// Parse a backend `order.payment_method` string back into a [PaymentMethod].
/// Unknown/null values fall back to [PaymentMethod.mobileMoney].
PaymentMethod paymentMethodFromBackendValue(String? value) {
  switch (value) {
    case 'mobileMoney':
      return PaymentMethod.mobileMoney;
    case 'card':
      return PaymentMethod.card;
    case 'cashOnDelivery':
      return PaymentMethod.cashOnDelivery;
    default:
      return PaymentMethod.mobileMoney;
  }
}
