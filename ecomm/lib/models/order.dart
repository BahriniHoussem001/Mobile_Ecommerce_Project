import 'cart_item.dart';
import 'app_user.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final ShippingAddress shippingAddress;
  final double subtotal;
  final double shippingFee;
  final double discount; // amount saved via coupon
  final String? couponCode;
  final double total;
  final OrderStatus status;
  final String paymentMethod; // 'card' | 'stripe' | 'cash_on_delivery'
  final String? paymentIntentId;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.subtotal,
    this.shippingFee = 0.0,
    this.discount = 0.0,
    this.couponCode,
    required this.total,
    this.status = OrderStatus.pending,
    required this.paymentMethod,
    this.paymentIntentId,
    this.trackingNumber,
    required this.createdAt,
    this.updatedAt,
  });

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  factory Order.fromMap(Map<String, dynamic> map, String docId) {
    return Order(
      id: docId,
      userId: map['userId'] as String,
      items: (map['items'] as List<dynamic>)
          .map((i) => CartItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      shippingAddress: ShippingAddress.fromMap(
        map['shippingAddress'] as Map<String, dynamic>,
      ),
      subtotal: (map['subtotal'] as num).toDouble(),
      shippingFee: (map['shippingFee'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      couponCode: map['couponCode'] as String?,
      total: (map['total'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: map['paymentMethod'] as String,
      paymentIntentId: map['paymentIntentId'] as String?,
      trackingNumber: map['trackingNumber'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'items': items.map((i) => i.toMap()).toList(),
    'shippingAddress': shippingAddress.toMap(),
    'subtotal': subtotal,
    'shippingFee': shippingFee,
    'discount': discount,
    'couponCode': couponCode,
    'total': total,
    'status': status.name,
    'paymentMethod': paymentMethod,
    'paymentIntentId': paymentIntentId,
    'trackingNumber': trackingNumber,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
  };

  Order copyWith({OrderStatus? status, String? trackingNumber}) {
    return Order(
      id: id,
      userId: userId,
      items: items,
      shippingAddress: shippingAddress,
      subtotal: subtotal,
      shippingFee: shippingFee,
      discount: discount,
      couponCode: couponCode,
      total: total,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      paymentIntentId: paymentIntentId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
