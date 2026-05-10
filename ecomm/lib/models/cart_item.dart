// ============================================================================
// CartItem model
// ============================================================================

// Modèle représentant un article ajouté au panier.
//
// Un CartItem ne représente pas seulement un produit,
// mais aussi une variante spécifique du produit : taille + couleur.
class CartItem {
  // --------------------------------------------------------------------------
  // Properties
  // --------------------------------------------------------------------------

  // Identifiant du produit.
  final String productId;

  // Nom du produit affiché dans le panier.
  final String productName;

  // Image du produit.
  final String imageUrl;

  // Prix unitaire du produit.
  final double unitPrice;

  // Taille choisie par l'utilisateur.
  final String selectedSize;

  // Couleur choisie par l'utilisateur.
  final String selectedColor;

  // Quantité du produit dans le panier.
  int quantity;

  // --------------------------------------------------------------------------
  // Constructor
  // --------------------------------------------------------------------------

  CartItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.unitPrice,
    required this.selectedSize,
    required this.selectedColor,
    this.quantity = 1,
  });

  // --------------------------------------------------------------------------
  // Computed properties
  // --------------------------------------------------------------------------

  // Clé unique utilisée pour distinguer les variantes d'un même produit.
  //
  // Exemple :
  // Même produit + taille différente = deux articles différents dans le panier.
  String get variantKey => '${productId}_${selectedSize}_$selectedColor';

  // Calcule le sous-total de cet article selon son prix unitaire et sa quantité.
  double get subtotal => unitPrice * quantity;

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  // Crée une copie de l'article en modifiant uniquement la quantité si nécessaire.
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

  // --------------------------------------------------------------------------
  // Serialization
  // --------------------------------------------------------------------------

  // Convertit l'objet CartItem en Map pour faciliter son stockage.
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'quantity': quantity,
    };
  }

  // Crée un objet CartItem à partir d'une Map récupérée depuis la base de données.
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