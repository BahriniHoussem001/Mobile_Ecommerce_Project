// lib/pages/client/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  bool _filtersOpen = false;
  ProductCategory? _category;
  String _sortBy = 'newest';
  RangeValues _priceRange = const RangeValues(0, 2000);
  bool _onSaleOnly = false;
  bool _inStockOnly = false;
  late AnimationController _filterAnim;
  late Animation<double> _filterHeight;

  @override
  void initState() {
    super.initState();
    _filterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _filterHeight = CurvedAnimation(
      parent: _filterAnim,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _filterAnim.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() => _filtersOpen = !_filtersOpen);
    _filtersOpen ? _filterAnim.forward() : _filterAnim.reverse();
  }

  void _applyFilters() {
    context.read<ProductProvider>()
      ..setCategory(_category)
      ..setSortBy(_sortBy);
    setState(() => _filtersOpen = false);
    _filterAnim.reverse();
  }

  void _clearFilters() {
    setState(() {
      _category = null;
      _sortBy = 'newest';
      _priceRange = const RangeValues(0, 2000);
      _onSaleOnly = false;
      _inStockOnly = false;
    });
    context.read<ProductProvider>().clearFilters();
  }

  List<Product> get _results {
    var list = context.watch<ProductProvider>().filtered;
    if (_onSaleOnly) list = list.where((p) => p.isOnSale).toList();
    if (_inStockOnly) list = list.where((p) => p.isInStock).toList();
    return list
        .where(
          (p) => p.price >= _priceRange.start && p.price <= _priceRange.end,
        )
        .toList();
  }

  String _sortLabel(String s) => switch (s) {
    'priceAsc' => 'Price ↑',
    'priceDesc' => 'Price ↓',
    'rating' => 'Top Rated',
    _ => 'Newest',
  };

  bool get _hasFilters =>
      _category != null ||
      _sortBy != 'newest' ||
      _onSaleOnly ||
      _inStockOnly ||
      _priceRange.start > 0 ||
      _priceRange.end < 2000;

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      backgroundColor: context.bgPage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: AtelierSearchBar(
                      controller: _searchCtrl,
                      onChanged: (q) =>
                          context.read<ProductProvider>().setSearch(q),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _toggleFilters,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _filtersOpen || _hasFilters
                            ? context.textPrimary
                            : context.bgChip,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: _filtersOpen || _hasFilters
                            ? Colors.white
                            : context.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active filter chips
            if (_hasFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_category != null)
                      _FChip(
                        label:
                            _category!.name[0].toUpperCase() +
                            _category!.name.substring(1),
                        onRemove: () {
                          setState(() => _category = null);
                          context.read<ProductProvider>().setCategory(null);
                        },
                      ),
                    if (_sortBy != 'newest')
                      _FChip(
                        label: _sortLabel(_sortBy),
                        onRemove: () {
                          setState(() => _sortBy = 'newest');
                          context.read<ProductProvider>().setSortBy('newest');
                        },
                      ),
                    if (_onSaleOnly)
                      _FChip(
                        label: 'On Sale',
                        onRemove: () => setState(() => _onSaleOnly = false),
                      ),
                    if (_inStockOnly)
                      _FChip(
                        label: 'In Stock',
                        onRemove: () => setState(() => _inStockOnly = false),
                      ),
                    GestureDetector(
                      onTap: _clearFilters,
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 12,
                          color: kError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Filter panel
            SizeTransition(
              sizeFactor: _filterHeight,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.bgChip,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.border, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CATEGORY',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700,
                        color: context.textSub,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CChip(
                          label: 'All',
                          selected: _category == null,
                          onTap: () => setState(() => _category = null),
                        ),
                        ...ProductCategory.values.map(
                          (c) => _CChip(
                            label:
                                c.name[0].toUpperCase() + c.name.substring(1),
                            selected: _category == c,
                            onTap: () => setState(() => _category = c),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          'PRICE RANGE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w700,
                            color: context.textSub,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${_priceRange.start.toInt()} – \$${_priceRange.end.toInt()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 2000,
                      divisions: 40,
                      activeColor: context.textPrimary,
                      inactiveColor: context.border,
                      onChanged: (r) => setState(() => _priceRange = r),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearFilters,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: context.textPrimary,
                                width: 1.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Apply Filters',
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Results bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${results.length} result${results.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSub,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showSortSheet(context),
                    child: Row(
                      children: [
                        Icon(Icons.sort, size: 16, color: context.textPrimary),
                        const SizedBox(width: 4),
                        Text(
                          _sortLabel(_sortBy),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Grid
            Expanded(
              child: results.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No results',
                      subtitle:
                          'Try different keywords or adjust your filters.',
                      actionLabel: 'Clear Filters',
                      onAction: _clearFilters,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 20,
                          ),
                      itemCount: results.length,
                      itemBuilder: (ctx, i) => ProductCard(
                        product: results[i],
                        onTap: () => Navigator.of(ctx).push(
                          _route(ProductDetailScreen(product: results[i])),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...[
              ('newest', 'Newest First'),
              ('priceAsc', 'Price: Low to High'),
              ('priceDesc', 'Price: High to Low'),
              ('rating', 'Top Rated'),
            ].map(
              (opt) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  opt.$2,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: _sortBy == opt.$1
                        ? context.textPrimary
                        : context.textBody,
                    fontWeight: _sortBy == opt.$1
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                trailing: _sortBy == opt.$1
                    ? Icon(Icons.check, color: context.textPrimary, size: 20)
                    : null,
                onTap: () {
                  setState(() => _sortBy = opt.$1);
                  context.read<ProductProvider>().setSortBy(opt.$1);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FChip({required this.label, required this.onRemove});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
    decoration: BoxDecoration(
      color: context.textPrimary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.textPrimary.withOpacity(0.3), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: Icon(Icons.close, size: 14, color: context.textPrimary),
        ),
      ],
    ),
  );
}

class _CChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? context.textPrimary : context.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? context.textPrimary : context.border,
          width: 1.2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? Colors.white : context.textBody,
        ),
      ),
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
