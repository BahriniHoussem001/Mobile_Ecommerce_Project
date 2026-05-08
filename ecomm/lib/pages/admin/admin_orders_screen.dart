// lib/pages/admin/admin_orders_screen.dart
//
// Matches the "Order Management" mockup exactly:
// • Stats cards (Total Orders with growth %, Pending with red dot)
// • Search by Order ID or customer name
// • Status filter chips: All / Pending / Shipped / Delivered (+ more)
// • Order rows: avatar initial, name, order ID, status badge, date, total in DT
// All data is live from AdminOrderProvider — no dummy values.
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/admin_order_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminOrderProvider>();
    final orders = prov.filtered;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── App bar ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Text(
                  'Order Management',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.more_vert, color: context.textSub, size: 22),
              ],
            ),
          ),

          // ── Stat cards ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    label: 'TOTAL ORDERS',
                    value: '${prov.totalOrders}',
                    badge: prov.orderGrowthPercent >= 0
                        ? '+${prov.orderGrowthPercent.toStringAsFixed(0)}%'
                        : '${prov.orderGrowthPercent.toStringAsFixed(0)}%',
                    badgePositive: prov.orderGrowthPercent >= 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStatCard(
                    label: 'PENDING',
                    value: '${prov.pendingCount}',
                    dotColor: prov.pendingCount > 0
                        ? const Color(0xFFE05050)
                        : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Search bar ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: context.bgChip,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.border, width: 1),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: prov.setSearch,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textBody,
                  fontFamily: 'Inter',
                ),
                decoration: InputDecoration(
                  hintText: 'Search Order ID or Customer Name',
                  hintStyle: TextStyle(
                    color: context.textHint,
                    fontSize: 13.5,
                    fontFamily: 'Inter',
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.textHint,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Filter chips ─────────────────────────────
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                  label: 'All',
                  active: prov.filterStatus == null,
                  onTap: () => prov.setFilter(null),
                ),
                ...[
                  OrderStatus.pending,
                  OrderStatus.confirmed,
                  OrderStatus.processing,
                  OrderStatus.shipped,
                  OrderStatus.delivered,
                  OrderStatus.cancelled,
                  OrderStatus.refunded,
                ].map(
                  (s) => _FilterChip(
                    label: s.name[0].toUpperCase() + s.name.substring(1),
                    active: prov.filterStatus == s,
                    onTap: () => prov.setFilter(s),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Orders list ──────────────────────────────
          Expanded(
            child: prov.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: context.textPrimary,
                    ),
                  )
                : orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: context.textHint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No orders found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.textSub,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: orders.length,
                    itemBuilder: (ctx, i) => _OrderRow(order: orders[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Mini stat card ─────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;
  final bool badgePositive;
  final Color? dotColor;

  const _MiniStatCard({
    required this.label,
    required this.value,
    this.badge,
    this.badgePositive = true,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) => Container(
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
                fontSize: 9,
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
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

// ── Filter chip ────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? context.textPrimary : context.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? context.textPrimary : context.border,
          width: 1.2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          fontFamily: 'Inter',
          color: active ? Colors.white : context.textBody,
        ),
      ),
    ),
  );
}

// ── Order row (matches mockup) ─────────────────────────────────
class _OrderRow extends StatelessWidget {
  final Order order;
  const _OrderRow({required this.order});

  static const _statusColors = {
    OrderStatus.pending: Color(0xFFA07000),
    OrderStatus.confirmed: Color(0xFF1A56DB),
    OrderStatus.processing: Color(0xFF5B5BD6),
    OrderStatus.shipped: Color(0xFF0077B6),
    OrderStatus.delivered: Color(0xFF2E7D32),
    OrderStatus.cancelled: Color(0xFFE05050),
    OrderStatus.refunded: Color(0xFF888888),
  };

  static const _statusBgs = {
    OrderStatus.pending: Color(0xFFFFF8E6),
    OrderStatus.confirmed: Color(0xFFE8F0FE),
    OrderStatus.processing: Color(0xFFEEF0FF),
    OrderStatus.shipped: Color(0xFFE6F4FF),
    OrderStatus.delivered: Color(0xFFE8F5E9),
    OrderStatus.cancelled: Color(0xFFFFEEEE),
    OrderStatus.refunded: Color(0xFFF5F5F5),
  };

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

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[order.status] ?? context.textSub;
    final bg = _statusBgs[order.status] ?? context.bgChip;
    final initial = order.shippingAddress.fullName.isNotEmpty
        ? order.shippingAddress.fullName[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(_route(AdminOrderDetailScreen(orderId: order.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: avatar + name + status badge
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.bgChip,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        '#ORD-${order.id.substring(0, 6).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSub,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.name[0].toUpperCase() +
                        order.status.name.substring(1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      color: color,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: context.divider),
            const SizedBox(height: 10),

            // Row 2: order date + total
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORDER DATE',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        color: context.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmt(order.createdAt),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: context.textBody,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOTAL AMOUNT',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        color: context.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.total.toStringAsFixed(0)} DT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
