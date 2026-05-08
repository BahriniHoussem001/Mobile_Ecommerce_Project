import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/coupon.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  Coupon? _appliedCoupon;
  double _shippingFee = 7.0;

  // ── Getters ───────────────────────────────────────────────

  List<CartItem> get items => _items.values.toList();

  int get itemCount => _items.values.fold(0, (sum, i) => sum + i.quantity);

  bool get isEmpty => _items.isEmpty;

  Coupon? get appliedCoupon => _appliedCoupon;

  double get shippingFee => _shippingFee;

  double get subtotal => _items.values.fold(0.0, (sum, i) => sum + i.subtotal);

  double get discountAmount => _appliedCoupon?.computeDiscount(subtotal) ?? 0.0;

  double get total =>
      (subtotal - discountAmount + _shippingFee).clamp(0.0, double.infinity);

  bool containsProduct(String productId) =>
      _items.keys.any((k) => k.startsWith(productId));

  // ── Mutations ─────────────────────────────────────────────

  /// Add or increment an item. Merges if same product + size + color.
  void addItem(CartItem item) {
    final key = item.variantKey;
    if (_items.containsKey(key)) {
      _items[key]!.quantity += item.quantity;
    } else {
      _items[key] = item;
    }
    notifyListeners();
  }

  void removeItem(String variantKey) {
    _items.remove(variantKey);
    notifyListeners();
  }

  void incrementQuantity(String variantKey) {
    if (_items.containsKey(variantKey)) {
      _items[variantKey]!.quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String variantKey) {
    if (_items.containsKey(variantKey)) {
      if (_items[variantKey]!.quantity <= 1) {
        _items.remove(variantKey);
      } else {
        _items[variantKey]!.quantity--;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    notifyListeners();
  }

  // ── Coupon ────────────────────────────────────────────────

  /// Returns null on success, error message on failure.
  String? applyCoupon(Coupon coupon) {
    if (!coupon.isValid) {
      return coupon.isExpired ? 'Coupon has expired.' : 'Coupon is not valid.';
    }
    if (coupon.minimumOrder != null && subtotal < coupon.minimumOrder!) {
      return 'Minimum order of \$${coupon.minimumOrder!.toStringAsFixed(2)} required.';
    }
    _appliedCoupon = coupon;
    notifyListeners();
    return null;
  }

  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  // ── Shipping ──────────────────────────────────────────────

  void setShippingFee(double fee) {
    _shippingFee = fee;
    notifyListeners();
  }

  // ── Snapshot for order creation ───────────────────────────

  List<CartItem> get snapshot =>
      _items.values.map((i) => i.copyWith(quantity: i.quantity)).toList();
}
