// lib/pages/admin/add_edit_product_screen.dart
//
// Matches the "Edit Product" mockup exactly.
// Fields:
//   PRODUCT MEDIA   — main image URL + optional extra image URLs
//   BASIC INFO      — name, description, sizes (chips + add), colors (dots + add)
//   PRICING         — base price (DT), On Sale toggle → sale price field
//   INVENTORY       — stock quantity, Track Inventory toggle
//   ORGANIZATION    — category dropdown
//   Footer          — Delete Product (edit mode only) + Product ID
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';

class AddEditProductScreen extends StatefulWidget {
  /// null = add mode, non-null = edit mode
  final Product? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  bool get _isEdit => widget.product != null;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _sizeInputCtrl = TextEditingController();
  final _colorInputCtrl = TextEditingController();

  // State
  List<String> _sizes = [];
  List<String> _colors = [];
  List<String> _imageUrls = [];
  bool _isOnSale = false;
  bool _trackInventory = true;
  bool _isFeatured = false;
  ProductCategory _category = ProductCategory.tops;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _priceCtrl.text = p.price.toStringAsFixed(2);
      _sizes = List.from(p.availableSizes);
      _colors = List.from(p.availableColors);
      _imageUrls = List.from(p.imageUrls);
      _isOnSale = p.isOnSale;
      _trackInventory = true;
      _category = p.category;
      _stockCtrl.text = p.stockQuantity.toString();
      if (p.isOnSale && p.originalPrice != null) {
        _salePriceCtrl.text = p.originalPrice!.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _salePriceCtrl.dispose();
    _stockCtrl.dispose();
    _imageUrlCtrl.dispose();
    _sizeInputCtrl.dispose();
    _colorInputCtrl.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────
  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return 'Product name is required.';
    if (_priceCtrl.text.trim().isEmpty) return 'Base price is required.';
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) return 'Enter a valid price.';
    if (_isOnSale) {
      final sale = double.tryParse(_salePriceCtrl.text.trim());
      if (sale == null || sale <= 0) return 'Enter a valid sale price.';
      if (sale >= price) return 'Sale price must be lower than base price.';
    }
    if (_trackInventory) {
      final stock = int.tryParse(_stockCtrl.text.trim());
      if (stock == null || stock < 0) return 'Enter a valid stock quantity.';
    }
    return null;
  }

  // ── Save ────────────────────────────────────────────────────
  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      _snack(err, kError);
      return;
    }
    setState(() => _saving = true);

    final price = double.parse(_priceCtrl.text.trim());
    final originalPrice = _isOnSale
        ? price // current price is the sale price
        : null;
    // When on sale: originalPrice = base price, price = sale price
    final salePrice = _isOnSale
        ? double.parse(_salePriceCtrl.text.trim())
        : price;
    final resolvedOriginal = _isOnSale ? price : null;
    final resolvedPrice = _isOnSale
        ? double.parse(_salePriceCtrl.text.trim())
        : price;

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: resolvedPrice,
      originalPrice: _isOnSale ? price : null,
      imageUrls: _imageUrls.isEmpty ? [''] : _imageUrls,
      category: _category,
      availableSizes: _sizes,
      availableColors: _colors,
      stockQuantity: _trackInventory
          ? (int.tryParse(_stockCtrl.text.trim()) ?? 0)
          : 999,
      rating: widget.product?.rating ?? 0.0,
      reviewCount: widget.product?.reviewCount ?? 0,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
    );

    try {
      final prov = context.read<ProductProvider>();
      if (_isEdit) {
        await prov.updateProduct(product);
        _snack('Product updated successfully', const Color(0xFF2E7D32));
      } else {
        await prov.addProduct(product);
        _snack('Product added successfully', const Color(0xFF2E7D32));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _snack('Error: $e', kError);
    }
    if (mounted) setState(() => _saving = false);
  }

  // ── Delete ──────────────────────────────────────────────────
  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete Product',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        content: Text(
          'This will permanently delete "${_nameCtrl.text}". This cannot be undone.',
          style: TextStyle(
            fontSize: 13.5,
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
              backgroundColor: kError,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete',
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

    if (ok == true && mounted) {
      setState(() => _deleting = true);
      await context.read<ProductProvider>().deleteProduct(widget.product!.id);
      if (mounted) Navigator.of(context).pop();
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

  // ── Add size chip ───────────────────────────────────────────
  void _addSize() {
    final s = _sizeInputCtrl.text.trim().toUpperCase();
    if (s.isEmpty || _sizes.contains(s)) return;
    setState(() {
      _sizes.add(s);
      _sizeInputCtrl.clear();
    });
  }

  // ── Add color chip ──────────────────────────────────────────
  void _addColor() {
    final c = _colorInputCtrl.text.trim();
    if (c.isEmpty || _colors.contains(c)) return;
    setState(() {
      _colors.add(c);
      _colorInputCtrl.clear();
    });
  }

  // ── Add image URL ───────────────────────────────────────────
  void _addImage() {
    final url = _imageUrlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _imageUrls.add(url);
      _imageUrlCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      size: 22,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Product' : 'Add Product',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.textPrimary,
                            ),
                          )
                        : Text(
                            'Save',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: context.textPrimary,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── PRODUCT MEDIA ──────────────────
                    _SectionHeader('PRODUCT MEDIA'),
                    const SizedBox(height: 10),

                    // Main image preview
                    if (_imageUrls.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: double.infinity,
                          height: 200,
                          child: Image.network(
                            _imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: context.bgChip,
                              child: Icon(
                                Icons.image_outlined,
                                color: context.textHint,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: context.bgChip,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: context.border,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: context.textHint,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add product image',
                              style: TextStyle(
                                color: context.textHint,
                                fontFamily: 'Inter',
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Image URL input
                    _Field(
                      label: 'Image URL',
                      controller: _imageUrlCtrl,
                      hint: 'https://...',
                      suffix: GestureDetector(
                        onTap: _addImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.textPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Thumbnail strip
                    if (_imageUrls.length > 1) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (ctx, i) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _imageUrls[i],
                                  width: 56,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 56,
                                    height: 60,
                                    color: context.bgChip,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _imageUrls.removeAt(i)),
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE05050),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ─── BASIC INFORMATION ──────────────
                    _SectionHeader('BASIC INFORMATION'),
                    const SizedBox(height: 12),

                    _FieldLabel('PRODUCT NAME'),
                    const SizedBox(height: 6),
                    _textField(_nameCtrl, 'e.g. Artisan Leather Tote', context),

                    const SizedBox(height: 14),
                    _FieldLabel('DESCRIPTION'),
                    const SizedBox(height: 6),
                    _textField(
                      _descCtrl,
                      'Describe the product...',
                      context,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 16),

                    // Sizes
                    _FieldLabel('AVAILABLE SIZES'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._sizes.map(
                          (s) => _ChipTag(
                            label: s,
                            onRemove: () => setState(() => _sizes.remove(s)),
                          ),
                        ),
                        _AddChipButton(
                          controller: _sizeInputCtrl,
                          hint: 'Size',
                          onAdd: _addSize,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Colors
                    _FieldLabel('AVAILABLE COLORS'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._colors.map(
                          (c) => _ChipTag(
                            label: c,
                            dotColor: _namedColor(c),
                            onRemove: () => setState(() => _colors.remove(c)),
                          ),
                        ),
                        _AddChipButton(
                          controller: _colorInputCtrl,
                          hint: 'Color',
                          onAdd: _addColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ─── PRICING ────────────────────────
                    _SectionHeader('PRICING'),
                    const SizedBox(height: 12),

                    _FieldLabel('BASE PRICE (DT)'),
                    const SizedBox(height: 6),
                    _textField(
                      _priceCtrl,
                      '0.00',
                      context,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefix: Text(
                        'DT ',
                        style: TextStyle(
                          color: context.textSub,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // On sale toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sell_outlined,
                            color: context.textSub,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'On Sale',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textBody,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const Spacer(),
                          Switch.adaptive(
                            value: _isOnSale,
                            onChanged: (v) => setState(() => _isOnSale = v),
                            activeColor: kPrimary,
                          ),
                        ],
                      ),
                    ),

                    if (_isOnSale) ...[
                      const SizedBox(height: 12),
                      _FieldLabel('SALE PRICE (DT)'),
                      const SizedBox(height: 6),
                      _textField(
                        _salePriceCtrl,
                        '0.00',
                        context,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        prefix: Text(
                          'DT ',
                          style: TextStyle(
                            color: context.textSub,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ─── INVENTORY ──────────────────────
                    _SectionHeader('INVENTORY'),
                    const SizedBox(height: 12),

                    _FieldLabel('STOCK QUANTITY'),
                    const SizedBox(height: 6),
                    _textField(
                      _stockCtrl,
                      '0',
                      context,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),

                    const SizedBox(height: 12),

                    // Track inventory toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.track_changes_outlined,
                            color: context.textSub,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Track Inventory',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textBody,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const Spacer(),
                          Switch.adaptive(
                            value: _trackInventory,
                            onChanged: (v) =>
                                setState(() => _trackInventory = v),
                            activeColor: kPrimary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── ORGANIZATION ───────────────────
                    _SectionHeader('ORGANIZATION'),
                    const SizedBox(height: 12),

                    _FieldLabel('CATEGORY'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.border, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ProductCategory>(
                          value: _category,
                          isExpanded: true,
                          dropdownColor: context.bgSurface,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: context.textBody,
                          ),
                          items: ProductCategory.values.map((c) {
                            const labels = {
                              ProductCategory.tops: 'Tops',
                              ProductCategory.bottoms: 'Bottoms',
                              ProductCategory.dresses: 'Dresses',
                              ProductCategory.outerwear: 'Outerwear',
                              ProductCategory.accessories: 'Accessories',
                              ProductCategory.shoes: 'Shoes',
                            };
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                labels[c] ?? c.name,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: context.textBody,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (c) => setState(() => _category = c!),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ─── Delete (edit mode only) ─────────
                    if (_isEdit) ...[
                      GestureDetector(
                        onTap: _deleting ? null : _delete,
                        child: Center(
                          child: _deleting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: kError,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: kError,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Delete Product',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: kError,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'PRODUCT ID: ${widget.product!.id.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            color: context.textHint,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _namedColor(String name) {
    final map = {
      'sand': const Color(0xFFD4B896),
      'midnight': const Color(0xFF191970),
      'sage': const Color(0xFF7D9B76),
      'black': const Color(0xFF222222),
      'white': const Color(0xFFF5F5F5),
      'red': const Color(0xFFE05050),
      'blue': const Color(0xFF3B7DD8),
      'green': const Color(0xFF3A8C5C),
      'yellow': const Color(0xFFE8C03A),
      'pink': const Color(0xFFE87EA1),
      'gray': const Color(0xFF888888),
      'brown': const Color(0xFF8B6347),
      'navy': const Color(0xFF1B3A6B),
      'beige': const Color(0xFFF5E6C8),
    };
    return map[name.toLowerCase()];
  }

  Widget _textField(
    TextEditingController ctrl,
    String hint,
    BuildContext context, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefix,
  }) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    style: TextStyle(
      fontSize: 14,
      color: context.textBody,
      fontFamily: 'Inter',
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: context.textHint,
        fontFamily: 'Inter',
        fontSize: 13.5,
      ),
      prefix: prefix,
      filled: true,
      fillColor: context.bgSurface,
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.textPrimary, width: 1.5),
      ),
    ),
  );
}

// ── Section header ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      letterSpacing: 1.4,
      fontWeight: FontWeight.w700,
      fontFamily: 'Inter',
      color: context.textSub,
    ),
  );
}

// ── Field label ────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 10,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
      color: context.textHint,
    ),
  );
}

// ── Field with optional suffix ─────────────────────────────────
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final Widget? suffix;
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontSize: 13.5,
                color: context.textBody,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: context.textHint,
                  fontFamily: 'Inter',
                  fontSize: 13,
                ),
                filled: true,
                fillColor: context.bgSurface,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.border, width: 1.2),
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
          ),
          if (suffix != null) ...[const SizedBox(width: 8), suffix!],
        ],
      ),
    ],
  );
}

// ── Chip tag (size or color) ───────────────────────────────────
class _ChipTag extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final VoidCallback onRemove;
  const _ChipTag({required this.label, this.dotColor, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: context.bgChip,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.border, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dotColor != null) ...[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: context.textBody,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: onRemove,
          child: Icon(Icons.close, size: 13, color: context.textSub),
        ),
      ],
    ),
  );
}

// ── Add chip input button ──────────────────────────────────────
class _AddChipButton extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;
  const _AddChipButton({
    required this.controller,
    required this.hint,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 120,
    height: 34,
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => onAdd(),
            style: TextStyle(
              fontSize: 12.5,
              color: context.textBody,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: context.textHint,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
              filled: true,
              fillColor: context.bgSurface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.textPrimary, width: 1.3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.textPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 14),
          ),
        ),
      ],
    ),
  );
}
