import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config/api_config.dart';
import 'services/auth_service.dart';

import 'package:http/http.dart' as http;

// ─── Theme Constants (kept consistent with the app ────────────────────────
const kDark = Color(0xFF091925);
const kBlue = Color(0xFF2EABFE);
const kBlueFaint = Color(0x1A2EABFE);
const kBorder = Color(0x1A020817);
const kBg = Color(0xFFF6F7FB);
const kWhite = Colors.white;
const kMuted = Color(0x990B1220);
const kGreen = Color(0xFF22C55E);
const kAmber = Color(0xFFF59E0B);
const kRed = Color(0xFFFF6B6B);
const kSurface = Color(0xD0FFFFFF);

class OrdersScreen extends StatefulWidget {
  final String? token;
  const OrdersScreen({super.key, this.token});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String? _token;
  bool _loading = true;
  String _error = '';
  bool _ordersReloading = false;
  String _ordersError = '';

  // Web spec: orders state starts as []
  final List<Map<String, dynamic>> _orders = [];

  // Filter: all/completed/pending/refunded
  String _filterStatus = 'all';

  // Web spec: payments tab is currently mock UI (local cards only)
  final List<Map<String, dynamic>> _mockCards = [
    {'brand': 'Visa', 'last4': '4242', 'expiry': '08/26', 'isDefault': true},
    {'brand': 'Mastercard', 'last4': '1111', 'expiry': '03/25', 'isDefault': false},
  ];

  late List<Map<String, dynamic>> _cards;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cards = List<Map<String, dynamic>>.from(_mockCards);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final token = widget.token ?? await AuthService.getToken();
      _token = token;

      // Web spec: on mount call API.get('/orders/my')
      await _fetchOrders();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Network error: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchOrders() async {
    final apiBase = '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}';
    final res = await http
        .get(
          Uri.parse('$apiBase/orders/my'),
          headers: {
            'Content-Type': 'application/json',
            if (_token != null) 'Authorization': 'Bearer $_token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Failed to load orders (${res.statusCode})');
    }

    final data = jsonDecode(res.body) as List;
    final normalized = data.map((o) => _normalizeOrder(Map<String, dynamic>.from(o))).toList();
    _orders
      ..clear()
      ..addAll(normalized);
  }

  Future<void> _reloadOrdersFromButton() async {
    setState(() {
      _ordersReloading = true;
      _ordersError = '';
    });

    try {
      await _fetchOrders();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ordersError = 'Failed to reload.';
      });
    } finally {
      if (!mounted) return;
      setState(() => _ordersReloading = false);
    }
  }

  Future<void> _reloadOrdersFromPull() async {
    setState(() => _ordersError = '');
    await _fetchOrders();
    if (!mounted) return;
    setState(() {});
  }

  // Web spec: normalizeOrder(order)
  Map<String, dynamic> _normalizeOrder(Map<String, dynamic> order) {
    final rawItems = (order['items'] as List?) ?? [];
    final items = rawItems
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .map((rawItem) {
      final courseId = rawItem['course_id'];
      final course = courseId is Map<String, dynamic> ? courseId : <String, dynamic>{};

      return <String, dynamic>{
        'course_title': course['title'] ?? 'Course Purchase',
        'type': course['type'] ?? '',
        'hours': course['credit_hours'] ?? 0,
        'price': rawItem['price'] ?? 0,
      };
    }).toList();

    final firstItem = items.isNotEmpty ? items.first as Map<String, dynamic> : <String, dynamic>{};

    final orderId = (order['_id'] ?? order['id'] ?? '').toString();
    final last8 = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;

    // Match web: date = order.createdAt || order.created_at || ''
    final createdAt = (order['createdAt'] ?? order['created_at'])?.toString();
    final date = createdAt ?? '';
    final dateLabel = _formatOrderListDate(date);
    final timeLabel = _formatOrderListTime(date);

    final totalAmount = order['total_amount'] as num? ?? 0;

    final statusRaw = (order['status'] as String?) ?? 'completed';
    final status = statusRaw.toLowerCase();

    // Web spec: refundEligible: order.status === 'pending'
    final refundEligible = status == 'pending';

    return {
      'id': orderId,
      'displayId': 'INV-${last8.toString().toUpperCase()}',
      'createdAt': date,
      'dateLabel': dateLabel,
      'timeLabel': timeLabel,
      'status': status,
      'refundEligible': refundEligible,
      'total_amount': totalAmount,
      'course_title': firstItem['course_title'] ?? 'Course Purchase',
      'type': firstItem['type'] ?? '',
      'hours': firstItem['hours'] ?? 0,
      'items': items,
    };
  }

  String _formatOrderListDate(String createdAtRaw) {
    if (createdAtRaw.trim().isEmpty) return '';
    final dt = DateTime.tryParse(createdAtRaw);
    if (dt == null) return createdAtRaw;
    final localDt = dt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[localDt.month - 1];
    return '$m ${localDt.day}, ${localDt.year}';
  }

  String _formatOrderListTime(String createdAtRaw) {
    if (createdAtRaw.trim().isEmpty) return '';
    final dt = DateTime.tryParse(createdAtRaw);
    if (dt == null) return '';
    final localDt = dt.toLocal();

    final hour24 = localDt.hour;
    final ampm = hour24 < 12 ? 'AM' : 'PM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = localDt.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $ampm';
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_filterStatus == 'all') return _orders;
    return _orders
        .where((o) {
          final status = (o['status'] as String?)?.toLowerCase();
          return status == _filterStatus;
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Orders & Billing',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kBlue,
          labelColor: kBlue,
          unselectedLabelColor: kMuted,
          tabs: const [
            Tab(text: 'Orders'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kRed, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersTab(),
                    _buildPaymentsTab(),
                  ],
                ),
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reloadOrdersFromPull,
            color: kBlue,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                _buildStatsRow(),
                const SizedBox(height: 12),
                _buildFilterRow(),
                const SizedBox(height: 10),
                if (_ordersError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kRed.withOpacity(0.35)),
                      ),
                      child: Text(
                        _ordersError,
                        style: const TextStyle(color: kRed, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                if (_ordersReloading) ...[
                  for (var i = 0; i < 3; i++) ...[
                    Container(
                      height: 92,
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ] else ...[
                  if (_filteredOrders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Text('No orders found for this filter.', textAlign: TextAlign.center),
                    ),
                  for (final order in _filteredOrders) ...[
                    _OrderRow(
                      order: order,
                      onReceipt: () => _downloadReceipt(order),
                      onRefund: () => _openRefundDialog(order),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: _StickyNote(
              icon: Icons.info_outline_rounded,
              title: 'Refund Policy:',
              message:
                  'Refunds are available within 7 days of purchase if the course has not been started. Once any module is accessed, refunds are not available per NMLS provider policy.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    if (_ordersReloading) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final spacing = 12.0;
          final isWide = maxW >= 680;

          Widget skel(double w) => Container(
                width: w,
                height: 86,
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorder),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: kDark.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );

          if (isWide) {
            final cardW = (maxW - (spacing * 3)) / 4;
            return Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  skel(cardW),
                  if (i != 3) SizedBox(width: spacing),
                ],
              ],
            );
          }

          final cardW = (maxW - spacing) / 2;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              skel(cardW),
              skel(cardW),
              skel(cardW),
              skel(cardW),
            ],
          );
        },
      );
    }

    final totalOrders = _orders.length;
    final completedOrders = _orders.where((o) {
      final s = (o['status'] as String?)?.toLowerCase() ?? '';
      return s == 'paid' || s == 'completed';
    }).length;

    final totalSpent = _orders.fold<num>(0, (sum, o) {
      final s = (o['status'] as String?)?.toLowerCase() ?? '';
      if (!(s == 'paid' || s == 'completed')) return sum;
      final amt = o['total_amount'];
      if (amt is num) return sum + amt;
      return sum + (num.tryParse(amt?.toString() ?? '0') ?? 0);
    });

    final savedCards = _cards.length;

    String money(num n) => '\$${n.toStringAsFixed(2)}';

    final cards = <_StatCardData>[
      _StatCardData(icon: Icons.attach_money_rounded, value: money(totalSpent), label: 'Total Spent'),
      _StatCardData(icon: Icons.check_rounded, value: '$completedOrders', label: 'Completed Orders'),
      _StatCardData(icon: Icons.description_outlined, value: '$totalOrders', label: 'Total Orders'),
      _StatCardData(icon: Icons.credit_card_rounded, value: '$savedCards', label: 'Saved Cards'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;

        // Small screens: 2x2 grid (no horizontal scrolling, no clipping).
        // Wider screens: 4 in a row.
        final isWide = maxW >= 680;
        final spacing = 12.0;

        if (isWide) {
          final cardW = (maxW - (spacing * 3)) / 4;
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                _StatCard(
                  icon: cards[i].icon,
                  value: cards[i].value,
                  label: cards[i].label,
                  width: cardW,
                ),
                if (i != cards.length - 1) SizedBox(width: spacing),
              ],
            ],
          );
        }

        final cardW = (maxW - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final c in cards)
              _StatCard(
                icon: c.icon,
                value: c.value,
                label: c.label,
                width: cardW,
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order History',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kDark),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(label: 'all', selected: _filterStatus == 'all', onTap: () => setState(() => _filterStatus = 'all')),
              _FilterChip(label: 'completed', selected: _filterStatus == 'completed', onTap: () => setState(() => _filterStatus = 'completed')),
              _FilterChip(label: 'pending', selected: _filterStatus == 'pending', onTap: () => setState(() => _filterStatus = 'pending')),
              _FilterChip(label: 'refunded', selected: _filterStatus == 'refunded', onTap: () => setState(() => _filterStatus = 'refunded')),
              _RefreshChip(
                loading: _ordersReloading,
                onTap: _ordersReloading ? null : _reloadOrdersFromButton,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _downloadReceipt(Map<String, dynamic> order) async {
    final html = _buildReceiptHtml(order);
    final uri = Uri.dataFromString(html, mimeType: 'text/html', encoding: utf8);
    // This mimics "generate HTML receipt and trigger download" using a data URL.
    // On mobile, browser/OS will handle saving/printing.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _buildReceiptHtml(Map<String, dynamic> order) {
    final displayId = order['displayId']?.toString() ?? '';
    final createdAtRaw = order['createdAt']?.toString() ?? '';
    final dateLabel = _formatReceiptDate(createdAtRaw);
    final timeLabel = _formatReceiptTime(createdAtRaw);
    final status = (order['status'] as String?)?.toString() ?? '';

    final rawItems = (order['items'] as List?) ?? const [];
    final items = rawItems
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final itemRows = () {
      if (items.isEmpty) {
        // Backwards compatibility if older normalized shape exists.
        final courseTitle = (order['course_title']?.toString() ?? '').toUpperCase();
        final type = (order['type']?.toString() ?? '').toUpperCase();
        final hours = order['hours']?.toString() ?? '0';
        final priceNum = order['total_amount'] as num? ?? 0;
        return [
          {
            'course_title': courseTitle,
            'type': type,
            'hours': hours,
            'price': priceNum,
          }
        ];
      }
      return items
          .map((i) => {
                'course_title': (i['course_title']?.toString() ?? '').toUpperCase(),
                'type': (i['type']?.toString() ?? '').toUpperCase(),
                'hours': i['hours']?.toString() ?? '0',
                'price': (() {
                  final rawPrice = i['price'];
                  if (rawPrice is num) return rawPrice;
                  return num.tryParse(rawPrice?.toString() ?? '0') ?? 0;
                })(),
              })
          .toList();
    }();

    final statusLower = status.toLowerCase();
    final receiptStatusKey = switch (statusLower) {
      'completed' => 'paid',
      '' => 'paid',
      _ => statusLower,
    };
    final receiptStatusLabel = receiptStatusKey.isEmpty
        ? 'Paid'
        : receiptStatusKey[0].toUpperCase() + receiptStatusKey.substring(1);

    final totalPaidNum = itemRows.fold<num>(0, (sum, i) {
      final price = i['price'];
      if (price is num) return sum + price;
      return sum;
    });
    final totalPaidFormatted = totalPaidNum.toStringAsFixed(2);

    final itemRowsHtml = itemRows.asMap().entries.map((entry) {
      final item = entry.value;
      final course = item['course_title']?.toString() ?? '';
      final type = item['type']?.toString() ?? '';
      final hours = item['hours']?.toString() ?? '0';
      final priceRaw = item['price'];
      final price = priceRaw is num ? priceRaw : num.tryParse(priceRaw?.toString() ?? '0') ?? 0;
      return '''
        <tr>
          <td class="course">${htmlEscape(course)}</td>
          <td class="typehrs">${htmlEscape(type)}&nbsp;&nbsp;${htmlEscape(hours)}</td>
          <td class="amount">\$${htmlEscape(price.toStringAsFixed(2))}</td>
        </tr>
      ''';
    }).join();

    return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Receipt</title>
  <style>
  @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700;800&display=swap');
  *{margin:0;padding:0;box-sizing:border-box}
  body{font-family:'Poppins',Arial,sans-serif;background:#f4f7fb;padding:18px 12px;color:#091925}
  .card{background:#fff;max-width:620px;margin:0 auto;border-radius:16px;overflow:hidden;box-shadow:0 8px 32px rgba(9,25,37,.1)}
  .hdr{background:#091925;padding:18px 18px;display:flex;justify-content:space-between;align-items:center}
  .brand{font-size:20px;font-weight:800;color:#fff}
  .brand span{color:#2EABFE}
  .receipt-pill{font-size:10.5px;font-weight:900;letter-spacing:.9px;text-transform:uppercase;color:#2EABFE;border:1px solid rgba(46,171,254,.5);padding:6px 12px;border-radius:999px;background:transparent}
  .body{padding:18px 18px}
  h1{font-size:24px;line-height:1.15;font-weight:900;margin:0 0 8px 0;color:#091925}
  .sub{color:#64748b;font-size:12.5px;font-weight:600;margin-bottom:18px}
  .infoRow{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:8px;gap:10px}
  .lbl{font-size:11px;color:#94a3b8;font-weight:800;text-transform:uppercase;letter-spacing:.9px}
  .valBlue{font-size:12px;color:#2EABFE;font-weight:800;text-align:right}
  .timeBlue{font-size:11px;color:#7c8aa3;font-weight:800}
  .divider{height:1px;background:#e2e8f0;margin:14px 0}
  table{width:100%;border-collapse:collapse;table-layout:fixed}
  th{text-align:left;font-size:11px;font-weight:900;text-transform:uppercase;letter-spacing:.8px;color:#94a3b8;padding:10px 0;border-bottom:2px solid #e2e8f0}
  th.thTypeHrs{text-align:center}
  th.thAmount{text-align:right}
  td{padding:10px 0;font-size:12.5px;border-bottom:1px solid #f1f5f9;vertical-align:top}
  .course{text-transform:uppercase;letter-spacing:.2px;color:#0b1523;font-weight:600}
  .typehrs{color:#0b1523;font-weight:500;white-space:nowrap;text-align:center;padding-right:10px}
  .amount{text-align:right;color:#0b1523;font-weight:900;white-space:nowrap;padding-left:10px}
  .badge{display:inline-block;padding:5px 12px;border-radius:999px;font-size:11px;font-weight:900;background:#dcfce7;color:#16a34a}
  .totalRow{display:flex;justify-content:space-between;align-items:center;margin-top:12px}
  .totalLabel{font-size:14px;font-weight:900;color:#0b1523}
  .totalAmount{font-size:16px;font-weight:900;color:#0b1523}
  .foot{background:#f8fafc;padding:14px 18px;text-align:center;font-size:11px;color:#94a3b8;line-height:1.6}
  </style>
</head>
<body>
  <div class="card">
    <div class="hdr">
      <div class="brand">Relstone <span>NMLS</span></div>
      <div class="receipt-pill">RECEIPT</div>
    </div>

    <div class="body">
      <h1>Payment Confirmed</h1>
      <div class="sub">Thank you for your purchase.</div>

      <div class="infoRow">
        <div class="lbl">Order Id</div>
        <div class="valBlue">${htmlEscape(displayId)}</div>
      </div>
      <div class="infoRow">
        <div class="lbl">Date</div>
        <div class="valBlue">
          ${htmlEscape(dateLabel)}
          <br/>
          <span class="timeBlue">${htmlEscape(timeLabel)}</span>
        </div>
      </div>
      <div class="infoRow" style="margin-bottom:6px">
        <div class="lbl">Status</div>
        <div><span class="badge">${htmlEscape(receiptStatusLabel)}</span></div>
      </div>

      <div class="divider"></div>

      <table>
        <colgroup>
          <col style="width:64%" />
          <col style="width:18%" />
          <col style="width:18%" />
        </colgroup>
        <thead>
          <tr>
            <th>COURSE</th>
            <th class="thTypeHrs">TYPEHRS</th>
            <th class="thAmount">AMOUNT</th>
          </tr>
        </thead>
        <tbody>
          $itemRowsHtml
        </tbody>
      </table>

      <div class="totalRow">
        <div class="totalLabel">Total Paid</div>
        <div class="totalAmount">\$${htmlEscape(totalPaidFormatted)}</div>
      </div>
    </div>

    <div class="foot">
      Relstone NMLS Education Platform &middot; NMLS Approved Provider<br/>
      support@relstone.com &middot; Keep this receipt for your records.
    </div>
  </div>
</body>
</html>
''';
  }

  String _formatReceiptDateTime(String createdAtRaw) {
    if (createdAtRaw.trim().isEmpty) return '';
    final dt = DateTime.tryParse(createdAtRaw);
    if (dt == null) return createdAtRaw;
    final localDt = dt.toLocal();

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final monthName = months[localDt.month - 1];
    final day = localDt.day;
    final year = localDt.year;

    final hour24 = localDt.hour;
    final ampm = hour24 < 12 ? 'AM' : 'PM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = localDt.minute.toString().padLeft(2, '0');

    // Example: March 25, 2026 3:45 PM
    return '${monthName} ${day}, ${year} ${hour12}:$minute ${ampm}';
  }

  String _formatReceiptDate(String createdAtRaw) {
    if (createdAtRaw.trim().isEmpty) return '';
    final dt = DateTime.tryParse(createdAtRaw);
    if (dt == null) return createdAtRaw;
    final localDt = dt.toLocal();

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final monthName = months[localDt.month - 1];
    final day = localDt.day;
    final year = localDt.year;
    return '${monthName} ${day}, ${year}';
  }

  String _formatReceiptTime(String createdAtRaw) {
    if (createdAtRaw.trim().isEmpty) return '';
    final dt = DateTime.tryParse(createdAtRaw);
    if (dt == null) return '';
    final localDt = dt.toLocal();

    final hour24 = localDt.hour;
    final ampm = hour24 < 12 ? 'AM' : 'PM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = localDt.minute.toString().padLeft(2, '0');
    return '${hour12}:$minute ${ampm}';
  }

  void _openRefundDialog(Map<String, dynamic> order) async {
    if (!(order['refundEligible'] == true)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request refund'),
        content: const Text('This will mark the order as refunded locally.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Refund')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      final id = order['id'];
      for (final o in _orders) {
        if (o['id'] == id) {
          o['status'] = 'refunded';
          o['refundEligible'] = false;
        }
      }
    });
  }

  Widget _buildPaymentsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              _buildCardSectionTitle(),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 230,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 230 / 162,
                    ),
                    itemCount: _cards.length + 1, // + ghost add tile
                    itemBuilder: (context, index) {
                      if (index == _cards.length) {
                        return _GhostAddCardTile(onTap: _openAddCardModal);
                      }
                      final card = _cards[index];
                      return _PaymentCardTile(
                        card: card,
                        onSetDefault: () => _setDefault(card),
                        onRemove: () => _removeCard(card),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: _StickyNote(
              icon: Icons.shield_outlined,
              title: 'Secure Storage:',
              message: 'Payment info is encrypted via Authorize.Net. Full card numbers are never stored on our servers.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardSectionTitle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: const Text(
        'Payment Methods',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kDark),
      ),
    );
  }

  void _openAddCardModal() async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _AddPaymentCardDialog(),
    ) as Map<String, dynamic>?;

    if (result == null) return;

    setState(() {
      if (result['isDefault'] == true) {
        for (final c in _cards) {
          c['isDefault'] = false;
        }
      }
      _cards = [..._cards, result];
    });
  }

  String _inferBrand(String digits) {
    if (digits.isEmpty) return 'Card';
    final first = digits[0];
    if (first == '4') return 'Visa';
    if (first == '5') return 'Mastercard';
    if (first == '3') return 'AmEx';
    if (first == '6') return 'Discover';
    return 'Card';
  }

  void _setDefault(Map<String, dynamic> card) {
    setState(() {
      final last4 = card['last4']?.toString();
      for (final c in _cards) {
        c['isDefault'] = c['last4']?.toString() == last4;
      }
    });
  }

  void _removeCard(Map<String, dynamic> card) async {
    final last4 = card['last4']?.toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove card'),
        content: const Text('Are you sure you want to remove this card?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _cards = _cards.where((c) => c['last4']?.toString() != last4).toList();
      if (_cards.isEmpty) return;
      // Ensure one default exists
      final hasDefault = _cards.any((c) => c['isDefault'] == true);
      if (!hasDefault) _cards[0]['isDefault'] = true;
    });
  }

  String htmlEscape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
}

class _AddPaymentCardDialog extends StatefulWidget {
  const _AddPaymentCardDialog();

  @override
  State<_AddPaymentCardDialog> createState() => _AddPaymentCardDialogState();
}

class _AddPaymentCardDialogState extends State<_AddPaymentCardDialog> {
  final _number = TextEditingController();
  final _name = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  final Map<String, String> _errors = {};

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  String _fmtNum(String v) {
    final digits = _digitsOnly(v);
    final cut = digits.substring(0, digits.length.clamp(0, 16));
    final buf = StringBuffer();
    for (var i = 0; i < cut.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(cut[i]);
    }
    return buf.toString();
  }

  String _fmtExp(String v) {
    final d = _digitsOnly(v);
    final cut = d.substring(0, d.length.clamp(0, 4));
    if (cut.length <= 2) return cut;
    return '${cut.substring(0, 2)}/${cut.substring(2)}';
  }

  String _fmtCvv(String v) {
    final d = _digitsOnly(v);
    return d.substring(0, d.length.clamp(0, 4));
  }

  bool _validate() {
    final e = <String, String>{};
    final digits = _digitsOnly(_number.text);
    if (digits.length < 16) e['number'] = 'Enter a valid 16-digit card number';
    if (_name.text.trim().isEmpty) e['name'] = 'Cardholder name is required';
    final exp = _expiry.text.trim();
    if (!RegExp(r'^\\d{2}/\\d{2}\$').hasMatch(exp)) e['expiry'] = 'Use MM/YY format';
    if (_fmtCvv(_cvv.text).length < 3) e['cvv'] = 'Enter a valid CVV';

    setState(() {
      _errors
        ..clear()
        ..addAll(e);
    });
    return e.isEmpty;
  }

  String _inferBrand(String digits) {
    if (digits.isEmpty) return 'Visa';
    final first = digits[0];
    if (first == '4') return 'Visa';
    if (first == '5') return 'Mastercard';
    if (first == '3') return 'Amex';
    if (first == '6') return 'Discover';
    return 'Visa';
  }

  void _submit() {
    if (!_validate()) return;
    final digits = _digitsOnly(_number.text);
    final brand = _inferBrand(digits);
    final last4 = digits.substring(digits.length - 4);
    final expiry = _expiry.text.trim();

    Navigator.of(context).pop(<String, dynamic>{
      'brand': brand,
      'last4': last4,
      'expiry': expiry,
      'isDefault': false,
    });
  }

  InputDecoration _dec({
    required String label,
    required String placeholder,
    required String keyName,
  }) {
    final hasErr = _errors.containsKey(keyName);
    return InputDecoration(
      labelText: label,
      hintText: placeholder,
      labelStyle: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: Color(0x8C091925),
        letterSpacing: 0.3,
      ),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 13),
      filled: true,
      fillColor: hasErr ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: hasErr ? const Color(0xFFFCA5A5) : const Color(0x1A091925), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: hasErr ? const Color(0xFFFCA5A5) : kBlue, width: 1.8),
      ),
    );
  }

  Widget _fieldError(String keyName) {
    final msg = _errors[keyName];
    if (msg == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        msg,
        style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxW = w < 460 ? w - 32 : 440.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: maxW,
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40091925),
              blurRadius: 80,
              offset: Offset(0, 32),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Payment Card',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kDark),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Encrypted & secured via Authorize.Net',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.all(Radius.circular(9)),
                      border: Border.fromBorderSide(BorderSide(color: Color(0x1A091925))),
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                const gap = 12.0;

                Widget field({
                  required String keyName,
                  required String label,
                  required String placeholder,
                  required TextEditingController controller,
                  TextInputType? keyboardType,
                  required ValueChanged<String> onChanged,
                }) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        decoration: _dec(label: label, placeholder: placeholder, keyName: keyName),
                        onChanged: onChanged,
                      ),
                      _fieldError(keyName),
                    ],
                  );
                }

                final numberField = field(
                  keyName: 'number',
                  label: 'Card Number',
                  placeholder: '1234 5678 9012 3456',
                  controller: _number,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final f = _fmtNum(v);
                    if (f != v) {
                      _number.value = TextEditingValue(
                        text: f,
                        selection: TextSelection.collapsed(offset: f.length),
                      );
                    }
                    if (_errors.containsKey('number')) setState(() => _errors.remove('number'));
                  },
                );

                final nameField = field(
                  keyName: 'name',
                  label: 'Cardholder Name',
                  placeholder: 'Name on card',
                  controller: _name,
                  onChanged: (_) {
                    if (_errors.containsKey('name')) setState(() => _errors.remove('name'));
                  },
                );

                final expiryField = field(
                  keyName: 'expiry',
                  label: 'Expiry Date',
                  placeholder: 'MM/YY',
                  controller: _expiry,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final f = _fmtExp(v);
                    if (f != v) {
                      _expiry.value = TextEditingValue(
                        text: f,
                        selection: TextSelection.collapsed(offset: f.length),
                      );
                    }
                    if (_errors.containsKey('expiry')) setState(() => _errors.remove('expiry'));
                  },
                );

                final cvvField = field(
                  keyName: 'cvv',
                  label: 'CVV',
                  placeholder: '•••',
                  controller: _cvv,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final f = _fmtCvv(v);
                    if (f != v) {
                      _cvv.value = TextEditingValue(
                        text: f,
                        selection: TextSelection.collapsed(offset: f.length),
                      );
                    }
                    if (_errors.containsKey('cvv')) setState(() => _errors.remove('cvv'));
                  },
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      numberField,
                      const SizedBox(height: gap),
                      nameField,
                      const SizedBox(height: gap),
                      expiryField,
                      const SizedBox(height: gap),
                      cvvField,
                    ],
                  );
                }

                return Column(
                  children: [
                    numberField,
                    const SizedBox(height: gap),
                    nameField,
                    const SizedBox(height: gap),
                    Row(
                      children: [
                        Expanded(child: expiryField),
                        const SizedBox(width: gap),
                        Expanded(child: cvvField),
                      ],
                    ),
                  ],
                );
              },
            ),
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: kBlue.withOpacity(0.05),
                border: Border.all(color: kBlue.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded, size: 16, color: kBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '256-bit SSL encryption. CVV is never stored.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0x1A091925)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDark,
                        foregroundColor: kWhite,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        elevation: 0,
                      ),
                      child: const Text('Add Card'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final double? width;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 156,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A091925),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kBlueFaint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBlue.withOpacity(0.18)),
            ),
            child: Icon(icon, color: kBlue, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: kDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final IconData icon;
  final String value;
  final String label;

  const _StatCardData({
    required this.icon,
    required this.value,
    required this.label,
  });
}

class _OrderRow extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onReceipt;
  final VoidCallback onRefund;

  const _OrderRow({
    required this.order,
    required this.onReceipt,
    required this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] as String?)?.toString() ?? '';
    final total = order['total_amount'] as num? ?? 0;
    final refundEligible = order['refundEligible'] == true;
    final items = (order['items'] as List?) ?? const [];
    final itemCount = items.length;
    final extraCount = itemCount > 1 ? itemCount - 1 : 0;
    final dateLabel = order['dateLabel']?.toString() ?? '';
    final timeLabel = order['timeLabel']?.toString() ?? '';
    final type = (order['type']?.toString() ?? '').toUpperCase();
    final hours = order['hours']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['displayId']?.toString() ?? '',
                      style: const TextStyle(color: kBlue, fontWeight: FontWeight.w900, fontSize: 12.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateLabel.isNotEmpty) ...[
                      const SizedBox(height: 8), // space under invoice (not too dikit)
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              dateLabel,
                              style: const TextStyle(color: kMuted, fontWeight: FontWeight.w700, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeLabel.isNotEmpty)
                            const SizedBox(width: 8),
                          if (timeLabel.isNotEmpty)
                            Text(
                              timeLabel,
                              style: const TextStyle(color: kMuted, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ] else
                      const SizedBox(height: 8),
                    Text(
                      order['course_title']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kDark),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '$itemCount ${itemCount == 1 ? 'course' : 'courses'}',
                          style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                        if (type.isNotEmpty || hours.isNotEmpty) ...[
                          const Text(' · ', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700, fontSize: 12)),
                          Text(
                            type,
                            style: const TextStyle(color: kMuted, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                          if (hours.isNotEmpty)
                            Text(
                              '  $hours hrs',
                              style: const TextStyle(color: kMuted, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                        ],
                        if (extraCount > 0)
                          Text(
                            '  +$extraCount more',
                            style: const TextStyle(color: kBlue, fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '\$${total.toStringAsFixed(total is int ? 0 : 2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kDark),
              ),
              const Spacer(),
              _ReceiptActionPill(label: 'Receipt', onTap: onReceipt),
              const SizedBox(width: 8),
              if (refundEligible) _RefundActionPill(label: 'Refund', onTap: onRefund),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptActionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ReceiptActionPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: kBlueFaint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBlue.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_rounded, size: 14, color: kBlue),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: kBlue, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _RefundActionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RefundActionPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: kRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kRed.withOpacity(0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.replay_circle_filled_rounded, size: 14, color: kRed),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: kRed, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  Color _bg() {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return kGreen.withOpacity(0.12);
      case 'pending':
        return kAmber.withOpacity(0.12);
      case 'refunded':
        return kRed.withOpacity(0.12);
      default:
        return kBlueFaint;
    }
  }

  Color _border() {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return kGreen.withOpacity(0.65);
      case 'pending':
        return kAmber.withOpacity(0.75);
      case 'refunded':
        return kRed.withOpacity(0.7);
      default:
        return kBlue.withOpacity(0.45);
    }
  }

  Color _text() {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return kGreen;
      case 'pending':
        return kAmber;
      case 'refunded':
        return kRed;
      default:
        return kBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final label = lower.isEmpty
        ? 'unknown'
        : switch (lower) {
            'completed' => 'Completed',
            'paid' => 'Paid',
            'pending' => 'Pending',
            'refunded' => 'Refunded',
            'cancelled' => 'Cancelled',
            _ => lower[0].toUpperCase() + lower.substring(1),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border()),
      ),
      child: Text(
        label,
        style: TextStyle(color: _text(), fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kBlueFaint : kWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? kBlue.withOpacity(0.55) : kBorder),
        ),
        child: Text(
          label[0].toUpperCase() + label.substring(1),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: selected ? kBlue : kMuted,
          ),
        ),
      ),
    );
  }
}

class _RefreshChip extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;

  const _RefreshChip({
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final border = disabled ? kBorder : kBorder;
    final fg = disabled ? kMuted.withOpacity(0.55) : kMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.refresh_rounded, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              'Refresh',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyNote extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StickyNote({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: kBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBlue.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: kBlue),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  TextSpan(text: message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCardRow extends StatelessWidget {
  final Map<String, dynamic> card;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  const _PaymentCardRow({
    required this.card,
    required this.onSetDefault,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final brand = card['brand']?.toString() ?? 'Card';
    final last4 = card['last4']?.toString() ?? '';
    final expiry = card['expiry']?.toString() ?? '';
    final isDefault = card['isDefault'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kBlueFaint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBlue.withOpacity(0.35)),
                ),
                child: const Icon(Icons.credit_card_rounded, color: kBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$brand •••• $last4',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Exp $expiry',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted),
                    ),
                  ],
                ),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: kGreen.withOpacity(0.65)),
                  ),
                  child: const Text('Default', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: kGreen)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isDefault)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSetDefault,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kBlue,
                      side: const BorderSide(color: kBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Set Default'),
                  ),
                ),
              if (!isDefault) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onRemove,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kRed,
                    side: const BorderSide(color: kRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Remove'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentCardTile extends StatefulWidget {
  final Map<String, dynamic> card;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  const _PaymentCardTile({
    required this.card,
    required this.onSetDefault,
    required this.onRemove,
  });

  @override
  State<_PaymentCardTile> createState() => _PaymentCardTileState();
}

class _PaymentCardTileState extends State<_PaymentCardTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final brand = widget.card['brand']?.toString() ?? 'Visa';
    final last4 = widget.card['last4']?.toString() ?? '';
    final expiry = widget.card['expiry']?.toString() ?? '';
    final isDefault = widget.card['isDefault'] == true;

    final borderColor = isDefault ? kBlue : Colors.white.withOpacity(0.05);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: _hover ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2B3D), kDark],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: _hover
              ? const [
                  BoxShadow(
                    color: Color(0x38091925),
                    blurRadius: 36,
                    offset: Offset(0, 14),
                  )
                ]
              : const [],
        ),
        child: Stack(
          children: [
            // subtle overlay highlight like ::before
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kBlue.withOpacity(0.07),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.55],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        brand,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      const Spacer(),
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: kBlue.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: kBlue.withOpacity(0.35)),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF60C3FF),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '••••  ••••  ••••  $last4',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2.5,
                      fontFamily: 'Courier New',
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXP',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withOpacity(0.35),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            expiry,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _PCardButton(
                            label: 'Default',
                            icon: Icons.check_rounded,
                            onTap: widget.onSetDefault,
                          ),
                          const SizedBox(width: 6),
                          _PCardButton(
                            label: '',
                            icon: Icons.delete_outline_rounded,
                            danger: true,
                            onTap: widget.onRemove,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PCardButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _PCardButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  State<_PCardButton> createState() => _PCardButtonState();
}

class _PCardButtonState extends State<_PCardButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final baseBg = Colors.white.withOpacity(_hover ? 0.2 : 0.1);
    final baseBorder = Colors.white.withOpacity(0.15);
    final baseFg = widget.danger ? const Color(0xCCFCA5A5) : Colors.white.withOpacity(_hover ? 1 : 0.75);

    final bg = widget.danger ? ( _hover ? const Color(0x38EF4444) : Colors.white.withOpacity(0.1)) : baseBg;
    final border = widget.danger ? const Color(0x2FFCA5A5) : baseBorder;
    final fg = widget.danger ? ( _hover ? const Color(0xFFFCA5A5) : baseFg) : baseFg;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: widget.label.isEmpty ? 8 : 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: fg),
              if (widget.label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostAddCardTile extends StatefulWidget {
  final VoidCallback onTap;
  const _GhostAddCardTile({required this.onTap});

  @override
  State<_GhostAddCardTile> createState() => _GhostAddCardTileState();
}

class _GhostAddCardTileState extends State<_GhostAddCardTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final border = _hover ? kBlue : const Color(0x1F091925); // light gray normal, blue hovered
    final bg = _hover ? kBlue.withOpacity(0.02) : Colors.transparent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBlue.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.add_rounded, color: kBlue),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Add Card',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: kDark),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Visa - Mastercard - Amex',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

