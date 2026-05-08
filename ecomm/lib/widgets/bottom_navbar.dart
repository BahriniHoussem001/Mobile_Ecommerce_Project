import 'package:flutter/material.dart';

class AtelierBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AtelierBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_outlined, Icons.home, 'HOME'),
    (Icons.search_outlined, Icons.search, 'SEARCH'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'ORDERS'),
    (Icons.person_outline, Icons.person, 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
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
                    color: active
                        ? const Color(0xFF1B3A6B)
                        : const Color(0xFFAAAAAA),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _items[i].$3,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? const Color(0xFF1B3A6B)
                          : const Color(0xFFAAAAAA),
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
