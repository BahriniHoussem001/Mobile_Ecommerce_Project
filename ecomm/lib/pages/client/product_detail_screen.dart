import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  String? _selectedColor;
  int _currentImageIndex = 0;
  bool _materialsExpanded = false;
  bool _fitExpanded = false;

  Product get _p => widget.product;

  @override
  void initState() {
    super.initState();
    if (_p.availableSizes.isNotEmpty) _selectedSize = _p.availableSizes.first;
    if (_p.availableColors.isNotEmpty)
      _selectedColor = _p.availableColors.first;
  }

  void _addToCart() {
    if (_selectedSize == null || _selectedColor == null) return;
    context.read<CartProvider>().addItem(
      CartItem(
        productId: _p.id,
        productName: _p.name,
        imageUrl: _p.primaryImageUrl,
        unitPrice: _p.price,
        selectedSize: _selectedSize!,
        selectedColor: _selectedColor!,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_p.name} added to cart',
          style: const TextStyle(fontFamily: 'Inter'),
        ),
        backgroundColor: const Color(0xFF1B3A6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white70,
          onPressed: () =>
              Navigator.of(context).push(_route(const CartScreen())),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final isWishlisted = wishlist.contains(_p.id);
    final related = context
        .watch<ProductProvider>()
        .filtered
        .where((p) => p.category == _p.category && p.id != _p.id)
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero image with back + wishlist ─────────────
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Safe area header bar (sits above the image)
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 24,
                                color: Color(0xFF1B3A6B),
                              ),
                            ),
                            const Text(
                              'The Atelier',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 26,
                                color: Color(0xFF1B3A6B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => wishlist.toggle(_p.id),
                              child: Icon(
                                isWishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 24,
                                color: isWishlisted
                                    ? const Color(0xFF1B3A6B)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Image area (now BELOW the header, no overlap)
                    SizedBox(
                      height: 420,
                      width: double.infinity,
                      child: _p.imageUrls.isNotEmpty
                          ? Stack(
                              children: [
                                PageView.builder(
                                  itemCount: _p.imageUrls.length,
                                  onPageChanged: (i) =>
                                      setState(() => _currentImageIndex = i),
                                  itemBuilder: (_, i) => Image.network(
                                    _p.imageUrls[i],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFE8E4DE),
                                      child: const Icon(
                                        Icons.image_outlined,
                                        size: 48,
                                        color: Color(0xFFCCCCCC),
                                      ),
                                    ),
                                  ),
                                ),
                                // Page dots
                                if (_p.imageUrls.length > 1)
                                  Positioned(
                                    bottom: 14,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        _p.imageUrls.length,
                                        (i) => AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          width: i == _currentImageIndex
                                              ? 20
                                              : 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: i == _currentImageIndex
                                                ? const Color(0xFF1B3A6B)
                                                : Colors.white.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Container(
                              color: const Color(0xFFE8E4DE),
                              child: const Icon(
                                Icons.image_outlined,
                                size: 64,
                                color: Color(0xFFCCCCCC),
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // ── Product info card ─────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Collection tag + price
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PREMIUM COLLECTION',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8899CC),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_p.price.toStringAsFixed(0)}DT',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B3A6B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Name
                            Text(
                              _p.name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B3A6B),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Description
                            Text(
                              _p.description,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF666666),
                                height: 1.65,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Color selector
                            const Text(
                              'SELECT COLOR',
                              style: TextStyle(
                                fontSize: 10.5,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF888888),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              children: _p.availableColors.map((color) {
                                final isSelected = _selectedColor == color;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedColor = color),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: _colorFromName(color),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF1B3A6B)
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF1B3A6B,
                                                ).withOpacity(0.25),
                                                blurRadius: 6,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 22),

                            // Size selector
                            const Text(
                              'SELECT SIZE',
                              style: TextStyle(
                                fontSize: 10.5,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF888888),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _p.availableSizes.map((size) {
                                final isSelected = _selectedSize == size;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedSize = size),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 56,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF1B3A6B)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF1B3A6B)
                                            : const Color(0xFFDDDDDD),
                                        width: 1.4,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        size,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF444444),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // ── Accordion: Materials ───────────────
                      _AccordionTile(
                        title: 'Materials & Details',
                        content:
                            '100% Premium Wool outer shell. Polyester lining. Dry clean recommended. Made in Italy.',
                        isExpanded: _materialsExpanded,
                        onToggle: () => setState(
                          () => _materialsExpanded = !_materialsExpanded,
                        ),
                      ),
                      _AccordionTile(
                        title: 'Fit & Care',
                        content:
                            'Regular fit. Model is 6\'1" wearing size M. We recommend sizing up for a relaxed look.',
                        isExpanded: _fitExpanded,
                        onToggle: () =>
                            setState(() => _fitExpanded = !_fitExpanded),
                      ),

                      const SizedBox(height: 28),

                      // ── You May Also Like ──────────────────
                      if (related.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'You May Also Like',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B3A6B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 300,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: related.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (ctx, i) => SizedBox(
                              // ← add this
                              width: 160, // ← explicit width
                              child: ProductCard(
                                product: related[i],
                                onTap: () => Navigator.of(ctx).pushReplacement(
                                  _route(
                                    ProductDetailScreen(product: related[i]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Space for bottom bar
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Sticky bottom bar ──────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: const Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'TOTAL PRICE',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_p.price.toStringAsFixed(0)}DT',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B3A6B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _p.isInStock ? _addToCart : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3A6B),
                          disabledBackgroundColor: const Color(0xFFCCCCCC),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _p.isInStock ? 'Add to Cart' : 'Out of Stock',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('black')) return Colors.black87;
    if (lower.contains('white')) return Colors.white;
    if (lower.contains('navy') || lower.contains('blue'))
      return const Color(0xFF1B3A6B);
    if (lower.contains('green')) return const Color(0xFF3D6B4A);
    if (lower.contains('sand') ||
        lower.contains('beige') ||
        lower.contains('camel'))
      return const Color(0xFFB5956A);
    if (lower.contains('grey') || lower.contains('gray'))
      return const Color(0xFF888888);
    if (lower.contains('red')) return const Color(0xFFB53A3A);
    if (lower.contains('cream')) return const Color(0xFFF5EDE3);
    // fallback: generate from string hash
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return Color(0xFF000000 | (hash * 13756733) & 0x00FFFFFF);
  }
}

class _AccordionTile extends StatelessWidget {
  final String title;
  final String content;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _AccordionTile({
    required this.title,
    required this.content,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1B3A6B),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF1B3A6B),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF777777),
                height: 1.6,
              ),
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

PageRoute _route(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionDuration: const Duration(milliseconds: 320),
  transitionsBuilder: (_, anim, __, child) => FadeTransition(
    opacity: anim,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
      child: child,
    ),
  ),
);
