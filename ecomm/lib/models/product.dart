enum ProductCategory { tops, bottoms, dresses, outerwear, accessories, shoes }

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice; // non-null when on promotion
  final List<String> imageUrls;
  final ProductCategory category;
  final List<String> availableSizes;
  final List<String> availableColors;
  final int stockQuantity;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.imageUrls,
    required this.category,
    required this.availableSizes,
    required this.availableColors,
    required this.stockQuantity,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
  });

  bool get isOnSale => originalPrice != null && originalPrice! > price;

  double get discountPercent => isOnSale
      ? ((originalPrice! - price) / originalPrice! * 100).roundToDouble()
      : 0;

  bool get isInStock => stockQuantity > 0;

  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  // ── Firestore serialisation ──────────────────────────────────

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      originalPrice: map['originalPrice'] != null
          ? (map['originalPrice'] as num).toDouble()
          : null,
      imageUrls: List<String>.from(map['imageUrls'] as List),
      category: ProductCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ProductCategory.tops,
      ),
      availableSizes: List<String>.from(map['availableSizes'] as List),
      availableColors: List<String>.from(map['availableColors'] as List),
      stockQuantity: (map['stockQuantity'] as num).toInt(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'price': price,
    'originalPrice': originalPrice,
    'imageUrls': imageUrls,
    'category': category.name,
    'availableSizes': availableSizes,
    'availableColors': availableColors,
    'stockQuantity': stockQuantity,
    'rating': rating,
    'reviewCount': reviewCount,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  Product copyWith({
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    List<String>? imageUrls,
    ProductCategory? category,
    List<String>? availableSizes,
    List<String>? availableColors,
    int? stockQuantity,
    double? rating,
    int? reviewCount,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      availableSizes: availableSizes ?? this.availableSizes,
      availableColors: availableColors ?? this.availableColors,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt,
    );
  }
}
