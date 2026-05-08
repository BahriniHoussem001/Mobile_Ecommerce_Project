// lib/providers/order_provider.dart
//
// SECURITY FIXES:
// 1. listenToOrder() now requires userId parameter and validates ownership
// 2. deleteOrder() now requires userId parameter and validates ownership
// 3. Only OrderDetailScreen and OrderTrackingScreen can access orders
//    and they verify the order belongs to the authenticated user
// 4. placeOrder() uses a WriteBatch to atomically:
//    - Create the order document
//    - Decrement each product's stockQuantity by the ordered quantity
//    - Increment the coupon's usageCount (if a coupon was used)
//    - Set coupon isActive = false when usageCount reaches usageLimit
//
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/app_user.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _subscription;
  String? _currentUserId;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Real-time listener ────────────────────────────────────
  void listenToUserOrders(String userId) {
    if (_currentUserId == userId && _subscription != null) return;
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
            _orders = snap.docs
                .map((d) => Order.fromMap(d.data(), d.id))
                .toList();
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (e) {
            _isLoading = false;
            _errorMessage = 'Failed to load orders: $e';
            debugPrint('OrderProvider stream error: $e');
            notifyListeners();
          },
        );
  }

  // ── Single-order stream (OrderDetailScreen) ───────────────
  // SECURITY: Validates that the order belongs to the authenticated user
  Stream<Order> listenToOrder(String orderId, String userId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .asyncMap((snap) async {
          if (!snap.exists) {
            throw Exception('Order not found');
          }
          final order = Order.fromMap(snap.data() as Map<String, dynamic>, snap.id);
          // Verify the order belongs to the current user
          if (order.userId != userId) {
            throw Exception('Unauthorized: This order does not belong to you');
          }
          return order;
        });
  }

  // ── Stop listening (sign-out) ─────────────────────────────
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _currentUserId = null;
    _orders = [];
    _isLoading = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // Place order — atomic batch:
  //   1. Write the new /orders/{id} document
  //   2. Decrement stockQuantity on each /products/{id}
  //   3. If a coupon was used:
  //      a. Increment usageCount
  //      b. Set isActive = false when usageCount reaches usageLimit
  // ─────────────────────────────────────────────────────────
  Future<Order?> placeOrder({
    required String userId,
    required List<CartItem> items,
    required ShippingAddress shippingAddress,
    required double subtotal,
    required double shippingFee,
    required double discount,
    String? couponCode,
    required String paymentMethod,
    String? paymentIntentId,
  }) async {
    try {
      final total = (subtotal - discount + shippingFee).clamp(
        0.0,
        double.infinity,
      );

      // Pre-create the order ref so we have an id for the return value
      final orderRef = _db.collection('orders').doc();

      final order = Order(
        id: orderRef.id,
        userId: userId,
        items: items,
        shippingAddress: shippingAddress,
        subtotal: subtotal,
        shippingFee: shippingFee,
        discount: discount,
        couponCode: couponCode,
        total: total,
        paymentMethod: paymentMethod,
        paymentIntentId: paymentIntentId,
        createdAt: DateTime.now(),
      );

      final batch = _db.batch();

      // 1. Create the order document
      batch.set(orderRef, order.toMap());

      // 2. Decrement each product's stockQuantity
      //    Group items by productId first in case the same product
      //    appears multiple times (different variants).
      final Map<String, int> qtySold = {};
      for (final item in items) {
        qtySold[item.productId] =
            (qtySold[item.productId] ?? 0) + item.quantity;
      }

      for (final entry in qtySold.entries) {
        final productRef = _db.collection('products').doc(entry.key);
        batch.update(productRef, {
          'stockQuantity': FieldValue.increment(-entry.value),
        });
      }

      // 3. Handle coupon: increment usageCount + deactivate if at limit
      if (couponCode != null && couponCode.isNotEmpty) {
        final couponSnap = await _db
            .collection('coupons')
            .where('code', isEqualTo: couponCode)
            .limit(1)
            .get();

        if (couponSnap.docs.isNotEmpty) {
          final couponDoc = couponSnap.docs.first;
          final data = couponDoc.data();
          final currentCount = (data['usageCount'] as num?)?.toInt() ?? 0;
          final usageLimit = data['usageLimit'] as int?; // null = unlimited

          final newCount = currentCount + 1;
          final Map<String, dynamic> couponUpdate = {'usageCount': newCount};

          // Deactivate when the limit is reached
          if (usageLimit != null && newCount >= usageLimit) {
            couponUpdate['isActive'] = false;
          }

          batch.update(couponDoc.reference, couponUpdate);
        }
      }

      // Commit everything atomically
      await batch.commit();

      // The stream will auto-add the new order — return immediately
      return order;
    } catch (e) {
      _errorMessage = 'Failed to place order: $e';
      debugPrint('placeOrder error: $e');
      notifyListeners();
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────
  // Delete order — removes the Firestore document.
  // SECURITY: Validates that the order belongs to the authenticated user
  // The stream listener automatically removes it from _orders.
  // ─────────────────────────────────────────────────────────
  Future<void> deleteOrder(String orderId, String userId) async {
    try {
      // Verify the order belongs to the user before deleting
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }
      final order = Order.fromMap(orderDoc.data()!, orderId);
      if (order.userId != userId) {
        throw Exception('Unauthorized: You can only delete your own orders');
      }
      
      await _db.collection('orders').doc(orderId).delete();
      // Stream will update _orders; no manual list mutation needed.
    } catch (e) {
      debugPrint('deleteOrder error: $e');
      rethrow;
    }
  }

  // ── Admin mutations ───────────────────────────────────────
  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _db.collection('orders').doc(orderId).update({
        'status': status.name,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

  Future<void> setTrackingNumber(String orderId, String trackingNumber) =>
      _db.collection('orders').doc(orderId).update({
        'trackingNumber': trackingNumber,
        'status': OrderStatus.shipped.name,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

  // ── Admin dashboard stats ─────────────────────────────────
  double get totalRevenue => _orders
      .where((o) => o.status == OrderStatus.delivered)
      .fold(0.0, (sum, o) => sum + o.total);

  int get pendingCount =>
      _orders.where((o) => o.status == OrderStatus.pending).length;

  int get deliveredCount =>
      _orders.where((o) => o.status == OrderStatus.delivered).length;

  // ── Admin: one-time fetch ─────────────────────────────────
  Future<void> fetchAllOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      _orders = snap.docs.map((d) => Order.fromMap(d.data(), d.id)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load orders: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
