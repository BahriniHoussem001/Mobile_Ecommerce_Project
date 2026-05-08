// lib/pages/client/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/app_user.dart';
import '../../theme/app_theme.dart';

enum _ShippingMethod { standard, express }

enum _PaymentMethod { stripe, cod }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  _ShippingMethod _shipping = _ShippingMethod.standard;
  _PaymentMethod _payment = _PaymentMethod.stripe;
  bool _placing = false;

  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();

  double get _shippingCost => _shipping == _ShippingMethod.express ? 25.0 : 0.0;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvcCtrl.dispose();
    super.dispose();
  }

  Future<void> _completePurchase() async {
    if (_placing) return;

    if (_payment == _PaymentMethod.stripe) {
      final cardNum = _cardNumberCtrl.text.replaceAll(' ', '');
      if (cardNum.length < 16) {
        _showError('Please enter a valid card number.');
        return;
      }
      if (_expiryCtrl.text.isEmpty) {
        _showError('Please enter the expiry date.');
        return;
      }
      if (_cvcCtrl.text.length < 3) {
        _showError('Please enter a valid CVC.');
        return;
      }
    }

    setState(() => _placing = true);

    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final orderProv = context.read<OrderProvider>();

    if (auth.user == null) {
      setState(() => _placing = false);
      return;
    }

    final address = auth.user!.addresses.isNotEmpty
        ? auth.user!.addresses.first
        : ShippingAddress(
            id: 'default',
            label: 'Default',
            fullName: auth.user!.name,
            street: '—',
            city: '—',
            postalCode: '—',
            country: '—',
          );

    final order = await orderProv.placeOrder(
      userId: auth.user!.uid,
      items: cart.snapshot,
      shippingAddress: address,
      subtotal: cart.subtotal,
      shippingFee: _shippingCost,
      discount: cart.discountAmount,
      couponCode: cart.appliedCoupon?.code,
      paymentMethod: _payment == _PaymentMethod.stripe
          ? 'stripe'
          : 'cash_on_delivery',
    );

    if (order != null && mounted) {
      cart.clearCart();
      Navigator.of(context).popUntil((r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✓ Order placed successfully!',
            style: TextStyle(fontFamily: 'Inter'),
          ),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    if (mounted) setState(() => _placing = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: kError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final tax = cart.subtotal * 0.08;
    final total = cart.subtotal - cart.discountAmount + _shippingCost + tax;

    return Scaffold(
      backgroundColor: context.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Secure Checkout',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Delivery address ──────────────────────────────
                    Row(
                      children: [
                        Text(
                          'DELIVERY ADDRESS',
                          style: TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 1.5,
                            color: context.textSub,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Add New',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (user != null && user.addresses.isNotEmpty)
                      ...user.addresses.map(
                        (addr) => _AddressCard(
                          address: addr,
                          selected: addr.isDefault,
                        ),
                      )
                    else
                      _AddressCard(
                        address: ShippingAddress(
                          id: 'ph',
                          label: 'Home',
                          fullName: user?.name ?? 'Your Name',
                          street: '724 Fifth Avenue, 9th Floor',
                          city: 'Tunis',
                          postalCode: '1000',
                          country: 'Tunisia',
                          isDefault: true,
                        ),
                        selected: true,
                      ),

                    const SizedBox(height: 24),

                    // ── Shipping method ───────────────────────────────
                    Text(
                      'SHIPPING METHOD',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.5,
                        color: context.textSub,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ShippingOption(
                      title: 'Standard Delivery',
                      subtitle: 'Est. 3–5 business days',
                      price: 'Free',
                      priceColor: const Color(0xFF2E7D32),
                      selected: _shipping == _ShippingMethod.standard,
                      onTap: () =>
                          setState(() => _shipping = _ShippingMethod.standard),
                    ),
                    const SizedBox(height: 8),
                    _ShippingOption(
                      title: 'Express Atelier',
                      subtitle: 'Est. arrival: Tomorrow, by 10 AM',
                      price: '25 DT',
                      priceColor: context.textPrimary,
                      selected: _shipping == _ShippingMethod.express,
                      onTap: () =>
                          setState(() => _shipping = _ShippingMethod.express),
                    ),

                    const SizedBox(height: 24),

                    // ── Payment method ────────────────────────────────
                    Text(
                      'PAYMENT METHOD',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.5,
                        color: context.textSub,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Stripe card
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _payment == _PaymentMethod.stripe
                              ? context.textPrimary
                              : context.border,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => setState(
                              () => _payment = _PaymentMethod.stripe,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: context.textPrimary.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.credit_card,
                                      color: context.textPrimary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Stripe (Credit/Debit Card)',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                  ),
                                  _RadioDot(
                                    selected: _payment == _PaymentMethod.stripe,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_payment == _PaymentMethod.stripe)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(height: 1, color: context.divider),
                                  const SizedBox(height: 14),
                                  _FieldLabel('CARD NUMBER'),
                                  const SizedBox(height: 6),
                                  _CardField(
                                    controller: _cardNumberCtrl,
                                    hint: '0000 0000 0000 0000',
                                    suffix: Icon(
                                      Icons.credit_card_outlined,
                                      size: 18,
                                      color: context.textHint,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      _CardNumberFormatter(),
                                    ],
                                    keyboardType: TextInputType.number,
                                    maxLength: 19,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FieldLabel('EXPIRY DATE'),
                                            const SizedBox(height: 6),
                                            _CardField(
                                              controller: _expiryCtrl,
                                              hint: 'MM / YY',
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                                _ExpiryFormatter(),
                                              ],
                                              keyboardType:
                                                  TextInputType.number,
                                              maxLength: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FieldLabel('CVC'),
                                            const SizedBox(height: 6),
                                            _CardField(
                                              controller: _cvcCtrl,
                                              hint: '•••',
                                              suffix: Icon(
                                                Icons.info_outline,
                                                size: 16,
                                                color: context.textHint,
                                              ),
                                              obscureText: true,
                                              keyboardType:
                                                  TextInputType.number,
                                              maxLength: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Cash on delivery
                    GestureDetector(
                      onTap: () =>
                          setState(() => _payment = _PaymentMethod.cod),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.bgSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _payment == _PaymentMethod.cod
                                ? context.textPrimary
                                : context.border,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: context.textPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.payments_outlined,
                                color: context.textPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Payment on Delivery',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                            _RadioDot(selected: _payment == _PaymentMethod.cod),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Order summary ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.bgChip,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _SRow(
                            'Subtotal (${cart.itemCount} item${cart.itemCount != 1 ? 's' : ''})',
                            '${cart.subtotal.toStringAsFixed(2)} DT',
                          ),
                          const SizedBox(height: 8),
                          _SRow(
                            'Shipping',
                            _shipping == _ShippingMethod.standard
                                ? 'Free'
                                : '25 DT',
                            valueColor: _shipping == _ShippingMethod.standard
                                ? const Color(0xFF2E7D32)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          _SRow('Est. Tax', '${tax.toStringAsFixed(2)} DT'),
                          if (cart.discountAmount > 0) ...[
                            const SizedBox(height: 8),
                            _SRow(
                              'Discount (${cart.appliedCoupon?.code})',
                              '−${cart.discountAmount.toStringAsFixed(2)} DT',
                              valueColor: const Color(0xFF2E7D32),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: context.divider),
                          ),
                          Row(
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${total.toStringAsFixed(2)} DT',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: context.textSub,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'END-TO-END ENCRYPTED TRANSACTION',
                          style: TextStyle(
                            fontSize: 9.5,
                            letterSpacing: 1.2,
                            color: context.textSub,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Sticky CTA ──────────────────────────────────────────────
      bottomNavigationBar: Container(
        color: context.bgSurface,
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _placing ? null : _completePurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              disabledBackgroundColor: kPrimary.withOpacity(0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _placing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Complete Purchase',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  final ShippingAddress address;
  final bool selected;
  const _AddressCard({required this.address, required this.selected});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.bgSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: selected ? context.textPrimary : context.border,
        width: 1.5,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address.fullName,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address.street,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSub,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                '${address.city}, ${address.postalCode}',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSub,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                address.country,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSub,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        if (selected)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: context.textPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
      ],
    ),
  );
}

class _ShippingOption extends StatelessWidget {
  final String title, subtitle, price;
  final Color priceColor;
  final bool selected;
  final VoidCallback onTap;
  const _ShippingOption({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? context.textPrimary : context.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSub,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: priceColor,
            ),
          ),
          const SizedBox(width: 12),
          _RadioDot(selected: selected),
        ],
      ),
    ),
  );
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? context.textPrimary : context.border,
        width: 2,
      ),
    ),
    child: selected
        ? Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: context.textPrimary,
                shape: BoxShape.circle,
              ),
            ),
          )
        : null,
  );
}

class _CardField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  const _CardField({
    required this.controller,
    required this.hint,
    this.suffix,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    maxLength: maxLength,
    style: TextStyle(
      fontSize: 14,
      color: context.textBody,
      fontFamily: 'Inter',
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: context.textHint,
        fontSize: 13.5,
        fontFamily: 'Inter',
      ),
      suffixIcon: suffix,
      counterText: '',
      filled: true,
      fillColor: context.bgInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.border, width: 1.3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.textPrimary, width: 1.5),
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 9.5,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
      color: context.textSub,
      fontFamily: 'Inter',
    ),
  );
}

class _SRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _SRow(this.label, this.value, {this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: context.textSub,
            fontFamily: 'Inter',
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: valueColor ?? context.textBody,
            fontFamily: 'Inter',
          ),
        ),
      ],
    ),
  );
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final digits = n.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final f = buf.toString();
    return TextEditingValue(
      text: f,
      selection: TextSelection.collapsed(offset: f.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final digits = n.text.replaceAll('/', '');
    final f = digits.length >= 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: f,
      selection: TextSelection.collapsed(offset: f.length),
    );
  }
}
