// lib/views/client/profile_screen.dart
//
// FIXES:
// • Address saving now calls AuthProvider.addAddress() — the actual
//   Firestore write was missing before (updateProfile ignored addresses)
// • All colors use context.bgSurface / context.textPrimary etc. so
//   dark mode is properly reflected
// • Font family changed to Inter throughout
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../models/app_user.dart';
import '../../theme/app_theme.dart';
import '../screens.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editMode = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    await context.read<AuthProvider>().updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
    if (mounted) {
      setState(() {
        _saving = false;
        _editMode = false;
      });
      _snack('Profile updated ✓', kPrimary);
    }
  }

  // ── Change password ──────────────────────────────────────
  void _showChangePasswordDialog() {
    final emailCtrl = TextEditingController(
      text: context.read<AuthProvider>().user?.email ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Change Password',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "We'll send a password reset link to your email address.",
              style: TextStyle(
                fontSize: 13.5,
                color: context.textSub,
                height: 1.5,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              readOnly: true,
              style: TextStyle(
                fontSize: 14,
                color: context.textBody,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.mail_outline,
                  color: context.textHint,
                  size: 18,
                ),
                filled: true,
                fillColor: context.bgInput,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.border, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: context.textPrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.textHint)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final email = emailCtrl.text.trim();
              final ok = await context.read<AuthProvider>().sendPasswordReset(
                email,
              );
              if (mounted) {
                _snack(
                  ok
                      ? 'Reset link sent to $email'
                      : 'Failed to send reset link.',
                  ok ? kPrimary : kError,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Send Link',
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
  }

  // ── Add address ──────────────────────────────────────────
  // FIX: was calling updateProfile(name, phone) — addresses were silently
  // thrown away. Now calls AuthProvider.addAddress() which writes the
  // addresses array directly to Firestore.
  void _showAddAddressSheet() {
    final fullNameCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final postalCtrl = TextEditingController();
    final countryCtrl = TextEditingController();
    final labelCtrl = TextEditingController(text: 'Home');
    bool isDefault = false;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add Address',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SheetField(
                    label: 'Label (Home, Office…)',
                    ctrl: labelCtrl,
                    icon: Icons.label_outline,
                  ),
                  const SizedBox(height: 12),
                  _SheetField(
                    label: 'Full Name',
                    ctrl: fullNameCtrl,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  _SheetField(
                    label: 'Street Address',
                    ctrl: streetCtrl,
                    icon: Icons.home_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SheetField(
                          label: 'City',
                          ctrl: cityCtrl,
                          icon: Icons.location_city_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SheetField(
                          label: 'Postal Code',
                          ctrl: postalCtrl,
                          icon: Icons.markunread_mailbox_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SheetField(
                    label: 'Country',
                    ctrl: countryCtrl,
                    icon: Icons.flag_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: isDefault,
                        onChanged: (v) =>
                            setSheet(() => isDefault = v ?? false),
                        activeColor: kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Text(
                        'Set as default address',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: context.textBody,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (fullNameCtrl.text.trim().isEmpty ||
                                  streetCtrl.text.trim().isEmpty ||
                                  cityCtrl.text.trim().isEmpty) {
                                setSheet(() {});
                                return;
                              }
                              setSheet(() => saving = true);
                              final newAddr = ShippingAddress(
                                id: const Uuid().v4(),
                                label: labelCtrl.text.trim().isEmpty
                                    ? 'Home'
                                    : labelCtrl.text.trim(),
                                fullName: fullNameCtrl.text.trim(),
                                street: streetCtrl.text.trim(),
                                city: cityCtrl.text.trim(),
                                postalCode: postalCtrl.text.trim(),
                                country: countryCtrl.text.trim(),
                                isDefault: isDefault,
                              );
                              // FIX: call addAddress — actually saves to Firestore
                              await context.read<AuthProvider>().addAddress(
                                newAddr,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                _snack('Address saved ✓', kPrimary);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: saving
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
                              'Save Address',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Sign out ─────────────────────────────────────────────
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Sign Out',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of The Atelier?',
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
              backgroundColor: kPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Sign Out',
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

    if (confirmed == true && mounted) {
      context.read<OrderProvider>().stopListening();
      context.read<CartProvider>().clearCart();
      context.read<WishlistProvider>().clear();
      await context.read<AuthProvider>().signOut();
      if (mounted) {
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
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    
    // SECURITY: Only show orders that belong to the current user
    final allOrders = context.watch<OrderProvider>().orders;
    final orders = user != null
        ? allOrders.where((o) => o.userId == user.uid).toList()
        : [];
    
    final wishlistCount = context.watch<WishlistProvider>().count;
    final cartCount = context.watch<CartProvider>().itemCount;
    final themeProv = context.watch<ThemeProvider>();

    if (user == null) {
      return Center(
        child: CircularProgressIndicator(color: context.textPrimary),
      );
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
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
                  IconButton(
                    icon: Icon(
                      _editMode ? Icons.close : Icons.edit_outlined,
                      color: context.textPrimary,
                      size: 21,
                    ),
                    onPressed: () => setState(() => _editMode = !_editMode),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  _MiniIconBadge(
                    icon: wishlistCount > 0
                        ? Icons.favorite
                        : Icons.favorite_border,
                    count: wishlistCount,
                    badgeColor: kPrimaryLight,
                    onTap: () => Navigator.of(
                      context,
                    ).push(_route(const WishlistScreen())),
                  ),
                  _MiniIconBadge(
                    icon: Icons.shopping_bag_outlined,
                    count: cartCount,
                    badgeColor: kPrimary,
                    onTap: () =>
                        Navigator.of(context).push(_route(const CartScreen())),
                  ),
                ],
              ),
            ),
          ),

          // ── Avatar ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  Stack(
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
                        child: user.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user.photoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
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
                      if (_editMode)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: context.textPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.name,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
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
                      color: user.isAdmin
                          ? context.textPrimary
                          : context.bgChip,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.isAdmin ? '✦ Admin' : '✦ Member',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontFamily: 'Inter',
                        color: user.isAdmin
                            ? Colors.white
                            : context.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatBox(value: '${orders.length}', label: 'Orders'),
                  const SizedBox(width: 12),
                  _StatBox(value: '$wishlistCount', label: 'Wishlist'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(
                        context,
                      ).push(_route(const CartScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: context.bgChip,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$cartCount',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'In Cart',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textSub,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Edit form ──────────────────────────────────
          if (_editMode) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('EDIT PROFILE'),
                      const SizedBox(height: 14),
                      _ProfileField(
                        label: 'Full Name',
                        controller: _nameCtrl,
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),
                      _ProfileField(
                        label: 'Phone',
                        controller: _phoneCtrl,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
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
                                  'Save Changes',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],

          // ── Addresses ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: context.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          _Label('SHIPPING ADDRESSES'),
                          const Spacer(),
                          GestureDetector(
                            onTap: _showAddAddressSheet,
                            child: Text(
                              '+ Add',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: kPrimaryLight,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (user.addresses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: GestureDetector(
                          onTap: _showAddAddressSheet,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: context.textPrimary.withOpacity(0.3),
                                width: 1.3,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_location_alt_outlined,
                                  color: context.textPrimary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add your first address',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: context.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...user.addresses.map(
                        (addr) => _AddressTile(
                          address: addr,
                          onDelete: () => context
                              .read<AuthProvider>()
                              .deleteAddress(addr.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Preferences ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
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
                        child: _Label('PREFERENCES'),
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
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Account links ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
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
                        child: _Label('ACCOUNT'),
                      ),
                    ),
                    _MenuRow(
                      icon: Icons.lock_outline,
                      label: 'Change Password',
                      onTap: _showChangePasswordDialog,
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
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Sign out ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
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
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              child: Center(
                child: Text(
                  'The Atelier  v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textHint,
                    letterSpacing: 0.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: context.bgChip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.textSub,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 10,
      letterSpacing: 1.4,
      fontWeight: FontWeight.w700,
      fontFamily: 'Inter',
      color: context.textSub,
    ),
  );
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: context.textSub,
          fontFamily: 'Inter',
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 14,
          color: context.textBody,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: context.textHint, size: 18),
          filled: true,
          fillColor: context.bgInput,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.border, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.textPrimary, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final TextInputType keyboardType;

  const _SheetField({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: keyboardType,
    style: TextStyle(
      fontSize: 14,
      color: context.textBody,
      fontFamily: 'Inter',
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 13,
        color: context.textHint,
        fontFamily: 'Inter',
      ),
      prefixIcon: Icon(icon, color: context.textHint, size: 18),
      filled: true,
      fillColor: context.bgInput,
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.textPrimary, width: 1.5),
      ),
    ),
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
          Icon(Icons.chevron_right, color: context.textHint, size: 20),
        ],
      ),
    ),
  );
}

class _AddressTile extends StatelessWidget {
  final ShippingAddress address;
  final VoidCallback onDelete;

  const _AddressTile({required this.address, required this.onDelete});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.bgChip,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.location_on_outlined,
            color: context.textPrimary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    address.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  if (address.isDefault) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.textPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: context.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                address.fullAddress,
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.textSub,
                  height: 1.4,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Color(0xFFCC4444),
            size: 18,
          ),
          onPressed: onDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    ),
  );
}

class _MiniIconBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color badgeColor;
  final VoidCallback onTap;

  const _MiniIconBadge({
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
                  fontFamily: 'Inter',
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
