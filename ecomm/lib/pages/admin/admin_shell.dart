// lib/pages/admin/admin_shell.dart
//
// Root shell for the admin section.
// Has its own bottom navbar: STATS · ORDERS · INVENTORY · PROFILE
// Completely separate from the client HomeScreen shell.
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_order_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start real-time order stream for the entire admin session
      context.read<AdminOrderProvider>().startListening();
      // Ensure products are loaded
      context.read<ProductProvider>().fetchAll();
    });
  }

  @override
  void dispose() {
    // Stop the admin order stream when admin logs out
    context.read<AdminOrderProvider>().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: context.isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: context.bgPage,
      body: IndexedStack(
        index: _navIndex,
        children: const [
          AdminDashboardScreen(),
          AdminOrdersScreen(),
          AdminInventoryScreen(),
          AdminProfileScreen(),
        ],
      ),
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Admin bottom navbar — different from the client's
// ─────────────────────────────────────────────────────────────
class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AdminBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.bar_chart_outlined, Icons.bar_chart, 'STATS'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'ORDERS'),
    (Icons.inventory_2_outlined, Icons.inventory_2, 'INVENTORY'),
    (Icons.person_outline, Icons.person, 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: context.bgSurface,
        border: Border(top: BorderSide(color: context.divider, width: 1)),
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final active = currentIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    active ? _items[i].$2 : _items[i].$1,
                    size: 22,
                    color: active ? context.textPrimary : context.textHint,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _items[i].$3,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      color: active ? context.textPrimary : context.textHint,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
