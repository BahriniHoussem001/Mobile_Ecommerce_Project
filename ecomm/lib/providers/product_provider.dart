import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

enum ProductLoadState { initial, loading, loaded, error }

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Product> _all = [];
  ProductLoadState _state = ProductLoadState.initial;
  String? _errorMessage;

  // Client-side filters & search
  String _searchQuery = '';
  ProductCategory? _selectedCategory;
  String _sortBy = 'newest'; // newest | priceAsc | priceDesc | rating

  // ── Getters ───────────────────────────────────────────────

  ProductLoadState get state => _state;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  ProductCategory? get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  List<Product> get onSale =>
      _all.where((p) => p.isOnSale && p.isInStock).toList();

  List<Product> get filtered {
    List<Product> result = List.from(_all);

    if (_selectedCategory != null) {
      result = result.where((p) => p.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q),
          )
          .toList();
    }

    switch (_sortBy) {
      case 'priceAsc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'priceDesc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default: // newest
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  Product? getById(String id) {
    try {
      return _all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Data loading ──────────────────────────────────────────

  Future<void> fetchAll() async {
    _state = ProductLoadState.loading;
    notifyListeners();
    try {
      final snap = await _db.collection('products').get();
      _all = snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList();
      _state = ProductLoadState.loaded;
    } catch (e) {
      _state = ProductLoadState.error;
      _errorMessage = 'Failed to load products.';
    }
    notifyListeners();
  }

  // ── Filters ───────────────────────────────────────────────

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(ProductCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _sortBy = 'newest';
    notifyListeners();
  }

  // ── Admin CRUD ────────────────────────────────────────────

  Future<void> addProduct(Product product) async {
    final ref = await _db.collection('products').add(product.toMap());
    final newProduct = Product.fromMap(product.toMap(), ref.id);
    _all.insert(0, newProduct);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await _db.collection('products').doc(product.id).update(product.toMap());
    final index = _all.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _all[index] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
    _all.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  Future<void> updateStock(String productId, int newQuantity) async {
    await _db.collection('products').doc(productId).update({
      'stockQuantity': newQuantity,
    });
    final index = _all.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _all[index] = _all[index].copyWith(stockQuantity: newQuantity);
      notifyListeners();
    }
  }
}
