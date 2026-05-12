// ============================================================================
// Review model
// ============================================================================

// Modèle représentant un avis laissé par un utilisateur sur un produit.
//
// Chaque avis contient l'utilisateur concerné, le produit évalué,
// une note, un commentaire et la date de création.
class Review {
  // --------------------------------------------------------------------------
  // Properties
  // --------------------------------------------------------------------------

  // Identifiant unique de l'avis.
  final String id;

  // Identifiant du produit concerné par l'avis.
  final String productId;

  // Identifiant de l'utilisateur qui a laissé l'avis.
  final String userId;

  // Nom de l'utilisateur affiché avec l'avis.
  final String userName;

  // Photo optionnelle de l'utilisateur.
  final String? userPhotoUrl;

  // Note donnée au produit, généralement entre 1.0 et 5.0.
  final double rating;

  // Commentaire écrit par l'utilisateur.
  final String comment;

  // Date de création de l'avis.
  final DateTime createdAt;

  // --------------------------------------------------------------------------
  // Constructor
  // --------------------------------------------------------------------------

  const Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  // --------------------------------------------------------------------------
  // Serialization
  // --------------------------------------------------------------------------

  // Crée un objet Review à partir d'une Map récupérée depuis la base de données.
  //
  // Le paramètre docId représente l'identifiant du document dans Firestore
  // ou dans la source de données utilisée.
  factory Review.fromMap(Map<String, dynamic> map, String docId) {
    return Review(
      id: docId,
      productId: map['productId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userPhotoUrl: map['userPhotoUrl'] as String?,
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  // Convertit l'objet Review en Map pour pouvoir l'enregistrer dans la base.
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}