import 'package:flutter/material.dart';

class ProductShimmer extends StatefulWidget {
  const ProductShimmer({super.key});

  @override
  State<ProductShimmer> createState() => _ProductShimmerState();
}

class _ProductShimmerState extends State<ProductShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = Color.lerp(
          const Color(0xFFF0EEEC),
          const Color(0xFFE0DDD9),
          _anim.value,
        )!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(color: shimmer),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 13,
              width: 110,
              color: shimmer,
              margin: const EdgeInsets.only(bottom: 6),
            ),
            Container(height: 12, width: 70, color: shimmer),
          ],
        );
      },
    );
  }
}
