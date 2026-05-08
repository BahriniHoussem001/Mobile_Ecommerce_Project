import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon.dart';
import '../providers/cart_provider.dart';

class CouponField extends StatefulWidget {
  const CouponField({super.key});

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final _ctrl = TextEditingController();
  bool _isLoading = false;
  String? _feedback;
  bool _success = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _feedback = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('coupons')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        setState(() {
          _feedback = 'Coupon not found.';
          _success = false;
        });
      } else {
        final coupon = Coupon.fromMap(
          snap.docs.first.data(),
          snap.docs.first.id,
        );
        final cart = context.read<CartProvider>();
        final error = cart.applyCoupon(coupon);
        if (error == null) {
          setState(() {
            _feedback = 'Coupon applied!';
            _success = true;
          });
        } else {
          setState(() {
            _feedback = error;
            _success = false;
          });
        }
      }
    } catch (_) {
      setState(() {
        _feedback = 'Something went wrong. Try again.';
        _success = false;
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _success
                        ? const Color(0xFF2E7D32)
                        : (_feedback != null && !_success)
                        ? const Color(0xFFE05050)
                        : const Color(0xFFDDDDDD),
                    width: 1.4,
                  ),
                ),
                child: TextField(
                  controller: _ctrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 14,
                    letterSpacing: 1.2,
                    color: Color(0xFF1B3A6B),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'COUPON CODE',
                    hintStyle: TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 13,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3A6B),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Apply',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
        if (_feedback != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                _success ? Icons.check_circle_outline : Icons.error_outline,
                size: 14,
                color: _success
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE05050),
              ),
              const SizedBox(width: 5),
              Text(
                _feedback!,
                style: TextStyle(
                  fontSize: 12,
                  color: _success
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE05050),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
