import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class AtelierAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBack;
  final bool showCart;
  final bool showWishlist;
  final List<Widget>? extraActions;
  final VoidCallback? onCartTap;
  final VoidCallback? onWishlistTap;

  const AtelierAppBar({
    super.key,
    this.title,
    this.showBack = false,
    this.showCart = true,
    this.showWishlist = true,
    this.extraActions,
    this.onCartTap,
    this.onWishlistTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 60,
        child: Padding(
          // Consistent 20px horizontal padding everywhere
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: back arrow OR brand title
              if (showBack)
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: Color(0xFF1B3A6B),
                    ),
                  ),
                ),

              // Brand title (always centred when showBack = false, left-aligned otherwise)
              Expanded(
                child: Text(
                  title ?? 'The Atelier',
                  textAlign: showBack ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: showBack == true ? 17 : 22,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B3A6B),
                    letterSpacing: 0.4,
                  ),
                ),
              ),

              // Right actions
              if (extraActions != null) ...extraActions!,

              if (showWishlist) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.favorite_border,
                    color: Color(0xFF1B3A6B),
                    size: 23,
                  ),
                  onPressed: onWishlistTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],

              if (showCart) ...[
                const SizedBox(width: 2),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFF1B3A6B),
                        size: 23,
                      ),
                      onPressed: onCartTap,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B3A6B),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$cartCount',
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
