import 'package:flutter/material.dart';
import '../models/order.dart';

/// Compact order row used in order history list.
class OrderTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderTile({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: order id + status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF1B3A6B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),

            const SizedBox(height: 8),

            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            const SizedBox(height: 8),

            // Item count + date
            Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 15,
                  color: Color(0xFF999999),
                ),
                const SizedBox(width: 5),
                Text(
                  '${order.totalItems} item${order.totalItems > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF999999),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(order.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Total  ',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF999999)),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B3A6B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

/// Coloured pill badge for order status.
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name[0].toUpperCase() + status.name.substring(1),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color get _bg {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFFFF8E6);
      case OrderStatus.confirmed:
        return const Color(0xFFE8F0FE);
      case OrderStatus.processing:
        return const Color(0xFFEEF0FF);
      case OrderStatus.shipped:
        return const Color(0xFFE6F4FF);
      case OrderStatus.delivered:
        return const Color(0xFFE8F5E9);
      case OrderStatus.cancelled:
        return const Color(0xFFFFEEEE);
      case OrderStatus.refunded:
        return const Color(0xFFF5F5F5);
    }
  }

  Color get _fg {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFA07000);
      case OrderStatus.confirmed:
        return const Color(0xFF1A56DB);
      case OrderStatus.processing:
        return const Color(0xFF5B5BD6);
      case OrderStatus.shipped:
        return const Color(0xFF0077B6);
      case OrderStatus.delivered:
        return const Color(0xFF2E7D32);
      case OrderStatus.cancelled:
        return const Color(0xFFE05050);
      case OrderStatus.refunded:
        return const Color(0xFF888888);
    }
  }
}
