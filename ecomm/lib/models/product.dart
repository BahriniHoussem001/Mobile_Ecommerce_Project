// ============================================================================
// Product category
// ============================================================================

// Définit les catégories disponibles pour les produits de l'application.
enum ProductCategory { tops, bottoms, dresses, outerwear, accessories, shoes }

// ============================================================================
// Product model
// ============================================================================

// Modèle représentant un produit affiché dans l'application.
//
// Cette classe contient toutes les informations nécessaires pour afficher,
// filtrer, vendre et gérer un produit dans la boutique.
class Product {
  // --------------------------------------------------------------------------
  // Properties
  // --------------------------------------------------------------------------

  // Identifiant unique du produit.
  final String id;

  // Nom du produit.
  final String name;

  // Description détaillée du produit.
  final String description;

  // Prix actuel du produit.
  final double price;

  // Ancien prix du produit.
  // Si cette valeur n'est pas null et qu'elle est supérieure au prix actuel,
  // cela signifie que le produit est en promotion.
  final double? originalPrice;

  // Liste des URLs des images du produit.
  final List<String> imageUrls;

  // Catégorie à laquelle appartient le produit.
  final ProductCategory category;

  // Liste des tailles disponibles pour ce produit.
  final List<String> availableSizes;

  // Liste des couleurs disponibles pour ce produit.
  final List<String> availableColors;

  // Quantité disponible en stock.
  final int stockQuantity;

  // Note moyenne du produit.
  final double rating;

  // Nombre total d'avis associés au produit.
  final int reviewCount;

  // Date de création du produit.
  final DateTime createdAt;

  // --------------------------------------------------------------------------
  // Constructor
  // --------------------------------------------------------------------------

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

  // --------------------------------------------------------------------------
  // Computed properties
  // --------------------------------------------------------------------------

  // Vérifie si le produit est en promotion.
  bool get isOnSale => originalPrice != null && originalPrice! > price;

  // Calcule le pourcentage de réduction si le produit est en promotion.
  double get discountPercent {
    if (!isOnSale) return 0;

    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  // Vérifie si le produit est disponible en stock.
  bool get isInStock => stockQuantity > 0;

  // Retourne l'image principale du produit.
  //
  // Si aucune image n'est disponible, une chaîne vide est retournée
  // pour éviter une erreur d'accès à une liste vide.
  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  // --------------------------------------------------------------------------
  // Serialization
  // --------------------------------------------------------------------------

  // Crée un objet Product à partir d'une Map récupérée depuis Firestore.
  //
  // Le paramètre docId représente l'identifiant du document Firestore.
  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    final productCategory = ProductCategory.values.firstWhere(
      (category) => category.name == map['category'],
      orElse: () => ProductCategory.tops,
    );

    final productOriginalPrice = map['originalPrice'] != null
        ? (map['originalPrice'] as num).toDouble()
        : null;

    return Product(
      id: docId,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      originalPrice: productOriginalPrice,
      imageUrls: List<String>.from(map['imageUrls'] as List),
      category: productCategory,
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

  // Convertit l'objet Product en Map pour l'enregistrement dans Firestore.
  Map<String, dynamic> toMap() {
    return {
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
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  // Crée une copie du produit en modifiant uniquement les champs fournis.
  //
  // Cette méthode est utile lors de la modification d'un produit sans changer
  // directement l'objet existant.
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