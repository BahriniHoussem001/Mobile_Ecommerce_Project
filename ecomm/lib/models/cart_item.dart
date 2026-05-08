class CartItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final double unitPrice;
  final String selectedSize;
  final String selectedColor;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.unitPrice,
    required this.selectedSize,
    required this.selectedColor,
    this.quantity = 1,
  });

  /// Unique key per product + variant combination
  String get variantKey => '${productId}_${selectedSize}_$selectedColor';

  double get subtotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      unitPrice: unitPrice,
      selectedSize: selectedSize,
      selectedColor: selectedColor,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'imageUrl': imageUrl,
    'unitPrice': unitPrice,
    'selectedSize': selectedSize,
    'selectedColor': selectedColor,
    'quantity': quantity,
  };

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      imageUrl: map['imageUrl'] as String,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      selectedSize: map['selectedSize'] as String,
      selectedColor: map['selectedColor'] as String,
      quantity: (map['quantity'] as num).toInt(),
    );
  }
}
