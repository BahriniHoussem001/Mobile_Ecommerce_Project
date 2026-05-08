// lib/providers/admin_order_provider.dart
//
// Separate from the client OrderProvider.
// Streams ALL orders (not filtered by userId) for the admin panel.
// Exposes live statistics computed from the stream.
//
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import '../models/order.dart';

class AdminOrderProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _sub;

  // Filter state (used by the orders list screen)
  OrderStatus? _filterStatus;
  String _searchQuery = '';

  List<Order> get allOrders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  OrderStatus? get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;

  // ── Live statistics ───────────────────────────────────────
  int get totalOrders => _orders.length;
  int get pendingCount =>
      _orders.where((o) => o.status == OrderStatus.pending).length;
  int get shippedCount =>
      _orders.where((o) => o.status == OrderStatus.shipped).length;
  int get deliveredCount =>
      _orders.where((o) => o.status == OrderStatus.delivered).length;
  int get cancelledCount =>
      _orders.where((o) => o.status == OrderStatus.cancelled).length;

  double get totalRevenue => _orders
      .where((o) => o.status == OrderStatus.delivered)
      .fold(0.0, (s, o) => s + o.total);

  double get monthRevenue {
    final now = DateTime.now();
    return _orders
        .where(
          (o) =>
              o.status == OrderStatus.delivered &&
              o.createdAt.year == now.year &&
              o.createdAt.month == now.month,
        )
        .fold(0.0, (s, o) => s + o.total);
  }

  // Month-over-month order growth (%)
  double get orderGrowthPercent {
    final now = DateTime.now();
    final thisMonth = _orders
        .where(
          (o) => o.createdAt.year == now.year && o.createdAt.month == now.month,
        )
        .length;
    final lastMonth = _orders.where((o) {
      final prev = DateTime(now.year, now.month - 1);
      return o.createdAt.year == prev.year && o.createdAt.month == prev.month;
    }).length;
    if (lastMonth == 0) return thisMonth > 0 ? 100.0 : 0.0;
    return ((thisMonth - lastMonth) / lastMonth * 100);
  }

  // ── Filtered list for orders screen ──────────────────────
  List<Order> get filtered {
    var list = List<Order>.from(_orders);
    if (_filterStatus != null) {
      list = list.where((o) => o.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (o) =>
                o.id.toLowerCase().contains(q) ||
                o.shippingAddress.fullName.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  void setFilter(OrderStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  // ── Start real-time stream ────────────────────────────────
  void startListening() {
    if (_sub != null) return;
    _isLoading = true;
    notifyListeners();

    _sub = _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
            _orders = snap.docs
                .map(
                  (d) => Order.fromMap(d.data() as Map<String, dynamic>, d.id),
                )
                .toList();
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _isLoading = false;
            _error = 'Failed to load orders: $e';
            debugPrint('AdminOrderProvider: $e');
            notifyListeners();
          },
        );
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _orders = [];
    notifyListeners();
  }

  // ── Admin status update ───────────────────────────────────
  Future<void> updateStatus(String orderId, OrderStatus status) =>
      _db.collection('orders').doc(orderId).update({
        'status': status.name,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

  Future<void> setTracking(String orderId, String tracking) =>
      _db.collection('orders').doc(orderId).update({
        'trackingNumber': tracking,
        'status': OrderStatus.shipped.name,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

  // Single-order stream for admin detail screen
  Stream<Order> streamOrder(String orderId) => _db
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((s) => Order.fromMap(s.data() as Map<String, dynamic>, s.id));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
