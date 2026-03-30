import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/config/api_config.dart';

// ─── Theme ────────────────────────────────────────────────────────────
const _kDark       = Color(0xFF091925);
const _kBlue       = Color(0xFF2EABFE);
const _kBlueFaint  = Color(0x1A2EABFE);
const _kBlueBorder = Color(0x382EABFE);
const _kAmber      = Color(0xFFF59E0B);
const _kAmberFaint = Color(0x1AF59E0B);
const _kGreen      = Color(0xFF22C55E);
const _kGreenFaint = Color(0x1A22C55E);
const _kBg         = Color(0xFFF6F7FB);
const _kWhite      = Colors.white;
const _kMuted      = Color(0xFF7FA8C4);
const _kBorder     = Color(0x14020817);

class CheckoutScreen extends StatefulWidget {
  final String? token;
  final List<Map<String, dynamic>> cartItems;

  const CheckoutScreen({
    super.key,
    this.token,
    required this.cartItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _loading   = false;
  bool _submitted = false;
  String _error   = '';
  String _orderId = '';

  final _formKey = GlobalKey<FormState>();

  // Billing form controllers
  final _firstNameCtrl       = TextEditingController();
  final _lastNameCtrl        = TextEditingController();
  final _companyCtrl         = TextEditingController();
  final _streetCtrl          = TextEditingController();
  final _cityCtrl            = TextEditingController();
  final _stateCtrl           = TextEditingController();
  final _zipCtrl             = TextEditingController();
  final _phoneCtrl           = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _notesCtrl           = TextEditingController();
  String _country            = 'United States';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
  };

  double get _subtotal =>
      widget.cartItems.fold(0, (sum, item) => sum + ((item['price'] as num?) ?? 0));

  double get _textbookTotal => widget.cartItems.fold(
        0,
        (sum, item) => sum +
            (item['include_textbook'] == true
                ? ((item['textbook_price'] as num?) ?? 0)
                : 0),
      );

  double get _total => _subtotal + _textbookTotal;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _companyCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = ''; });

    try {
      final payload = {
        'items': widget.cartItems.map((item) => {
          'course_id':        item['_id'],
          'include_textbook': item['include_textbook'] ?? false,
          'price':            (item['price'] as num?)?.toDouble() ?? 0,
          'textbook_price':   item['include_textbook'] == true
              ? (item['textbook_price'] as num?)?.toDouble() ?? 0
              : 0,
        }).toList(),
        'total_amount': _total,
        'billing': {
          'first_name':      _firstNameCtrl.text.trim(),
          'last_name':       _lastNameCtrl.text.trim(),
          'company_name':    _companyCtrl.text.trim(),
          'country':         _country,
          'street_address':  _streetCtrl.text.trim(),
          'town_city':       _cityCtrl.text.trim(),
          'state':           _stateCtrl.text.trim(),
          'zip_code':        _zipCtrl.text.trim(),
          'phone':           _phoneCtrl.text.trim(),
          'email':           _emailCtrl.text.trim(),
          'additional_info': _notesCtrl.text.trim(),
        },
      };

      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/orders'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>?;
        final id = data?['_id'] as String? ??
            (data?['order'] as Map?)?['_id'] as String? ?? '';
        setState(() { _orderId = id; _submitted = true; });
      } else {
        final data = jsonDecode(res.body) as Map<String, dynamic>?;
        setState(() => _error = data?['message'] as String? ?? 'Failed to place order.');
      }
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen(context);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error.isNotEmpty) _buildErrorBanner(),
                    _buildBillingForm(),
                    const SizedBox(height: 16),
                    _buildOrderSummary(),
                    const SizedBox(height: 24),
                    _buildPlaceOrderBtn(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
        color: _kDark,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Colors.white70),
            ),
            const Expanded(
              child: Column(
                children: [
                  Text(
                    'Checkout',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kWhite,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Billing details & order summary',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 26),
          ],
        ),
      );

  Widget _buildErrorBanner() => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD1CF)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 16, color: Color(0xFFC0392B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_error,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC0392B),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  // ── Billing form ──────────────────────────────────────────────────
  Widget _buildBillingForm() => Container(
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('BILLING & SHIPPING', Icons.location_on_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _field('First Name', _firstNameCtrl,
                          required: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field('Last Name', _lastNameCtrl,
                          required: true)),
                ],
              ),
              const SizedBox(height: 12),
              _field('Company Name (optional)', _companyCtrl),
              const SizedBox(height: 12),
              // Country dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Country / Region',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kMuted)),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE3E5E8)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _country,
                        isExpanded: true,
                        style: const TextStyle(
                            fontSize: 14,
                            color: _kDark,
                            fontWeight: FontWeight.w600),
                        items: const [
                          DropdownMenuItem(
                              value: 'United States',
                              child: Text('United States')),
                          DropdownMenuItem(
                              value: 'Canada', child: Text('Canada')),
                          DropdownMenuItem(
                              value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) =>
                            setState(() => _country = val ?? _country),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field('Street Address', _streetCtrl, required: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child:
                          _field('Town / City', _cityCtrl, required: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field('State', _stateCtrl, required: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child:
                          _field('Zip Code', _zipCtrl, required: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field('Phone', _phoneCtrl,
                          required: true,
                          keyboardType: TextInputType.phone)),
                ],
              ),
              const SizedBox(height: 12),
              _field('Email Address', _emailCtrl,
                  required: true, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              // Notes textarea
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Additional Information',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kMuted)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Order notes, special instructions…',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: Color(0xFFADB5BD)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFB),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE3E5E8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE3E5E8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _kBlue, width: 1.5),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14, color: _kDark),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label + (required ? '*' : ''),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kMuted)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: required
                ? (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null
                : null,
            decoration: InputDecoration(
              hintStyle:
                  const TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
              filled: true,
              fillColor: const Color(0xFFF8FAFB),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE3E5E8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE3E5E8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _kBlue, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFFEF4444), width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 14, color: _kDark),
          ),
        ],
      );

  // ── Order summary ─────────────────────────────────────────────────
  Widget _buildOrderSummary() => Container(
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('YOUR ORDER', Icons.receipt_long_outlined),
            const SizedBox(height: 14),
            ...widget.cartItems.map((item) => _OrderLineItem(item: item)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: _kBorder, height: 1),
            ),
            _totalRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
            if (_textbookTotal > 0) ...[
              const SizedBox(height: 6),
              _totalRow('Textbooks', '+\$${_textbookTotal.toStringAsFixed(2)}',
                  valueColor: _kAmber),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kBlueFaint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBlueBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _kDark)),
                  Text(
                    '\$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _kBlue,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Pending note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kAmberFaint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x38F59E0B)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: _kAmber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your order will be marked pending until payment is confirmed by an admin.',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92600A),
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _totalRow(String label, String value, {Color? valueColor}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: _kMuted,
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? _kDark)),
        ],
      );

  Widget _sectionLabel(String label, IconData icon) => Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _kBlueFaint,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBlueBorder),
            ),
            child: Icon(icon, size: 15, color: _kBlue),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _kDark,
                  letterSpacing: 0.5)),
        ],
      );

  // ── Place order button ────────────────────────────────────────────
  Widget _buildPlaceOrderBtn() => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kDark,
            foregroundColor: _kWhite,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: _loading ? null : _placeOrder,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: _kWhite, strokeWidth: 2.5),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.credit_card_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Place Order',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
        ),
      );

  // ── Success screen ────────────────────────────────────────────────
  Widget _buildSuccessScreen(BuildContext context) => Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: _kGreenFaint,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0x3822C55E), width: 2),
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded,
                        size: 44, color: _kGreen),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Order Placed!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _kDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_orderId.isNotEmpty)
                    Text(
                      'Order #${_orderId.length > 6 ? _orderId.substring(_orderId.length - 6).toUpperCase() : _orderId.toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 14,
                          color: _kBlue,
                          fontWeight: FontWeight.w800),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kAmberFaint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x38F59E0B)),
                    ),
                    child: const Text(
                      'Once payment is confirmed by an admin, your courses will be unlocked and ready to start.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92600A),
                          height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: _kWhite,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      child: const Text('Go to Dashboard',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () =>
                          Navigator.of(context).pop(),
                      child: const Text('Browse More Courses',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _kDark)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// ─── Order Line Item ──────────────────────────────────────────────────
class _OrderLineItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const _OrderLineItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? 'Course';
    final type = (item['type'] as String? ?? '').toUpperCase();
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final includeTextbook = item['include_textbook'] == true;
    final textbookPrice = (item['textbook_price'] as num?)?.toDouble() ?? 0;
    final isPE = type == 'PE';
    final accentColor = isPE ? _kBlue : const Color(0xFF00B4B4);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.22)),
            ),
            child:
                Icon(Icons.menu_book_outlined, color: accentColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _kDark)),
                Text(type,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accentColor)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _kDark)),
              if (includeTextbook && textbookPrice > 0)
                Text('+\$${textbookPrice.toStringAsFixed(2)} book',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _kAmber)),
            ],
          ),
        ],
      ),
    );
  }
}