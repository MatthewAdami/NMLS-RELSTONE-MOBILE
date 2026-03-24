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
        child: Column(
          children: [
            _buildTopSection(context),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    final totalSpent = _displayOrders.fold<num>(
      0,
      (sum, order) => sum + ((order['total_amount'] as num?) ?? 0),
    );

    return Container(
      color: kDark,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
              const Expanded(
                child: Text(
                  'Orders & Billing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 18),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F334D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '\$${totalSpent.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: kBlue,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Text(
                        'Total Spent',
                        style: TextStyle(
                          color: Color(0xFF7D92A3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F334D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_displayOrders.length}',
                        style: const TextStyle(
                          color: kBlue,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Text(
                        'Total Orders',
                        style: TextStyle(
                          color: Color(0xFF7D92A3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(kBlue),
            ),
        ),
      );
    }

    final orders = _displayOrders;

    return RefreshIndicator(
      color: kBlue,
      onRefresh: _fetchOrders,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        child: Column(
          children: [
            if (_error.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD1CF)),
                ),
                child: const Text(
                  'Could not fetch live orders. Showing sample UI.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFC0392B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Container(
              alignment: Alignment.centerLeft,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              child: const Text(
                'PURCHASE HISTORY',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: kDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: List.generate(orders.length, (i) {
                  final order = orders[i];
                  return _buildHistoryRow(
                    order: order,
                    isLast: i == orders.length - 1,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow({
    required Map<String, dynamic> order,
    required bool isLast,
  }) {
    final total = (order['total_amount'] as num?) ?? 0;
    final status = ((order['status'] as String?) ?? 'paid').toLowerCase();
    final createdAt = _formatDate(order['createdAt'] as String?);
    final items = (order['items'] as List?) ?? [];
    final firstItem = items.isNotEmpty ? Map<String, dynamic>.from(items.first as Map) : <String, dynamic>{};
    final courseData = firstItem['course_id'];
    final course = courseData is Map<String, dynamic> ? courseData : <String, dynamic>{};
    final title = (course['title'] as String?) ?? 'Course Purchase';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0x12020817))),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      createdAt,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7D92A3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kDark,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8EE),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      status == 'paid' ? 'Paid' : status[0].toUpperCase() + status.substring(1),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionPill(
                label: title == 'Real Estate Principles' ? 'Invoice PDF' : 'Invoice',
                icon: Icons.download_rounded,
                color: kBlue,
              ),
              const SizedBox(width: 8),
              if (_canRequestRefund(order, title))
                const _ActionPill(
                  label: 'Refund Request',
                  icon: Icons.replay_circle_filled_rounded,
                  color: Color(0xFFFF6B6B),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canRequestRefund(Map<String, dynamic> order, String title) {
    if (!title.toLowerCase().contains('mortgage')) return false;
    final status = ((order['status'] as String?) ?? '').toLowerCase();
    if (status != 'paid') return false;
    final createdRaw = order['createdAt'] as String?;
    if (createdRaw == null) return false;
    final createdAt = DateTime.tryParse(createdRaw);
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt).inDays <= 30;
  }

  String _formatDate(String? iso) {
    if (iso == null) return 'Unknown date';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = parsed.toLocal();
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  List<Map<String, dynamic>> get _displayOrders {
    if (_orders.isNotEmpty) {
      return _orders.reversed.toList();
    }
    return [
      {
        'total_amount': 299,
        'status': 'paid',
        'createdAt': DateTime(2026, 3, 15).toIso8601String(),
        'items': [
          {
            'course_id': {'title': 'Real Estate Principles'}
          }
        ],
      },
      {
        'total_amount': 249,
        'status': 'paid',
        'createdAt': DateTime(2026, 2, 28).toIso8601String(),
        'items': [
          {
            'course_id': {'title': 'Mortgage Brokerage Basics'}
          }
        ],
      },
      {
        'total_amount': 199,
        'status': 'paid',
        'createdAt': DateTime(2026, 1, 10).toIso8601String(),
        'items': [
          {
            'course_id': {'title': 'CE Bundle Pack'}
          }
        ],
      },
    ];
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _ActionPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
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