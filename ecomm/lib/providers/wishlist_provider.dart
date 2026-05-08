import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Set<String> _productIds = {};
  String? _userId;

  Set<String> get productIds => _productIds;
  int get count => _productIds.length;

  bool contains(String productId) => _productIds.contains(productId);

  // ── Load from Firestore ───────────────────────────────────

  Future<void> load(String userId) async {
    _userId = userId;
    try {
      final doc = await _db.collection('wishlists').doc(userId).get();
      if (doc.exists) {
        final ids = List<String>.from(doc.data()?['productIds'] ?? []);
        _productIds
          ..clear()
          ..addAll(ids);
        notifyListeners();
      }
    } catch (_) {
      // silently fail — wishlist is not critical
    }
  }

  // ── Toggle ────────────────────────────────────────────────

  Future<void> toggle(String productId) async {
    if (_productIds.contains(productId)) {
      _productIds.remove(productId);
    } else {
      _productIds.add(productId);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String productId) async {
    _productIds.remove(productId);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _productIds.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    if (_userId == null) return;
    await _db.collection('wishlists').doc(_userId).set({
      'productIds': _productIds.toList(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
