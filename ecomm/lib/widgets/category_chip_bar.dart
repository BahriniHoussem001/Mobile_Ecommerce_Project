// lib/widgets/category_chip_bar.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class CategoryChipBar extends StatelessWidget {
  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onSelected;

  const CategoryChipBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const _labels = {
    null: 'All',
    ProductCategory.tops: 'Tops',
    ProductCategory.bottoms: 'Bottoms',
    ProductCategory.dresses: 'Dresses',
    ProductCategory.outerwear: 'Outerwear',
    ProductCategory.accessories: 'Accessories',
    ProductCategory.shoes: 'Shoes',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _labels.entries.map((entry) {
          final isActive = selected == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? context.textPrimary : context.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? context.textPrimary : context.border,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? Colors.white : context.textBody,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
