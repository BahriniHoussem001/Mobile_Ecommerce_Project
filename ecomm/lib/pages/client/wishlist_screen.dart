// lib/pages/client/wishlist_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final productProv = context.watch<ProductProvider>();
    final wishlistProducts = productProv.filtered
        .where((p) => wishlist.contains(p.id))
        .toList();

    return Scaffold(
      backgroundColor: context.bgPage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar ──────────────────────────────────
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
                  Icon(
                    wishlistProducts.isNotEmpty
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: context.textPrimary,
                    size: 22,
                  ),
                ],
              ),
            ),

            // ── Title ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY WISHLIST',
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1.5,
                      color: context.textSub,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${wishlistProducts.length} item${wishlistProducts.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Grid or empty state ───────────────────────
            Expanded(
              child: wishlistProducts.isEmpty
                  ? const EmptyState(
                      icon: Icons.favorite_border,
                      title: 'Nothing saved yet',
                      subtitle: 'Tap the heart on any product to save it here.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            // childAspectRatio drives cell height.
                            // Lower = taller cells. 0.52 gives enough room
                            // for image (3:4) + chip + name + rating + price.
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 20,
                          ),
                      itemCount: wishlistProducts.length,
                      itemBuilder: (ctx, i) => ProductCard(
                        product: wishlistProducts[i],
                        onTap: () => Navigator.of(ctx).push(
                          _route(
                            ProductDetailScreen(product: wishlistProducts[i]),
                          ),
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
