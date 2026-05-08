// lib/pages/client/all_products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';

class AllProductsScreen extends StatefulWidget {
  final ProductCategory? initialCategory;
  const AllProductsScreen({super.key, this.initialCategory});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final _searchCtrl = TextEditingController();
  late ProductCategory? _category;
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>()
        ..setCategory(_category)
        ..setSearch('')
        ..setSortBy('newest');
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _sortLabel(String s) => switch (s) {
    'priceAsc' => 'Price ↑',
    'priceDesc' => 'Price ↓',
    'rating' => 'Top Rated',
    _ => 'Newest',
  };

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...[
              ('newest', 'Newest First'),
              ('priceAsc', 'Price: Low → High'),
              ('priceDesc', 'Price: High → Low'),
              ('rating', 'Top Rated'),
            ].map(
              (o) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  o.$2,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: _sort == o.$1
                        ? context.textPrimary
                        : context.textBody,
                    fontWeight: _sort == o.$1
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                trailing: _sort == o.$1
                    ? Icon(Icons.check, color: context.textPrimary, size: 20)
                    : null,
                onTap: () {
                  setState(() => _sort = o.$1);
                  context.read<ProductProvider>().setSortBy(o.$1);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final products = prov.filtered;

    return Scaffold(
      backgroundColor: context.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The Atelier',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  // Wishlist icon with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(
                          wishlist.count > 0
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: context.textPrimary,
                          size: 22,
                        ),
                        onPressed: () => Navigator.of(
                          context,
                        ).push(_route(const WishlistScreen())),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      if (wishlist.count > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: kPrimaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${wishlist.count}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Cart icon with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shopping_bag_outlined,
                          color: context.textPrimary,
                          size: 22,
                        ),
                        onPressed: () => Navigator.of(
                          context,
                        ).push(_route(const CartScreen())),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: kPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${cart.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Search bar ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AtelierSearchBar(
                controller: _searchCtrl,
                onChanged: (q) => prov.setSearch(q),
                hint: 'Search products...',
              ),
            ),

            const SizedBox(height: 12),

            // ── Category chips ───────────────────────────
            CategoryChipBar(
              selected: _category,
              onSelected: (c) {
                setState(() => _category = c);
                prov.setCategory(c);
              },
            ),

            const SizedBox(height: 12),

            // ── Results bar ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${products.length} products',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSub,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showSortSheet,
                    child: Row(
                      children: [
                        Icon(Icons.sort, size: 16, color: context.textPrimary),
                        const SizedBox(width: 4),
                        Text(
                          _sortLabel(_sort),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Grid ─────────────────────────────────────
            Expanded(
              child: prov.state == ProductLoadState.loading
                  ? GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 20,
                          ),
                      itemCount: 6,
                      itemBuilder: (_, __) => const ProductShimmer(),
                    )
                  : products.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No products found',
                      subtitle: 'Try a different category or search term.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            // 0.52 = tall enough for image (3:4) + all text
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 20,
                          ),
                      itemCount: products.length,
                      itemBuilder: (ctx, i) => ProductCard(
                        product: products[i],
                        onTap: () => Navigator.of(ctx).push(
                          _route(ProductDetailScreen(product: products[i])),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
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
