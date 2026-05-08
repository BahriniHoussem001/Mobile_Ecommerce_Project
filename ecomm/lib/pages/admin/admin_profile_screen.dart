// lib/pages/admin/admin_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_order_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final themeProv = context.watch<ThemeProvider>();
    final adminOrders = context.watch<AdminOrderProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 14),

            // ── App bar ──────────────────────────────────
            Row(
              children: [
                Text(
                  'The Atelier',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: adminOrders.pendingCount > 0
                        ? kError.withOpacity(0.1)
                        : context.bgChip,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 16,
                        color: adminOrders.pendingCount > 0
                            ? kError
                            : context.textPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${adminOrders.pendingCount}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: adminOrders.pendingCount > 0
                              ? kError
                              : context.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Avatar ───────────────────────────────────
            Column(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.bgChip,
                    border: Border.all(
                      color: context.textPrimary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'A',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'Admin',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSub,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.textPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✦ Admin',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontFamily: 'Inter',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Analytics Stats ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHOP ANALYTICS',
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1.5,
                      color: context.textSub,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _AnalyticsBox(
                        value: '${adminOrders.totalOrders}',
                        label: 'Total Orders',
                        icon: Icons.receipt_long,
                        color: kPrimary,
                      ),
                      const SizedBox(width: 8),
                      _AnalyticsBox(
                        value: '${adminOrders.pendingCount}',
                        label: 'Pending',
                        icon: Icons.pending,
                        color: kError,
                      ),
                      const SizedBox(width: 8),
                      _AnalyticsBox(
                        value: '${adminOrders.shippedCount}',
                        label: 'Shipped',
                        icon: Icons.local_shipping,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _AnalyticsBox(
                        value: '${adminOrders.deliveredCount}',
                        label: 'Delivered',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _AnalyticsBox(
                        value: '${adminOrders.cancelledCount}',
                        label: 'Cancelled',
                        icon: Icons.cancel,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RevenueBox(
                          totalRevenue: adminOrders.totalRevenue,
                          monthRevenue: adminOrders.monthRevenue,
                          growthPercent: adminOrders.orderGrowthPercent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Preferences ────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: context.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border, width: 1.2),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'PREFERENCES',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                          color: context.textSub,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  _Toggle(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    value: themeProv.isDark,
                    onChanged: (v) => themeProv.set(v),
                  ),
                  _Toggle(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    value: true,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Account links ──────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: context.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border, width: 1.2),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ACCOUNT',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                          color: context.textSub,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.lock_outline,
                    label: 'Change Password',
                    onTap: () {},
                  ),
                  _MenuRow(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () {},
                  ),
                  _MenuRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () {},
                  ),
                  _MenuRow(
                    icon: Icons.info_outline,
                    label: 'About The Atelier',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Sign out ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  context.read<AdminOrderProvider>().stopListening();
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const LoginScreen(),
                        transitionDuration: const Duration(milliseconds: 400),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                      ),
                      (_) => false,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.border, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.logout,
                  color: Color(0xFFCC4444),
                  size: 18,
                ),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFFCC4444),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'The Atelier Admin v1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textHint,
                  letterSpacing: 0.5,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Analytics widgets
// ─────────────────────────────────────────────────────────────

class _AnalyticsBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _AnalyticsBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: context.bgChip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: context.textSub,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _RevenueBox extends StatelessWidget {
  final double totalRevenue;
  final double monthRevenue;
  final double growthPercent;

  const _RevenueBox({
    required this.totalRevenue,
    required this.monthRevenue,
    required this.growthPercent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    decoration: BoxDecoration(
      color: context.bgChip,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_money, size: 16, color: Colors.green),
            const SizedBox(width: 2),
            Text(
              '\$${totalRevenue.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Revenue',
          style: TextStyle(
            fontSize: 9,
            color: context.textSub,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: context.border),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '\$${monthRevenue.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${growthPercent >= 0 ? '+' : ''}${growthPercent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: growthPercent >= 0 ? Colors.green : Colors.red,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        Text(
          'This Month',
          style: TextStyle(
            fontSize: 8,
            color: context.textSub,
            fontFamily: 'Inter',
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Reused widgets from client profile
// ─────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.bgSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.border, width: 1),
    ),
    child: Column(children: children),
  );
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: context.textPrimary),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: context.textBody,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: kPrimary,
        ),
      ],
    ),
  );
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: context.textBody,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: context.textHint),
        ],
      ),
    ),
  );
}
