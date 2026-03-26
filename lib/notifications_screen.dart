import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/config/api_config.dart';
import 'package:nmls_mobile/catalog/token_provider.dart';

const kNtfDark = Color(0xFF091925);
const kNtfBlue = Color(0xFF2EABFE);
const kNtfBg = Color(0xFFF6F7FB);
const kNtfWhite = Colors.white;
const kNtfMuted = Color(0x990B1220);
const kNtfBorder = Color(0x1A020817);

class NotificationsScreen extends StatefulWidget {
  final String? token;
  const NotificationsScreen({super.key, this.token});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String _error = '';
  List<_NotificationItem> _items = <_NotificationItem>[];
  String _filter = 'all';

  Future<Map<String, String>> _buildHeaders() async {
    final token = (widget.token != null && widget.token!.trim().isNotEmpty)
        ? widget.token!.trim()
        : await SharedPreferencesTokenProvider().getToken();

    return <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final headers = await _buildHeaders();
      final res = await http
          .get(Uri.parse(ApiConfig.notifications), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        setState(
          () => _error = 'Failed to load notifications (${res.statusCode})',
        );
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data['notifications'] as List?) ?? const [];
      final parsed = list
          .whereType<Map>()
          .map(
            (entry) =>
                _NotificationItem.fromApi(Map<String, dynamic>.from(entry)),
          )
          .where((n) => n != null)
          .cast<_NotificationItem>()
          .toList();

      setState(() => _items = parsed);
    } catch (_) {
      setState(() => _error = 'Unable to reach notifications service.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_NotificationItem> get _filtered {
    if (_filter == 'all') return _items;
    return _items.where((n) => n.type == _filter).toList();
  }

  String _fmtDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.month}/${d.day}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNtfBg,
      appBar: AppBar(
        backgroundColor: kNtfWhite,
        foregroundColor: kNtfDark,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_off_outlined,
                      color: kNtfDark,
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kNtfDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchNotifications,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: kNtfBlue,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _buildFilterRow(),
                  const SizedBox(height: 10),
                  if (_filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Text(
                        'No notifications for this filter yet.',
                        style: TextStyle(
                          color: kNtfMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    ..._filtered.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: kNtfWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kNtfBorder),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: item.tint.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 18,
                                  color: item.tint,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: kNtfDark,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _fmtDate(item.createdAt),
                                          style: const TextStyle(
                                            color: kNtfMuted,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.message,
                                      style: const TextStyle(
                                        color: kNtfMuted,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterRow() {
    final options = [
      {'key': 'all', 'label': 'All'},
      {'key': 'course_completion_milestone', 'label': 'Milestones'},
      {'key': 'quiz_result', 'label': 'Quiz'},
      {'key': 'ce_renewal_reminder', 'label': 'CE'},
      {'key': 'new_course_state', 'label': 'Courses'},
      {'key': 'promotional_offer', 'label': 'Offers'},
      {'key': 'system_announcement', 'label': 'System'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final key = opt['key']!;
          final selected = _filter == key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(opt['label']!),
              selected: selected,
              onSelected: (_) => setState(() => _filter = key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NotificationItem {
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;

  const _NotificationItem({
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  static _NotificationItem? fromApi(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().trim();
    final title = (data['title'] ?? '').toString().trim();
    final message = (data['message'] ?? '').toString().trim();
    final createdAtRaw = (data['createdAt'] ?? '').toString().trim();
    final createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();

    if (type.isEmpty || title.isEmpty || message.isEmpty) return null;

    return _NotificationItem(
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
    );
  }

  IconData get icon {
    switch (type) {
      case 'course_completion_milestone':
        return Icons.emoji_events_outlined;
      case 'quiz_result':
        return Icons.fact_check_outlined;
      case 'retake_eligibility':
        return Icons.refresh_rounded;
      case 'ce_renewal_reminder':
        return Icons.calendar_month_outlined;
      case 'new_course_state':
        return Icons.new_releases_outlined;
      case 'promotional_offer':
        return Icons.local_offer_outlined;
      case 'system_announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get tint {
    switch (type) {
      case 'course_completion_milestone':
        return const Color(0xFF16A34A);
      case 'quiz_result':
      case 'retake_eligibility':
        return const Color(0xFFF59E0B);
      case 'ce_renewal_reminder':
        return const Color(0xFF0EA5E9);
      case 'new_course_state':
        return const Color(0xFF2563EB);
      case 'promotional_offer':
        return const Color(0xFF7C3AED);
      case 'system_announcement':
        return const Color(0xFF334155);
      default:
        return const Color(0xFF334155);
    }
  }
}
