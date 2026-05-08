// lib/pages/admin/admin_inventory_screen.dart
//
// Product management screen.
// • Lists all products from ProductProvider (live)
// • FAB (+) navigates to AddEditProductScreen
// • Each row: image, name, category, stock, price in DT
// • Tap row → edit; swipe left → confirm delete
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import 'add_edit_product_screen.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete Product',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
            fontSize: 17,
          ),
        ),
        content: Text(
          '"${p.name}" will be permanently removed from inventory.',
          style: TextStyle(
            fontSize: 13.5,
            color: context.textSub,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.textHint)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kError,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await context.read<ProductProvider>().deleteProduct(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${p.name}" deleted.',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            backgroundColor: kError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final products = prov.filtered;

    // Stats
    final total = prov.filtered.length;
    final outOfStock = products.where((p) => !p.isInStock).length;
    final onSale = products.where((p) => p.isOnSale).length;

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
                  Text(
                    'Inventory',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$total products',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSub,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

            // ── Inventory quick stats ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _QuickStat(
                    label: 'Total',
                    value: '$total',
                    color: context.textPrimary,
                  ),
                  const SizedBox(width: 12),
                  _QuickStat(
                    label: 'Out of stock',
                    value: '$outOfStock',
                    color: kError,
                  ),
                  const SizedBox(width: 12),
                  _QuickStat(
                    label: 'On sale',
                    value: '$onSale',
                    color: const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Search ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AtelierSearchBar(
                controller: _searchCtrl,
                onChanged: prov.setSearch,
                hint: 'Search products...',
              ),
            ),

            const SizedBox(height: 14),

            // ── List ──────────────────────────────────────
            Expanded(
              child: prov.state == ProductLoadState.loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.textPrimary,
                      ),
                    )
                  : products.isEmpty
                  ? const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No products',
                      subtitle: 'Tap + to add your first product.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: products.length,
                      itemBuilder: (ctx, i) => Dismissible(
                        key: Key(products[i].id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          bool confirmed = false;
                          await showDialog(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              backgroundColor: context.bgSurface,
                              title: Text(
                                'Delete "${products[i].name}"?',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                ),
                              ),
                              content: Text(
                                'This cannot be undone.',
                                style: TextStyle(
                                  color: context.textSub,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dCtx),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: context.textHint),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    confirmed = true;
                                    Navigator.pop(dCtx);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kError,
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          return confirmed;
                        },
                        onDismissed: (_) => context
                            .read<ProductProvider>()
                            .deleteProduct(products[i].id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: kError.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: kError,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: kError,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        child: _ProductRow(
                          product: products[i],
                          onTap: () => Navigator.of(ctx).push(
                            _route(AddEditProductScreen(product: products[i])),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),

      // ── FAB — add product ────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).push(_route(const AddEditProductScreen())),
        backgroundColor: context.textPrimary,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}

// ── Quick stat chip ────────────────────────────────────────────
class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _QuickStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Product list row ───────────────────────────────────────────
class _ProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductRow({required this.product, required this.onTap});

  static const _catLabels = {
    ProductCategory.tops: 'Tops',
    ProductCategory.bottoms: 'Bottoms',
    ProductCategory.dresses: 'Dresses',
    ProductCategory.outerwear: 'Outerwear',
    ProductCategory.accessories: 'Accessories',
    ProductCategory.shoes: 'Shoes',
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 64,
              child: product.primaryImageUrl.isNotEmpty
                  ? Image.network(
                      product.primaryImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: context.bgChip),
                    )
                  : Container(
                      color: context.bgChip,
                      child: Icon(
                        Icons.image_outlined,
                        color: context.textHint,
                        size: 22,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.bgChip,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        _catLabels[product.category] ?? product.category.name,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: context.textSub,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: product.isInStock
                            ? const Color(0xFF2E7D32).withOpacity(0.1)
                            : kError.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        product.isInStock
                            ? '${product.stockQuantity} in stock'
                            : 'Out of stock',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                          color: product.isInStock
                              ? const Color(0xFF2E7D32)
                              : kError,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.price.toStringAsFixed(0)} DT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              if (product.isOnSale)
                Text(
                  '${product.originalPrice!.toStringAsFixed(0)} DT',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textHint,
                    decoration: TextDecoration.lineThrough,
                    fontFamily: 'Inter',
                  ),
                ),
              const SizedBox(height: 4),
              Icon(Icons.edit_outlined, color: context.textHint, size: 16),
            ],
          ),
        ],
      ),
    ),
  );
}

PageRoute _route(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionDuration: const Duration(milliseconds: 300),
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
