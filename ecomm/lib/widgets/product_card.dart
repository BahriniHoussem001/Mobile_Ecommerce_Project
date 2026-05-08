// lib/widgets/product_card.dart
//
// FIX: Overflow resolved by replacing the unbounded Column with a
// LayoutBuilder + explicit proportional sizing.
// The card now measures its own available width and derives every
// dimension from that, so it works correctly inside any grid cell size.
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/wishlist_provider.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  static const _categoryLabels = {
    ProductCategory.tops: 'Tops',
    ProductCategory.bottoms: 'Bottoms',
    ProductCategory.dresses: 'Dresses',
    ProductCategory.outerwear: 'Outerwear',
    ProductCategory.accessories: 'Accessories',
    ProductCategory.shoes: 'Shoes',
  };

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final isWishlisted = wishlist.contains(product.id);

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 160.0;
          // Derive image height from available width (3:4 ratio)
          final imgHeight = constraints.maxWidth * (4 / 3);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // ← don't expand to fill
            children: [
              // ── Image ──────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: cardWidth,
                      height: imgHeight,
                      child: product.primaryImageUrl.isNotEmpty
                          ? Image.network(
                              product.primaryImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(context),
                            )
                          : _placeholder(context),
                    ),
                  ),

                  // Sale badge
                  if (product.isOnSale)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${product.discountPercent.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),

                  // Out of stock overlay
                  if (!product.isInStock)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          color: Colors.black.withOpacity(0.35),
                          child: const Center(
                            child: Text(
                              'OUT OF\nSTOCK',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.8,
                                fontFamily: 'Inter',
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Wishlist heart
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => wishlist.toggle(product.id),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: context.bgSurface.withOpacity(0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 15,
                          color: isWishlisted ? kPrimary : context.textHint,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              // ── Category chip ───────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.bgChip,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _categoryLabels[product.category] ?? product.category.name,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: context.textSub,
                    letterSpacing: 0.3,
                    fontFamily: 'Inter',
                  ),
                ),
              ),

              const SizedBox(height: 5),

              // ── Name (max 2 lines) ──────────────────────
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 3),

              // ── Rating (only if reviewed) ───────────────
              if (product.reviewCount > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 11,
                      color: Color(0xFFD4AF37),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.textSub,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '(${product.reviewCount})',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textHint,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 4),

              // ── Price ───────────────────────────────────
              Row(
                children: [
                  Text(
                    '${product.price.toStringAsFixed(2)}DT',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  if (product.isOnSale) ...[
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${product.originalPrice!.toStringAsFixed(2)}DT',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textHint,
                          decoration: TextDecoration.lineThrough,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    color: context.bgChip,
    child: Center(
      child: Icon(Icons.image_outlined, color: context.textHint, size: 28),
    ),
  );
}
