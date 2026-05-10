// ============================================================================
// Discount type
// ============================================================================

// Définit les deux types de réduction possibles pour un coupon.
// - percentage  : réduction en pourcentage.
// - fixedAmount : réduction avec un montant fixe.
enum DiscountType { percentage, fixedAmount }

// ============================================================================
// Coupon model
// ============================================================================

// Modèle représentant un coupon de réduction.
//
// Ce modèle permet de gérer les codes promotionnels utilisés dans le panier,
// avec des conditions comme la date d'expiration, le montant minimum,
// la limite d'utilisation et le type de réduction.
class Coupon {
  // --------------------------------------------------------------------------
  // Properties
  // --------------------------------------------------------------------------

  // Identifiant unique du coupon.
  final String id;

  // Code saisi par l'utilisateur, par exemple : "WELCOME10".
  final String code;

  // Type de réduction : pourcentage ou montant fixe.
  final DiscountType type;

  // Valeur de la réduction.
  // Si le type est percentage, cette valeur représente un pourcentage.
  // Si le type est fixedAmount, cette valeur représente un montant fixe.
  final double value;

  // Montant minimum du panier nécessaire pour utiliser ce coupon.
  final double? minimumOrder;

  // Nombre maximum d'utilisations autorisées.
  // Si la valeur est null, le coupon peut être utilisé sans limite.
  final int? usageLimit;

  // Nombre d'utilisations déjà effectuées.
  final int usageCount;

  // Date d'expiration du coupon.
  final DateTime expiresAt;

  // Indique si le coupon est activé ou désactivé.
  final bool isActive;

  // --------------------------------------------------------------------------
  // Constructor
  // --------------------------------------------------------------------------

  const Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minimumOrder,
    this.usageLimit,
    this.usageCount = 0,
    required this.expiresAt,
    this.isActive = true,
  });

  // --------------------------------------------------------------------------
  // Computed properties
  // --------------------------------------------------------------------------

  // Vérifie si la date d'expiration du coupon est dépassée.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Vérifie si le coupon peut être utilisé.
  //
  // Un coupon est valide s'il est actif, non expiré,
  // et s'il n'a pas dépassé sa limite d'utilisation.
  bool get isValid {
    final hasUsageLeft = usageLimit == null || usageCount < usageLimit!;

    return isActive && !isExpired && hasUsageLeft;
  }

  // --------------------------------------------------------------------------
  // Business logic
  // --------------------------------------------------------------------------

  // Calcule le montant de réduction à appliquer sur le total du panier.
  //
  // Si le coupon n'est pas valide ou si le panier ne respecte pas
  // le minimum requis, la réduction retournée est 0.
  double computeDiscount(double cartTotal) {
    if (!isValid) return 0.0;

    if (minimumOrder != null && cartTotal < minimumOrder!) {
      return 0.0;
    }

    if (type == DiscountType.percentage) {
      return cartTotal * (value / 100);
    }

    return value > cartTotal ? cartTotal : value;
  }

  // --------------------------------------------------------------------------
  // Serialization
  // --------------------------------------------------------------------------

  // Crée un objet Coupon à partir d'une Map récupérée depuis la base de données.
  //
  // Le paramètre docId représente l'identifiant du document dans la base.
  factory Coupon.fromMap(Map<String, dynamic> map, String docId) {
    final couponType = map['type'] == 'percentage'
        ? DiscountType.percentage
        : DiscountType.fixedAmount;

    final minimumOrderValue = map['minimumOrder'] != null
        ? (map['minimumOrder'] as num).toDouble()
        : null;

    return Coupon(
      id: docId,
      code: map['code'] as String,
      type: couponType,
      value: (map['value'] as num).toDouble(),
      minimumOrder: minimumOrderValue,
      usageLimit: map['usageLimit'] as int?,
      usageCount: (map['usageCount'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  // Convertit l'objet Coupon en Map pour l'enregistrement dans la base.
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'type': type.name,
      'value': value,
      'minimumOrder': minimumOrder,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }
}