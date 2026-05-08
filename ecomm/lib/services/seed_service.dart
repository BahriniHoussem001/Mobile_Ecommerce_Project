import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/models.dart';

class SeedService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seed(String userId) async {
    await Future.wait([_seedProducts(), _seedCoupons()]);
    await _seedOrder(userId);
  }

  // ── Products ─────────────────────────────────────────────

  static Future<void> _seedProducts() async {
    final col = _db.collection('products');

    final products = [
      // ── Tops ──────────────────────────────────────────
      {
        'name': 'Raw Silk Henley',
        'description':
            'Woven from pure raw silk with a subtle textured grain. The relaxed henley silhouette pairs effortlessly with tailored trousers or slim denim.',
        'price': 90.0,
        'originalPrice': null,
        'imageUrls': [
          'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=600',
        ],
        'category': 'tops',
        'availableSizes': ['XS', 'S', 'M', 'L', 'XL'],
        'availableColors': ['Bone', 'Midnight', 'Clay'],
        'stockQuantity': 42,
        'isFeatured': true,
        'rating': 4.7,
        'reviewCount': 38,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'name': 'Merino Ribbed Polo',
        'description':
            'Extra-fine merino wool in a classic ribbed knit. Lightweight enough for four seasons, refined enough for any occasion.',
        'price': 110.0,
        'originalPrice': 150.0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=600',
        ],
        'category': 'tops',
        'availableSizes': ['S', 'M', 'L', 'XL'],
        'availableColors': ['Navy', 'Cream', 'Forest Green'],
        'stockQuantity': 20,
        'isFeatured': false,
        'rating': 4.5,
        'reviewCount': 22,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch,
      },

      // ── Bottoms ────────────────────────────────────────
      {
        'name': 'Timeless Tailored Trousers',
        'description':
            'Brown tailored trousers combine classic elegance with modern comfort. Designed with a refined textured fabric, perfect for formal occasions and smart-casual looks.',
        'price': 130.0,
        'originalPrice': null,
        'imageUrls': [
          'https://images.unsplash.com/photo-1594938374182-a57369db7f5c?w=600',
        ],
        'category': 'bottoms',
        'availableSizes': ['28', '30', '32', '34', '36'],
        'availableColors': ['Stone', 'Charcoal', 'Camel'],
        'stockQuantity': 15,
        'isFeatured': true,
        'rating': 4.8,
        'reviewCount': 54,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
      },
      {
        'name': 'Wide-Leg Linen Pants',
        'description':
            'Relaxed wide-leg silhouette in breathable European linen. An elevated wardrobe essential for warm-weather dressing.',
        'price': 120.0,
        'originalPrice': 160.0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=600',
        ],
        'category': 'bottoms',
        'availableSizes': ['XS', 'S', 'M', 'L'],
        'availableColors': ['Ecru', 'Black', 'Sage'],
        'stockQuantity': 8,
        'isFeatured': false,
        'rating': 4.3,
        'reviewCount': 17,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
      },

      // ── Dresses ───────────────────────────────────────
      {
        'name': 'The Silk Slip Dress',
        'description':
            'Fluid silk charmeuse with a bias cut that moves beautifully. A versatile piece worn alone or layered over a turtleneck.',
        'price': 195.0,
        'originalPrice': null,
        'imageUrls': [
          'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=600',
        ],
        'category': 'dresses',
        'availableSizes': ['XS', 'S', 'M', 'L'],
        'availableColors': ['Champagne', 'Midnight', 'Blush'],
        'stockQuantity': 12,
        'isFeatured': true,
        'rating': 4.9,
        'reviewCount': 73,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 2))
            .millisecondsSinceEpoch,
      },
      {
        'name': 'Structured Wool Shift',
        'description':
            'Architectural shift dress in a refined double-faced wool. The clean lines and minimalist silhouette make it a season-less piece.',
        'price': 220.0,
        'originalPrice': 280.0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=600',
        ],
        'category': 'dresses',
        'availableSizes': ['XS', 'S', 'M', 'L', 'XL'],
        'availableColors': ['Camel', 'Ivory', 'Slate'],
        'stockQuantity': 6,
        'isFeatured': false,
        'rating': 4.6,
        'reviewCount': 29,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 5))
            .millisecondsSinceEpoch,
      },

      // ── Outerwear ─────────────────────────────────────
      {
        'name': 'Wool Blend Overcoat',
        'description':
            'A sculptural overcoat in a premium wool blend with a single-breasted front and clean notch lapels. The Atelier\'s most iconic piece.',
        'price': 280.0,
        'originalPrice': null,
        'imageUrls': [
          'https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=600',
        ],
        'category': 'outerwear',
        'availableSizes': ['S', 'M', 'L', 'XL', 'XXL'],
        'availableColors': ['Sandstone', 'Charcoal', 'Midnight'],
        'stockQuantity': 25,
        'isFeatured': true,
        'rating': 4.9,
        'reviewCount': 112,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 0))
            .millisecondsSinceEpoch,
      },
      {
        'name': 'The Essential Trench',
        'description':
            'A heritage trench coat updated for the modern wardrobe. Water-resistant cotton gabardine with signature storm flap and D-ring belt.',
        'price': 320.0,
        'originalPrice': 400.0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600',
        ],
        'category': 'outerwear',
        'availableSizes': ['XS', 'S', 'M', 'L', 'XL'],
        'availableColors': ['Sand', 'Black', 'Forest Green'],
        'stockQuantity': 18,
        'isFeatured': true,
        'rating': 4.8,
        'reviewCount': 88,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 4))
            .millisecondsSinceEpoch,
      },

      // ── Accessories ────────────────────────────────────
      {
        'name': 'Geometric Silk Scarf',
        'description':
            'Hand-rolled edges on 100% Italian silk. An exclusive geometric print designed in collaboration with a Milanese studio.',
        'price': 60.0,
        'originalPrice': null,
        'imageUrls': [
          'https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=600',
        ],
        'category': 'accessories',
        'availableSizes': ['OS'],
        'availableColors': ['Gold & Navy', 'Rose & Ivory', 'Sage & Cream'],
        'stockQuantity': 50,
        'isFeatured': false,
        'rating': 4.7,
        'reviewCount': 45,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 6))
            .millisecondsSinceEpoch,
      },
      {
        'name': 'Chronos Series 01',
        'description':
            'Swiss-made automatic movement in a Bauhaus-inspired case. 38mm stainless steel with Italian leather strap.',
        'price': 250.0,
        'originalPrice': null,
        'imageUrls': [
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600',
        ],
        'category': 'accessories',
        'availableSizes': ['OS'],
        'availableColors': ['Black', 'Cognac', 'Slate'],
        'stockQuantity': 10,
        'isFeatured': true,
        'rating': 4.9,
        'reviewCount': 67,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 8))
            .millisecondsSinceEpoch,
      },
      {
        'name': 'Architectural Tote',
        'description':
            'Full-grain Italian leather with a structured silhouette. Brass hardware and a canvas lining with an interior zip pocket.',
        'price': 630.0,
        'originalPrice': null,
        'imageUrls': [
          'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
        ],
        'category': 'accessories',
        'availableSizes': ['OS'],
        'availableColors': ['Cognac', 'Midnight Black', 'Sand'],
        'stockQuantity': 7,
        'isFeatured': true,
        'rating': 4.8,
        'reviewCount': 34,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 9))
            .millisecondsSinceEpoch,
      },

      // ── Shoes ─────────────────────────────────────────
      {
        'name': 'Oxford Brogue',
        'description':
            'Blake-stitched calfskin oxford with hand-applied broguing. A heritage silhouette built to last decades.',
        'price': 180.0,
        'originalPrice': null,
        'imageUrls': [
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
        ],
        'category': 'shoes',
        'availableSizes': ['40', '41', '42', '43', '44', '45'],
        'availableColors': ['Tan', 'Dark Brown', 'Black'],
        'stockQuantity': 22,
        'isFeatured': false,
        'rating': 4.7,
        'reviewCount': 59,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      },
      {
        'name': 'Suede Chelsea Boot',
        'description':
            'Fine Italian suede upper with an elastic gusset and stacked leather heel. Comfortable enough for all-day wear.',
        'price': 210.0,
        'originalPrice': 260.0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1520639888713-7851133b1ed0?w=600',
        ],
        'category': 'shoes',
        'availableSizes': ['39', '40', '41', '42', '43', '44'],
        'availableColors': ['Camel', 'Black', 'Navy'],
        'stockQuantity': 0,
        'isFeatured': false,
        'rating': 4.4,
        'reviewCount': 31,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 12))
            .millisecondsSinceEpoch,
      },
    ];

    final batch = _db.batch();
    for (final p in products) {
      batch.set(col.doc(), p);
    }
    await batch.commit();
  }

  // ── Coupons ──────────────────────────────────────────────

  static Future<void> _seedCoupons() async {
    final col = _db.collection('coupons');

    final coupons = [
      {
        'code': 'ATELIER10',
        'type': 'percentage',
        'value': 10.0,
        'minimumOrder': 100.0,
        'usageLimit': 200,
        'usageCount': 12,
        'expiresAt': DateTime.now()
            .add(const Duration(days: 60))
            .millisecondsSinceEpoch,
        'isActive': true,
      },
      {
        'code': 'WELCOME25',
        'type': 'fixedAmount',
        'value': 25.0,
        'minimumOrder': 80.0,
        'usageLimit': 1,
        'usageCount': 0,
        'expiresAt': DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
        'isActive': true,
      },
      {
        'code': 'SALE20',
        'type': 'percentage',
        'value': 20.0,
        'minimumOrder': 200.0,
        'usageLimit': null,
        'usageCount': 43,
        'expiresAt': DateTime.now()
            .add(const Duration(days: 7))
            .millisecondsSinceEpoch,
        'isActive': true,
      },
    ];

    final batch = _db.batch();
    for (final c in coupons) {
      batch.set(col.doc(), c);
    }
    await batch.commit();
  }

  // ── Sample past order ────────────────────────────────────

  static Future<void> _seedOrder(String userId) async {
    final address = ShippingAddress(
      id: 'addr_seed',
      label: 'Home',
      fullName: 'Jonathan Miller',
      street: '1248 North Highland Ave, Suite 200',
      city: 'Los Angeles',
      postalCode: 'CA 90038',
      country: 'United States',
      isDefault: true,
    );

    final items = [
      CartItem(
        productId: 'seed_p1',
        productName: 'Wool Blend Overcoat',
        imageUrl:
            'https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=400',
        unitPrice: 280.0,
        selectedSize: 'M',
        selectedColor: 'Sandstone',
      ),
      CartItem(
        productId: 'seed_p2',
        productName: 'Raw Silk Henley',
        imageUrl:
            'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=400',
        unitPrice: 90.0,
        selectedSize: 'M',
        selectedColor: 'Bone',
      ),
    ];

    final order = Order(
      id: '',
      userId: userId,
      items: items,
      shippingAddress: address,
      subtotal: 370.0,
      shippingFee: 7.0,
      discount: 0,
      total: 377.0,
      status: OrderStatus.delivered,
      paymentMethod: 'stripe',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    );

    await _db.collection('orders').add(order.toMap());
  }
}
