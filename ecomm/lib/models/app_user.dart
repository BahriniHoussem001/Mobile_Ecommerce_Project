enum UserRole { client, admin }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final String? phone;
  final List<ShippingAddress> addresses;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = UserRole.client,
    this.photoUrl,
    this.phone,
    this.addresses = const [],
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      name: map['name'] as String,
      email: map['email'] as String,
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.client,
      photoUrl: map['photoUrl'] as String?,
      phone: map['phone'] as String?,
      addresses: (map['addresses'] as List<dynamic>? ?? [])
          .map((a) => ShippingAddress.fromMap(a as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role.name,
    'photoUrl': photoUrl,
    'phone': phone,
    'addresses': addresses.map((a) => a.toMap()).toList(),
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  AppUser copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    List<ShippingAddress>? addresses,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt,
    );
  }
}

class ShippingAddress {
  final String id;
  final String label; // e.g. "Home", "Office"
  final String fullName;
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final bool isDefault;

  const ShippingAddress({
    required this.id,
    required this.label,
    required this.fullName,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
    this.isDefault = false,
  });

  String get fullAddress => '$street, $city $postalCode, $country';

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      id: map['id'] as String,
      label: map['label'] as String,
      fullName: map['fullName'] as String,
      street: map['street'] as String,
      city: map['city'] as String,
      postalCode: map['postalCode'] as String,
      country: map['country'] as String,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'fullName': fullName,
    'street': street,
    'city': city,
    'postalCode': postalCode,
    'country': country,
    'isDefault': isDefault,
  };
}
