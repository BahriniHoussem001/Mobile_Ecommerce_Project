// lib/pages/client/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/order_tile.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) {
      return Scaffold(
        backgroundColor: context.bgPage,
        body: Center(
          child: Text(
            'Not authenticated',
            style: TextStyle(color: context.textSub),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.bgPage,
      body: StreamBuilder<Order>(
        stream: context.read<OrderProvider>().listenToOrder(orderId, userId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.textPrimary),
            );
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Text(
                snap.hasError
                    ? 'Unable to load order: ${snap.error}'
                    : 'Unable to load order.',
                style: TextStyle(color: context.textSub),
              ),
            );
          }
          return _Body(order: snap.data!);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Order order;
  const _Body({required this.order});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: CustomScrollView(
      slivers: [
        // App bar
        SliverToBoxAdapter(
          child: Padding(
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
                Text(
                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Status hero
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.bgChip,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  OrderStatusBadge(status: order.status),
                  const SizedBox(height: 10),
                  Text(
                    _heroTitle(order.status),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estimated delivery: ${_fmtDate(order.createdAt.add(const Duration(days: 5)))}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSub,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Timeline
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.bgSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRACKING STATUS',
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1.5,
                      color: context.textSub,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildTimeline(order, context),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Shipping address
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _InfoCard(
              title: 'SHIPPING ADDRESS',
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
                  const SizedBox(height: 4),
                  Text(
                    order.shippingAddress.fullAddress,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSub,
                      height: 1.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Order info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _InfoCard(
              title: 'ORDER INFORMATION',
              child: Column(
                children: [
                  _IRow('Placed on', _fmtDate(order.createdAt)),
                  _IRow(
                    'Total Amount',
                    '\$${order.total.toStringAsFixed(0)}',
                    valueColor: context.textPrimary,
                  ),
                  _IRow('Payment', order.paymentMethod.toUpperCase()),
                  if (order.trackingNumber != null)
                    _IRow('Tracking', order.trackingNumber!),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Items (${order.totalItems})',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        SliverList(
          delegate: SliverChildBuilderDelegate((ctx, i) {
            final item = order.items[i];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 72,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          Text(
                            'Size: ${item.selectedSize}  •  Color: ${item.selectedColor}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSub,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            'Qty: ${item.quantity}',
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }, childCount: order.items.length),
        ),

        // Price breakdown
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.bgChip,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _PRow('Subtotal', '\$${order.subtotal.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _PRow(
                    'Shipping',
                    '\$${order.shippingFee.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                  _PRow(
                    'Estimated Tax',
                    '\$${(order.total * 0.08 / 1.08).toStringAsFixed(0)}',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: context.divider),
                  ),
                  Row(
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
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
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: context.bgChip,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'Need Help?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    ),
  );

  List<Widget> _buildTimeline(Order order, BuildContext context) {
    final steps = [
      (OrderStatus.confirmed, 'Confirmed'),
      (OrderStatus.processing, 'Processing'),
      (OrderStatus.shipped, 'Shipped'),
      (OrderStatus.delivered, 'Delivered'),
    ];
    final activeIdx = steps.indexWhere((s) => s.$1 == order.status);
    return List.generate(steps.length, (i) {
      final done = i <= activeIdx;
      final time = order.createdAt.add(Duration(hours: i * 12));
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: done ? context.textPrimary : context.border,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 13,
                    color: done ? Colors.white : context.textHint,
                  ),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: done && i < activeIdx
                        ? context.textPrimary
                        : context.border,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[i].$2,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: done ? context.textPrimary : context.textHint,
                    ),
                  ),
                  if (done)
                    Text(
                      _fmtDateTime(time),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.textSub,
                        fontFamily: 'Inter',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  String _heroTitle(OrderStatus s) => switch (s) {
    OrderStatus.pending => 'Order Received',
    OrderStatus.confirmed => 'Order Confirmed',
    OrderStatus.processing => 'Being Prepared',
    OrderStatus.shipped => 'On Its Way',
    OrderStatus.delivered => 'Delivered!',
    OrderStatus.cancelled => 'Order Cancelled',
    OrderStatus.refunded => 'Order Refunded',
  };

  String _fmtDate(DateTime dt) {
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
    return '${m[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  String _fmtDateTime(DateTime dt) {
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
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    return '${m[dt.month - 1]} ${dt.day}, $h:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.bgSurface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 1.5,
            color: context.textSub,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _IRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _IRow(this.label, this.value, {this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: context.textSub,
            fontFamily: 'Inter',
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor ?? context.textBody,
            fontFamily: 'Inter',
          ),
        ),
      ],
    ),
  );
}

class _PRow extends StatelessWidget {
  final String label;
  final String value;
  const _PRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13.5,
          color: context.textSub,
          fontFamily: 'Inter',
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: context.textBody,
          fontFamily: 'Inter',
        ),
      ),
    ],
  );
}
