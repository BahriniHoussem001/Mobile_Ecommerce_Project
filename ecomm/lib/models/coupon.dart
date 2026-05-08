enum DiscountType { percentage, fixedAmount }

class Coupon {
  final String id;
  final String code;
  final DiscountType type;
  final double value; // % or fixed amount in currency
  final double? minimumOrder; // min cart total to apply
  final int? usageLimit; // null = unlimited
  final int usageCount;
  final DateTime expiresAt;
  final bool isActive;

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

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid =>
      isActive &&
      !isExpired &&
      (usageLimit == null || usageCount < usageLimit!);

  /// Returns the discount amount to subtract from [cartTotal].
  double computeDiscount(double cartTotal) {
    if (!isValid) return 0.0;
    if (minimumOrder != null && cartTotal < minimumOrder!) return 0.0;
    if (type == DiscountType.percentage) {
      return cartTotal * (value / 100);
    }
    return value > cartTotal ? cartTotal : value;
  }

  factory Coupon.fromMap(Map<String, dynamic> map, String docId) {
    return Coupon(
      id: docId,
      code: map['code'] as String,
      type: map['type'] == 'percentage'
          ? DiscountType.percentage
          : DiscountType.fixedAmount,
      value: (map['value'] as num).toDouble(),
      minimumOrder: map['minimumOrder'] != null
          ? (map['minimumOrder'] as num).toDouble()
          : null,
      usageLimit: map['usageLimit'] as int?,
      usageCount: (map['usageCount'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
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
