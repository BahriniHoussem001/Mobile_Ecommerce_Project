// lib/pages/client/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/providers.dart';
import '../../services/seed_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../screens.dart';
import '../admin/admin_shell.dart';
import 'all_products_screen.dart';

const bool kDebugSeed = false;

// ─────────────────────────────────────────────────────────────
// HomeScreen — shell with persistent bottom nav.
//
// FIX for orders on cold restart:
//   Firebase Auth resolves _asynchronously_ after initState runs,
//   so calling listenToUserOrders() there finds user==null and skips.
//   Solution: also call it from didChangeDependencies(), which is
//   triggered every time AuthProvider notifies — including when it
//   finishes loading the user from Firebase on a cold restart.
// ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  bool _streamsStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchAll();
      _tryStartStreams();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Called again whenever AuthProvider notifies — catches late-resolved uid
    _tryStartStreams();
  }

  void _tryStartStreams() {
    if (_streamsStarted) return;
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    _streamsStarted = true;
    context.read<OrderProvider>().listenToUserOrders(uid);
    context.read<WishlistProvider>().load(uid);
  }

  void _goToTab(int i) => setState(() => _navIndex = i);

  @override
  Widget build(BuildContext context) {
    // Watching AuthProvider ensures didChangeDependencies fires when user loads
    final auth = context.watch<AuthProvider>();

    if (auth.isAdmin) {
      return const AdminShell();
    }

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
        children: [
          _HomeBody(onGoToOrders: () => _goToTab(2)),
          const SearchScreen(),
          const OrderTrackingScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _AtelierBottomNav(
        currentIndex: _navIndex,
        onTap: _goToTab,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Home body
// ─────────────────────────────────────────────────────────────
class _HomeBody extends StatefulWidget {
  final VoidCallback onGoToOrders;
  const _HomeBody({required this.onGoToOrders});

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  ProductCategory? _selectedCategory;
  bool _seeding = false;

  Future<void> _seed() async {
    final uid = context.read<AuthProvider>().user?.uid ?? 'dev_user';
    setState(() => _seeding = true);
    try {
      await SeedService.seed(uid);
      if (mounted) {
        await context.read<ProductProvider>().fetchAll();
        _snack('🌱 Dummy data seeded!', kPrimary);
      }
    } catch (e) {
      if (mounted) _snack('Seed failed: $e', kError);
    }
    if (mounted) setState(() => _seeding = false);
  }

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final homeProducts = productProv.filtered.take(6).toList();

    return SafeArea(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── App bar ────────────────────────────────
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
                      _IconBadge(
                        icon: wishlist.count > 0
                            ? Icons.favorite
                            : Icons.favorite_border,
                        count: wishlist.count,
                        badgeColor: kPrimaryLight,
                        onTap: () => Navigator.of(
                          context,
                        ).push(_route(const WishlistScreen())),
                      ),
                      _IconBadge(
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

              // ── Search bar ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => Navigator.of(
                      context,
                    ).push(_route(const SearchScreen())),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.bgChip,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(
                            Icons.search_rounded,
                            color: context.textHint,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search curated collections...',
                              style: TextStyle(
                                color: context.textHint,
                                fontSize: 13.5,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          Icon(
                            Icons.tune_rounded,
                            color: context.textHint,
                            size: 20,
                          ),
                          const SizedBox(width: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Hero banner ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        // Background Image
                        SizedBox(
                          height: 190,
                          width: double.infinity,
                          child: Image.asset(
                            'assets/images/hero_banner.png',
                            fit: BoxFit.cover,
                          ),
                        ),

                        // Gradient overlay
                        Container(
                          height: 190,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xCC000000),
                                Color(0x66000000),
                                Colors.transparent,
                              ],
                              stops: [0, 0.5, 1],
                            ),
                          ),
                        ),

                        Positioned(
                          top: 20,
                          left: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NEW SEASON',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'The Ethereal\nCollection',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.2,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => Navigator.of(
                                  context,
                                ).push(_route(const AllProductsScreen())),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Explore Lookbook',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: Color(0xFF1B3A6B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
              // ── Promo card ─────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Category chips ─────────────────────────
              SliverToBoxAdapter(
                child: CategoryChipBar(
                  selected: _selectedCategory,
                  onSelected: (c) {
                    setState(() => _selectedCategory = c);
                    context.read<ProductProvider>().setCategory(c);
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Section header — FIX: View All navigates ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Curated Essentials',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Product grid ───────────────────────────
              if (productProv.state == ProductLoadState.loading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const ProductShimmer(),
                      childCount: 4,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.58,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 20,
                        ),
                  ),
                )
              else if (productProv.filtered.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'No products yet',
                    subtitle: kDebugSeed
                        ? 'Tap "Seed Data" to populate.'
                        : 'Check back soon.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => ProductCard(
                        product: homeProducts[i],
                        onTap: () => Navigator.of(ctx).push(
                          _route(ProductDetailScreen(product: homeProducts[i])),
                        ),
                      ),
                      childCount: homeProducts.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.52,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 20,
                        ),
                  ),
                ),

              // See all nudge
              if (productProv.filtered.length > 6)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: GestureDetector(
                      onTap: () => Navigator.of(
                        context,
                      ).push(_route(const AllProductsScreen())),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: context.textPrimary.withOpacity(0.3),
                            width: 1.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'See all ${productProv.filtered.length} products',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: context.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),

          // ── Seed FAB ──────────────────────────────────
          if (kDebugSeed)
            Positioned(
              bottom: 16,
              right: 16,
              child: GestureDetector(
                onTap: _seeding ? null : _seed,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _seeding
                        ? kPrimaryLight.withOpacity(0.7)
                        : kPrimaryLight,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_seeding)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      else
                        const Icon(
                          Icons.cloud_upload_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _seeding ? 'Seeding...' : 'Seed Data',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Reusable icon+badge ───────────────────────────────────────
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color badgeColor;
  final VoidCallback onTap;
  const _IconBadge({
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
        icon: Icon(icon, color: context.textPrimary, size: 24),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
      if (count > 0)
        Positioned(
          right: 2,
          top: 2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

// ── Bottom nav ────────────────────────────────────────────────
class _AtelierBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _AtelierBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'HOME'),
    (Icons.search_outlined, Icons.search, 'SEARCH'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'ORDERS'),
    (Icons.person_outline, Icons.person, 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) => Container(
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
