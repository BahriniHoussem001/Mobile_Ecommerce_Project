// lib/pages/admin/admin_dashboard_screen.dart
//
// All statistics are computed live from Firestore streams —
// no hardcoded numbers anywhere.
// Currency: Tunisian Dinar (DT)
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/admin_order_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AdminOrderProvider>();
    final products = context.watch<ProductProvider>();

    // Dynamic stats
    final totalOrders = orders.totalOrders;
    final pending = orders.pendingCount;
    final delivered = orders.deliveredCount;
    final revenue = orders.totalRevenue;
    final monthRev = orders.monthRevenue;
    final growth = orders.orderGrowthPercent;
    final allProducts = products.filtered;
    final lowStock = allProducts
        .where((p) => p.stockQuantity > 0 && p.stockQuantity <= 5)
        .length;
    final outOfStock = allProducts.where((p) => !p.isInStock).length;
    final totalProducts = allProducts.length;

    // Recent 5 orders
    final recent = orders.allOrders.take(5).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        'Live overview',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: context.textSub,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (orders.isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Orders section label ──────────────────────
          _SectionLabel('ORDERS', context),

          // ── Stats cards row 1: Total + Pending ────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'TOTAL ORDERS',
                      value: '$totalOrders',
                      badge: growth >= 0
                          ? '+${growth.toStringAsFixed(0)}%'
                          : '${growth.toStringAsFixed(0)}%',
                      badgePositive: growth >= 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'PENDING',
                      value: '$pending',
                      dotColor: pending > 0
                          ? const Color(0xFFE05050)
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Stats cards row 2: Delivered + Revenue ────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'DELIVERED',
                      value: '$delivered',
                      dotColor: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'TOTAL REVENUE',
                      value: '${revenue.toStringAsFixed(0)} DT',
                      valueSmall: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Stats cards row 3: Month revenue + Products ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'THIS MONTH',
                      value: '${monthRev.toStringAsFixed(0)} DT',
                      valueSmall: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'PRODUCTS',
                      value: '$totalProducts',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Inventory alerts ──────────────────────────
          if (lowStock > 0 || outOfStock > 0) ...[
            _SectionLabel('INVENTORY ALERTS', context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    if (outOfStock > 0)
                      _AlertRow(
                        icon: Icons.remove_shopping_cart_outlined,
                        color: kError,
                        label:
                            '$outOfStock product${outOfStock > 1 ? 's' : ''} out of stock',
                      ),
                    if (lowStock > 0) ...[
                      const SizedBox(height: 8),
                      _AlertRow(
                        icon: Icons.warning_amber_outlined,
                        color: const Color(0xFFBA7517),
                        label:
                            '$lowStock product${lowStock > 1 ? 's' : ''} low on stock (≤ 5)',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],

          // ── Status breakdown ──────────────────────────
          _SectionLabel('ORDER BREAKDOWN', context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border, width: 1),
                ),
                child: Column(
                  children: OrderStatus.values.map((s) {
                    final count = orders.allOrders
                        .where((o) => o.status == s)
                        .length;
                    final pct = totalOrders == 0 ? 0.0 : count / totalOrders;
                    return _BreakdownRow(status: s, count: count, pct: pct);
                  }).toList(),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Recent orders ─────────────────────────────
          if (recent.isNotEmpty) ...[
            _SectionLabel('RECENT ORDERS', context),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _RecentOrderRow(order: recent[i]),
                childCount: recent.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Section label helper ──────────────────────────────────────
Widget _SectionLabel(String text, BuildContext context) => SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
        color: context.textSub,
      ),
    ),
  ),
);

// ── Stat card ──────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;
  final bool badgePositive;
  final Color? dotColor;
  final bool valueSmall;

  const _StatCard({
    required this.label,
    required this.value,
    this.badge,
    this.badgePositive = true,
    this.dotColor,
    this.valueSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  color: context.textSub,
                ),
              ),
              const Spacer(),
              if (dotColor != null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: valueSmall ? 20 : 28,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    height: 1,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgePositive
                        ? const Color(0xFF2E7D32).withOpacity(0.12)
                        : kError.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      color: badgePositive ? const Color(0xFF2E7D32) : kError,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Alert row ──────────────────────────────────────────────────
class _AlertRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _AlertRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25), width: 1),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: color,
            fontFamily: 'Inter',
          ),
        ),
      ],
    ),
  );
}

// ── Breakdown row ──────────────────────────────────────────────
class _BreakdownRow extends StatelessWidget {
  final OrderStatus status;
  final int count;
  final double pct;
  const _BreakdownRow({
    required this.status,
    required this.count,
    required this.pct,
  });

  static const _colors = {
    OrderStatus.pending: Color(0xFFA07000),
    OrderStatus.confirmed: Color(0xFF1A56DB),
    OrderStatus.processing: Color(0xFF5B5BD6),
    OrderStatus.shipped: Color(0xFF0077B6),
    OrderStatus.delivered: Color(0xFF2E7D32),
    OrderStatus.cancelled: Color(0xFFE05050),
    OrderStatus.refunded: Color(0xFF888888),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? context.textSub;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              status.name[0].toUpperCase() + status.name.substring(1),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: context.textBody,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: context.bgChip,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.textSub,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent order row ───────────────────────────────────────────
class _RecentOrderRow extends StatelessWidget {
  final Order order;
  const _RecentOrderRow({required this.order});

  static const _statusColors = {
    OrderStatus.pending: Color(0xFFA07000),
    OrderStatus.confirmed: Color(0xFF1A56DB),
    OrderStatus.processing: Color(0xFF5B5BD6),
    OrderStatus.shipped: Color(0xFF0077B6),
    OrderStatus.delivered: Color(0xFF2E7D32),
    OrderStatus.cancelled: Color(0xFFE05050),
    OrderStatus.refunded: Color(0xFF888888),
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[order.status] ?? context.textSub;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.bgChip,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  order.shippingAddress.fullName.isNotEmpty
                      ? order.shippingAddress.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.shippingAddress.fullName,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    '#ORD-${order.id.substring(0, 6).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.textSub,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.status.name[0].toUpperCase() +
                        order.status.name.substring(1),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.total.toStringAsFixed(0)} DT',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
