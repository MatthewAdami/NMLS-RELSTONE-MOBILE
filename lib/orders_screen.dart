import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/config/api_config.dart';

// ─── Theme Constants (matches dashboard/courses) ──────────────────────
const kDark        = Color(0xFF091925);
const kBlue        = Color(0xFF2EABFE);
const kBlueFaint   = Color(0x1A2EABFE);
const kBlueBorder  = Color(0x382EABFE);
const kTeal        = Color(0xFF00B4B4);
const kTealFaint   = Color(0x1A00B4B4);
const kTealBorder  = Color(0x3300B4B4);
const kAmber       = Color(0xFFF59E0B);
const kAmberFaint  = Color(0x1AF59E0B);
const kAmberBorder = Color(0x38F59E0B);
const kGreen       = Color(0xFF22C55E);
const kGreenFaint  = Color(0x1A22C55E);
const kGreenBorder = Color(0x3822C55E);
const kBg          = Color(0xFFF6F7FB);
const kWhite       = Colors.white;
const kMuted       = Color(0x990B1220);
const kBorder      = Color(0x1A020817);
const kSurface     = Color(0xD0FFFFFF);

class OrdersScreen extends StatefulWidget {
  final String? token;
  const OrdersScreen({Key? key, this.token}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool   _loading = true;
  String _error   = '';

  String get _apiBase => '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}';
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
  };

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await http
          .get(Uri.parse('$_apiBase/orders/my'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() => _orders = data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      } else {
        setState(() => _error = 'Failed to load orders (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(context),
          Expanded(child: _buildBody()),
        ]),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kDark),
          ),
        ),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('My Orders', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900,
              color: kDark, letterSpacing: -0.3)),
          Text('Purchase history', style: TextStyle(
              fontSize: 12, color: kMuted, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: SizedBox(
        width: 32, height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(kBlue),
        ),
      ));
    }

    if (_error.isNotEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: const Color(0x1AC0392B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x38C0392B)),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFC0392B), size: 22),
          ),
          const SizedBox(height: 12),
          Text(_error, textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 14)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchOrders,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(12)),
              child: const Text('Retry',
                  style: TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ),
        ]),
      ));
    }

    if (_orders.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: kBlueFaint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBlueBorder),
            ),
            child: const Icon(Icons.receipt_long_outlined, color: kBlue, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('No orders yet', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900, color: kDark)),
          const SizedBox(height: 6),
          const Text('Your course purchases will appear here.',
              style: TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
        ]),
      ));
    }

    return RefreshIndicator(
      color: kBlue,
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (ctx, i) {
          // Show newest first
          final order = _orders[_orders.length - 1 - i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _OrderCard(order: order),
          );
        },
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) { return iso; }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':      return kGreen;
      case 'pending':   return kAmber;
      case 'cancelled': return const Color(0xFFC0392B);
      default:          return kMuted;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'paid':      return kGreenFaint;
      case 'pending':   return kAmberFaint;
      case 'cancelled': return const Color(0x1AC0392B);
      default:          return const Color(0x1A888888);
    }
  }

  Color _statusBorder(String status) {
    switch (status.toLowerCase()) {
      case 'paid':      return kGreenBorder;
      case 'pending':   return kAmberBorder;
      case 'cancelled': return const Color(0x38C0392B);
      default:          return const Color(0x38888888);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':      return Icons.check_circle_outline;
      case 'pending':   return Icons.access_time_outlined;
      case 'cancelled': return Icons.cancel_outlined;
      default:          return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status     = (widget.order['status'] as String?) ?? 'pending';
    final total      = widget.order['total_amount'] ?? 0;
    final createdAt  = _fmtDate(widget.order['createdAt'] as String?);
    final items      = (widget.order['items'] as List?) ?? [];
    final orderId    = (widget.order['_id'] as String?) ?? '';
    final shortId    = orderId.length > 8 ? orderId.substring(orderId.length - 8).toUpperCase() : orderId.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 16, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // Order icon
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: kBlueFaint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBlueBorder),
              ),
              child: const Icon(Icons.receipt_long_outlined, color: kBlue, size: 20),
            ),
            const SizedBox(width: 12),

            // Order ID + date
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #$shortId', style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: kDark)),
              if (createdAt.isNotEmpty)
                Text(createdAt, style: const TextStyle(
                    fontSize: 12, color: kMuted, fontWeight: FontWeight.w700)),
            ])),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusBg(status),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _statusBorder(status)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_statusIcon(status), size: 12, color: _statusColor(status)),
                const SizedBox(width: 5),
                Text(status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                        color: _statusColor(status))),
              ]),
            ),
          ]),
        ),

        // ── Divider ──────────────────────────────────────────────────
        const Divider(color: kBorder, height: 1),

        // ── Summary row ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            // Items count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kBlueFaint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBlueBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.menu_book_outlined, size: 13, color: kBlue),
                const SizedBox(width: 5),
                Text('${items.length} course${items.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kBlue)),
              ]),
            ),
            const Spacer(),

            // Total
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Total', style: TextStyle(
                  fontSize: 11, color: kMuted, fontWeight: FontWeight.w700)),
              Text('\$${total is num ? total.toStringAsFixed(2) : total}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900,
                      color: kDark, letterSpacing: -0.5)),
            ]),
          ]),
        ),

        // ── Expand/collapse items ─────────────────────────────────────
        if (items.isNotEmpty) ...[
          const Divider(color: kBorder, height: 1),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(children: [
                const Text('Course Details', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w900, color: kDark)),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: kMuted),
                ),
              ]),
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(color: kBorder, height: 1),
                ...items.asMap().entries.map((entry) {
                  final i    = entry.key;
                  final item = Map<String, dynamic>.from(entry.value as Map);
                  return _CourseLineItem(
                    item: item,
                    isLast: i == items.length - 1,
                  );
                }),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ]),
    );
  }
}

// ─── Course Line Item ─────────────────────────────────────────────────
class _CourseLineItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isLast;
  const _CourseLineItem({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final courseData = item['course_id'];
    final course = courseData is Map
        ? Map<String, dynamic>.from(courseData)
        : <String, dynamic>{};

    final title      = course['title']       as String? ?? 'Course';
    final type       = (course['type']        as String? ?? '').toUpperCase();
    final creditHrs  = course['credit_hours'] ?? 0;
    final price      = item['price']          ?? 0;
    final textbook   = item['include_textbook'] == true;
    final tbPrice    = item['textbook_price'] ?? 0;

    final isPE        = type == 'PE';
    final badgeColor  = isPE ? kBlue : kTeal;
    final badgeBg     = isPE ? kBlueFaint : kTealFaint;
    final badgeBorder = isPE ? kBlueBorder : kTealBorder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Course icon
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: badgeBorder),
          ),
          child: Icon(Icons.menu_book_outlined, color: badgeColor, size: 16),
        ),
        const SizedBox(width: 12),

        // Course info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (type.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: badgeBorder),
              ),
              child: Text(type, style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w900, color: badgeColor)),
            ),
          Text(title, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w900, color: kDark)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.access_time_outlined, size: 12, color: kMuted),
            const SizedBox(width: 4),
            Text('$creditHrs credit hrs',
                style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w700)),
            if (textbook) ...[
              const SizedBox(width: 8),
              const Icon(Icons.book_outlined, size: 12, color: kAmber),
              const SizedBox(width: 4),
              const Text('+ Textbook',
                  style: TextStyle(fontSize: 11, color: kAmber, fontWeight: FontWeight.w700)),
            ],
          ]),
        ])),

        // Price
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${price is num ? price.toStringAsFixed(2) : price}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: kDark)),
          if (textbook && tbPrice != 0)
            Text('+\$${tbPrice is num ? tbPrice.toStringAsFixed(2) : tbPrice}',
                style: const TextStyle(
                    fontSize: 11, color: kAmber, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}