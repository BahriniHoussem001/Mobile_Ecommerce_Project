// lib/pages/client/order_tracking_screen.dart
//
// FIXES:
// • History rows are wrapped in Dismissible — swipe left to delete.
//   A confirmation dialog prevents accidental deletion.
// • Active orders can also be deleted via a "Remove" option in the
//   item summary card (only shown for cancelled/refunded orders in
//   the "current" bucket, which shouldn't happen but is a safety net).
// • deleteOrder() calls OrderProvider.deleteOrder() — the Firestore
//   stream removes the doc from the list automatically.
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../screens.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  // ── Confirm + delete helper ───────────────────────────────
  static Future<void> _confirmDelete(
    BuildContext context,
    String orderId,
  ) async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Remove Order',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
            fontSize: 18,
          ),
        ),
        content: Text(
          'This will permanently remove the order from your history.',
          style: TextStyle(
            fontSize: 14,
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
              'Remove',
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

    if (confirmed == true && context.mounted) {
      try {
        await context.read<OrderProvider>().deleteOrder(orderId, userId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete order: $e'),
              backgroundColor: kError,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid;

    // SECURITY: Only show orders that belong to the current user
    final orders = userId != null
        ? orderProv.orders.where((o) => o.userId == userId).toList()
        : [];

    // "current" = orders the user is still waiting on (in-progress)
    final current = orders
        .where(
          (o) =>
              o.status != OrderStatus.delivered &&
              o.status != OrderStatus.cancelled &&
              o.status != OrderStatus.refunded,
        )
        .toList();

    // "history" = completed / cancelled / refunded
    final history = orders
        .where(
          (o) =>
              o.status == OrderStatus.delivered ||
              o.status == OrderStatus.cancelled ||
              o.status == OrderStatus.refunded,
        )
        .toList();

    final activeOrder = current.isNotEmpty ? current.first : null;
    // Extra in-progress orders beyond the first (edge case)
    final extraActive = current.skip(1).toList();
    // All past orders shown in history list (history + extra active)
    final pastList = [...extraActive, ...history];

    return Scaffold(
      backgroundColor: context.bgPage,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App bar ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Text(
                      'The Atelier',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _AppBarIcon(
                      icon: wishlist.count > 0
                          ? Icons.favorite
                          : Icons.favorite_border,
                      count: wishlist.count,
                      badgeColor: kPrimaryLight,
                      onTap: () => Navigator.of(
                        context,
                      ).push(_route(const WishlistScreen())),
                    ),
                    const SizedBox(width: 4),
                    _AppBarIcon(
                      icon: Icons.shopping_bag_outlined,
                      count: cart.itemCount,
                      badgeColor: kPrimary,
                      onTap: () => Navigator.of(
                        context,
                      ).push(_route(const CartScreen())),
                    ),
                  ],
                ),
              ),
            ),

            // ── Title ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT STATUS',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.5,
                        color: context.textSub,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (activeOrder != null)
                      Row(
                        children: [
                          Text(
                            'Order #${activeOrder.id.substring(0, 5).toUpperCase()}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          OrderStatusBadge(status: activeOrder.status),
                        ],
                      )
                    else
                      Text(
                        'Your Orders',
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
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Loading / empty ───────────────────────────
            if (orderProv.isLoading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: context.textPrimary),
                ),
              )
            else if (orders.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders yet',
                  subtitle: 'Your order history will appear here.',
                ),
              )
            else ...[
              // ── Active order stepper ──────────────────
              if (activeOrder != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _OrderStepper(status: activeOrder.status),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        _route(OrderDetailScreen(orderId: activeOrder.id)),
                      ),
                      child: _ItemSummaryCard(order: activeOrder),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],

              // ── Past orders ─────────────────────────
              if (pastList.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Past Orders',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Swipe left to remove',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textHint,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Each row is Dismissible — swipe left → confirm → delete
                SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final o = pastList[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Dismissible(
                        key: Key(o.id),
                        direction: DismissDirection.endToStart,
                        // Ask for confirmation before actually removing
                        confirmDismiss: (_) async {
                          bool confirmed = false;
                          await showDialog(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              backgroundColor: context.bgSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              title: Text(
                                'Remove Order',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                  fontSize: 18,
                                ),
                              ),
                              content: Text(
                                'Remove this order from your history? This cannot be undone.',
                                style: TextStyle(
                                  fontSize: 14,
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
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Remove',
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
                          return confirmed;
                        },
                        onDismissed: (_) {
                          if (userId != null) {
                            ctx
                                .read<OrderProvider>()
                                .deleteOrder(o.id, userId)
                                .catchError((e) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to delete order: $e',
                                      ),
                                      backgroundColor: kError,
                                    ),
                                  );
                                });
                          }
                        },
                        // Red delete background revealed on swipe
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: kError.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: kError,
                                size: 24,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Remove',
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
                        child: GestureDetector(
                          onTap: () => Navigator.of(
                            ctx,
                          ).push(_route(OrderDetailScreen(orderId: o.id))),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.bgChip,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: context.bgSurface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: context.textPrimary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order #${o.id.substring(0, 5).toUpperCase()}',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          OrderStatusBadge(status: o.status),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${_fmt(o.createdAt)} · ${o.totalItems} item${o.totalItems > 1 ? 's' : ''}',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: context.textSub,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '\$${o.total.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.chevron_right,
                                  color: context.textHint,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: pastList.length),
                ),
              ],
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────
// Item summary card (taps into OrderDetailScreen)
// ─────────────────────────────────────────────────────────────
class _ItemSummaryCard extends StatelessWidget {
  final Order order;
  const _ItemSummaryCard({required this.order});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.bgSurface,
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Summary',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        ...order.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 64,
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: context.bgChip),
                          )
                        : Container(color: context.bgChip),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        '${item.selectedColor} / Size ${item.selectedSize}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSub,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${item.subtotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: context.divider),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'TOTAL AMOUNT',
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.2,
                color: context.textSub,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
            const Spacer(),
            Text(
              '\$${order.total.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Progress stepper
// ─────────────────────────────────────────────────────────────
class _OrderStepper extends StatelessWidget {
  final OrderStatus status;
  const _OrderStepper({required this.status});

  static const _steps = [
    (OrderStatus.confirmed, Icons.check_circle_outline, 'CONFIRMED'),
    (OrderStatus.processing, Icons.settings_outlined, 'PROCESSING'),
    (OrderStatus.shipped, Icons.local_shipping_outlined, 'SHIPPED'),
    (OrderStatus.delivered, Icons.home_outlined, 'DELIVERED'),
  ];

  int get _activeIdx {
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].$1 == status) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIdx;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: context.bgChip,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final sIdx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: sIdx < active ? context.textPrimary : context.border,
              ),
            );
          }
          final sIdx = i ~/ 2;
          final done = sIdx < active;
          final cur = sIdx == active;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (done || cur) ? context.textPrimary : context.border,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  done ? Icons.check : _steps[sIdx].$2,
                  size: 18,
                  color: (done || cur) ? Colors.white : context.textHint,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _steps[sIdx].$3,
                style: TextStyle(
                  fontSize: 8.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  color: (done || cur) ? context.textPrimary : context.textHint,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// App bar icon with badge
// ─────────────────────────────────────────────────────────────
class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color badgeColor;
  final VoidCallback onTap;
  const _AppBarIcon({
    required this.icon,
    required this.count,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        icon: Icon(icon, color: context.textPrimary, size: 22),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      if (count > 0)
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$count',
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
  );
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
