import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nmls_mobile/checkout_screeen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme ────────────────────────────────────────────────────────────
const kDark       = Color(0xFF091925);
const kBlue       = Color(0xFF2EABFE);
const kBlueFaint  = Color(0x1A2EABFE);
const kBlueBorder = Color(0x382EABFE);
const kTeal       = Color(0xFF00B4B4);
const kTealFaint  = Color(0x1A00B4B4);
const kTealBorder = Color(0x3300B4B4);
const kAmber      = Color(0xFFF59E0B);
const kAmberFaint = Color(0x1AF59E0B);
const kGreen      = Color(0xFF22C55E);
const kBg         = Color(0xFFF6F7FB);
const kWhite      = Colors.white;
const kMuted      = Color(0xFF7FA8C4);
const kBorder     = Color(0x14020817);

class CartScreen extends StatefulWidget {
  final String? token;
  const CartScreen({super.key, this.token});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cart');
    setState(() {
      _cartItems = raw != null
          ? List<Map<String, dynamic>>.from(
              (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)))
          : [];
      _loading = false;
    });
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart', jsonEncode(_cartItems));
  }

  void _removeItem(int index) {
    setState(() => _cartItems.removeAt(index));
    _saveCart();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item removed from cart',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: kDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleTextbook(int index, bool value) {
    setState(() => _cartItems[index]['include_textbook'] = value);
    _saveCart();
  }

  double get _subtotal =>
      _cartItems.fold(0, (sum, item) => sum + ((item['price'] as num?) ?? 0));

  double get _textbookTotal => _cartItems.fold(
        0,
        (sum, item) => sum +
            (item['include_textbook'] == true
                ? ((item['textbook_price'] as num?) ?? 0)
                : 0),
      );

  double get _total => _subtotal + _textbookTotal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: kBlue, strokeWidth: 2.5))
                  : _cartItems.isEmpty
                      ? _buildEmpty(context)
                      : _buildBody(),
            ),
            if (!_loading && _cartItems.isNotEmpty) _buildCheckoutBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
        color: kDark,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Colors.white70),
            ),
            const Expanded(
              child: Text(
                'My Cart',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kWhite,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: kBlueFaint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBlueBorder),
              ),
              alignment: Alignment.center,
              child: Text(
                '${_cartItems.length}',
                style: const TextStyle(
                  color: kBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildBody() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SELECTED COURSES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: kMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(_cartItems.length, (i) => _CartItemCard(
                  item: _cartItems[i],
                  onRemove: () => _removeItem(i),
                  onToggleTextbook: (val) => _toggleTextbook(i, val),
                )),
            const SizedBox(height: 20),
            _buildSummaryCard(),
          ],
        ),
      );

  Widget _buildSummaryCard() => Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kDark,
              ),
            ),
            const SizedBox(height: 14),
            _summaryRow('Courses (${_cartItems.length})', '\$${_subtotal.toStringAsFixed(2)}'),
            if (_textbookTotal > 0) ...[
              const SizedBox(height: 8),
              _summaryRow('Textbooks', '\$${_textbookTotal.toStringAsFixed(2)}',
                  color: kAmber),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: kBorder, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: kDark)),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: kBlue,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _summaryRow(String label, String value, {Color? color}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: kMuted, fontWeight: FontWeight.w600)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color ?? kDark)),
        ],
      );

  Widget _buildCheckoutBar(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: kWhite,
          border: const Border(top: BorderSide(color: kBorder)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontSize: 13, color: kMuted, fontWeight: FontWeight.w700)),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: kDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  foregroundColor: kWhite,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      token: widget.token,
                      cartItems: _cartItems,
                    ),
                  ),
                ).then((_) => _loadCart()),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.credit_card_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildEmpty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kBlueFaint,
                  shape: BoxShape.circle,
                  border: Border.all(color: kBlueBorder),
                ),
                child: const Icon(Icons.shopping_cart_outlined,
                    size: 36, color: kBlue),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your cart is empty',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: kDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add courses from the catalog to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: kMuted),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: kBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Browse Courses',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: kWhite),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Cart Item Card ───────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;
  final ValueChanged<bool> onToggleTextbook;

  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onToggleTextbook,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? 'Course';
    final type = (item['type'] as String? ?? '').toUpperCase();
    final hours = (item['credit_hours'] as num?)?.toInt() ?? 0;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final hasTextbook = item['has_textbook'] == true || item['textbook_price'] != null;
    final includeTextbook = item['include_textbook'] == true;
    final textbookPrice = (item['textbook_price'] as num?)?.toDouble() ?? 0;

    final isPE = type == 'PE';
    final accentColor = isPE ? kBlue : kTeal;
    final accentFaint = isPE ? kBlueFaint : kTealFaint;
    final accentBorder = isPE ? kBlueBorder : kTealBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          // Accent top bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentFaint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentBorder),
                      ),
                      child: Icon(Icons.menu_book_outlined,
                          color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentFaint,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: accentBorder),
                                ),
                                child: Text(type,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: accentColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: kDark)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule_outlined,
                                  size: 12, color: kMuted),
                              const SizedBox(width: 4),
                              Text('$hours credit hrs',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: kMuted,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Price + remove
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: kDark,
                              letterSpacing: -0.4),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFFFD1CF)),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 14, color: Color(0xFFC0392B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Textbook toggle
                if (hasTextbook && textbookPrice > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: kAmberFaint,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0x38F59E0B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.book_outlined,
                            size: 14, color: kAmber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Add Textbook',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: kDark)),
                              Text(
                                '+\$${textbookPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: kAmber,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: includeTextbook,
                          onChanged: onToggleTextbook,
                          activeColor: kAmber,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}