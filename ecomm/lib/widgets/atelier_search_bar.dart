import 'package:flutter/material.dart';

class AtelierSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  const AtelierSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search The Atelier…',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1.3),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13.5),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFAAAAAA),
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFFAAAAAA),
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 4,
          ),
        ),
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────
// lib/widgets/product_shimmer.dart  — skeleton loading card
// ─────────────────────────────────────────────────────────────

 
 
// ─────────────────────────────────────────────────────────────
// lib/widgets/coupon_field.dart
// ─────────────────────────────────────────────────────────────
