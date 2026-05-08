// lib/pages/admin/admin_order_detail_screen.dart
//
// Admin view of a single order.
// • Streams the order in real-time
// • Inline status dropdown to update order status
// • Tracking number field (auto-sets status to Shipped)
// • Full order breakdown in DT
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/admin_order_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/order_tile.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final _trackingCtrl = TextEditingController();
  bool _savingStatus = false;
  bool _savingTracking = false;
  OrderStatus? _selectedStatus;

  @override
  void dispose() {
    _trackingCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;
    setState(() => _savingStatus = true);
    await context.read<AdminOrderProvider>().updateStatus(
      widget.orderId,
      _selectedStatus!,
    );
    if (mounted) {
      setState(() => _savingStatus = false);
      _snack(
        'Status updated to ${_selectedStatus!.name}',
        const Color(0xFF2E7D32),
      );
    }
  }

  Future<void> _saveTracking() async {
    final t = _trackingCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() => _savingTracking = true);
    await context.read<AdminOrderProvider>().setTracking(widget.orderId, t);
    if (mounted) {
      setState(() => _savingTracking = false);
      _snack(
        'Tracking number saved — status set to Shipped',
        const Color(0xFF0077B6),
      );
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AdminOrderProvider>();

    return Scaffold(
      backgroundColor: context.bgPage,
      body: StreamBuilder<Order>(
        stream: prov.streamOrder(widget.orderId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.textPrimary),
            );
          }
          if (!snap.hasData || snap.hasError) {
            return Center(
              child: Text(
                'Unable to load order.',
                style: TextStyle(color: context.textSub),
              ),
            );
          }

          final order = snap.data!;
          // Initialise dropdown to current status on first build
          _selectedStatus ??= order.status;
          // Pre-fill tracking if already set
          if (_trackingCtrl.text.isEmpty && order.trackingNumber != null) {
            _trackingCtrl.text = order.trackingNumber!;
          }

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── App bar ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
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
                            'Order #${order.id.substring(0, 8).toUpperCase()}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        OrderStatusBadge(status: order.status),
                      ],
                    ),
                  ),
                ),

                // ── Customer info ───────────────────────
                _sliver(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _Card(
                      title: 'CUSTOMER',
                      child: Row(
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
                                order.shippingAddress.fullName.isNotEmpty
                                    ? order.shippingAddress.fullName[0]
                                          .toUpperCase()
                                    : '?',
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
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Text(
                                  order.shippingAddress.fullAddress,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: context.textSub,
                                    fontFamily: 'Inter',
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                _gap,

                // ── Update status ───────────────────────
                _sliver(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _Card(
                      title: 'UPDATE STATUS',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.bgChip,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.border,
                                width: 1.2,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<OrderStatus>(
                                value: _selectedStatus,
                                isExpanded: true,
                                dropdownColor: context.bgSurface,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: context.textBody,
                                ),
                                items: OrderStatus.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s.name[0].toUpperCase() +
                                              s.name.substring(1),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: context.textBody,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (s) =>
                                    setState(() => _selectedStatus = s),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _savingStatus ? null : _updateStatus,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.textPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _savingStatus
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Save Status',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                _gap,

                // ── Tracking number ─────────────────────
                _sliver(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _Card(
                      title: 'TRACKING NUMBER',
                      child: Column(
                        children: [
                          TextField(
                            controller: _trackingCtrl,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textBody,
                              fontFamily: 'Inter',
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter tracking number',
                              hintStyle: TextStyle(
                                color: context.textHint,
                                fontFamily: 'Inter',
                              ),
                              filled: true,
                              fillColor: context.bgChip,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 14,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.border,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.textPrimary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _savingTracking ? null : _saveTracking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0077B6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _savingTracking
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Save & Mark Shipped',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                _gap,

                // ── Order items ─────────────────────────
                _sliver(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _Card(
                      title: 'ITEMS (${order.totalItems})',
                      child: Column(
                        children: order.items
                            .map(
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
                                                    Container(
                                                      color: context.bgChip,
                                                    ),
                                              )
                                            : Container(color: context.bgChip),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            '${item.selectedColor} / ${item.selectedSize}  ×${item.quantity}',
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
                                      '${item.subtotal.toStringAsFixed(0)} DT',
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
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),

                _gap,

                // ── Price breakdown ─────────────────────
                _sliver(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _Card(
                      title: 'PRICE BREAKDOWN',
                      child: Column(
                        children: [
                          _PRow(
                            'Subtotal',
                            '${order.subtotal.toStringAsFixed(0)} DT',
                            context,
                          ),
                          _PRow(
                            'Shipping',
                            '${order.shippingFee.toStringAsFixed(0)} DT',
                            context,
                          ),
                          if (order.discount > 0)
                            _PRow(
                              'Discount',
                              '−${order.discount.toStringAsFixed(0)} DT',
                              context,
                              valueColor: const Color(0xFF2E7D32),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: context.divider),
                          ),
                          Row(
                            children: [
                              Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: context.textSub,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${order.total.toStringAsFixed(0)} DT',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Payment',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: context.textSub,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const Spacer(),
                              Text(
                                order.paymentMethod.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.textBody,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _sliver(Widget child) => SliverToBoxAdapter(child: child);

  Widget get _gap => const SliverToBoxAdapter(child: SizedBox(height: 16));
}

// ── Shared sub-widgets ────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.bgSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.border, width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            color: context.textSub,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

Widget _PRow(
  String label,
  String value,
  BuildContext context, {
  Color? valueColor,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(
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
          color: valueColor ?? context.textBody,
          fontFamily: 'Inter',
        ),
      ),
    ],
  ),
);
