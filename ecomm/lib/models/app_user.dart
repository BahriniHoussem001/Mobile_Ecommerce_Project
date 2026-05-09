// ============================================================================
// User roles
// ============================================================================

// Définit les rôles possibles dans l'application.
// - client : utilisateur normal de l'application.
// - admin  : utilisateur avec accès à l'espace d'administration.
enum UserRole { client, admin }

// ============================================================================
// AppUser model
// ============================================================================

// Modèle principal représentant un utilisateur de l'application.
class AppUser {
  // --------------------------------------------------------------------------
  // Properties
  // --------------------------------------------------------------------------

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final String? phone;
  final List<ShippingAddress> addresses;
  final DateTime createdAt;

  // --------------------------------------------------------------------------
  // Constructor
  // --------------------------------------------------------------------------

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

  // --------------------------------------------------------------------------
  // Computed properties
  // --------------------------------------------------------------------------

  // Permet de vérifier rapidement si l'utilisateur est un administrateur.
  bool get isAdmin => role == UserRole.admin;

  // --------------------------------------------------------------------------
  // Serialization
  // --------------------------------------------------------------------------

  // Convertit les données récupérées depuis la base en objet AppUser.
  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    final addressesData = map['addresses'] as List<dynamic>? ?? [];

    return AppUser(
      uid: uid,
      name: map['name'] as String,
      email: map['email'] as String,
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.client,
      photoUrl: map['photoUrl'] as String?,
      phone: map['phone'] as String?,
      addresses: addressesData
          .map((address) =>
              ShippingAddress.fromMap(address as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? 0,
      ),
    );
  }

  // Convertit l'objet AppUser en Map pour l'enregistrement dans la base.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'photoUrl': photoUrl,
      'phone': phone,
      'addresses': addresses.map((address) => address.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  // Crée une nouvelle copie de l'utilisateur avec certains champs modifiés.
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

// ============================================================================
// ShippingAddress model
// ============================================================================

// Modèle représentant une adresse de livraison associée à un utilisateur.
class ShippingAddress {
  // --------------------------------------------------------------------------
  // Properties
  // --------------------------------------------------------------------------

  final String id;
  final String label;
  final String fullName;
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final bool isDefault;

  // --------------------------------------------------------------------------
  // Constructor
  // --------------------------------------------------------------------------

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

  // --------------------------------------------------------------------------
  // Computed properties
  // --------------------------------------------------------------------------

  // Retourne l'adresse complète sous forme d'une seule chaîne.
  String get fullAddress => '$street, $city $postalCode, $country';

  // --------------------------------------------------------------------------
  // Serialization
  // --------------------------------------------------------------------------

  // Convertit une Map provenant de la base en objet ShippingAddress.
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

  // Convertit l'objet ShippingAddress en Map pour l'enregistrement.
  Map<String, dynamic> toMap() {
    return {
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
}