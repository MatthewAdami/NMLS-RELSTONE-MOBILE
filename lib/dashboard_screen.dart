import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/config/api_config.dart';
import 'package:nmls_mobile/contact_support_page.dart';
import 'package:nmls_mobile/courses_screen.dart';
import 'package:nmls_mobile/my_certificates_screen.dart';
import 'package:nmls_mobile/my_courses_screen.dart';
import 'package:nmls_mobile/orders_screen.dart';
import 'package:nmls_mobile/profile_screen.dart' hide AppTopBar, AppSidebar;
import 'package:nmls_mobile/widgets/app_side_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme ────────────────────────────────────────────────────────────
const kDark       = Color(0xFF091925);
const kBlue       = Color(0xFF2EABFE);
const kBlueFaint  = Color(0x1A2EABFE);
const kAmber      = Color(0xFFF59E0B);
const kGreen      = Color(0xFF008000);
const kBg         = Color(0xFFF6F7FB);
const kWhite      = Colors.white;
const kMuted      = Color(0xFF7FA8C4);
const kBorder     = Color(0x12020817);

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String? token; // kept for compatibility — token is loaded from SharedPreferences internally
  const DashboardScreen({Key? key, this.user, this.token}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── State ─────────────────────────────────────────────────────────
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _transcript;
  List<Map<String, dynamic>> _certificates = [];

  bool   _loading = true;
  String _error   = '';
  String? _token;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Derived: mirrors web dashboard ────────────────────────────────
  Map<String, dynamic> get _profile =>
      Map<String, dynamic>.from(_dashboard?['profile'] as Map? ?? {});

  String get _userName {
    final n = (_profile['name'] as String?)?.trim();
    if (n != null && n.isNotEmpty) return n;
    return (widget.user?['name'] as String?)?.trim() ?? 'Student';
  }

  String get _userEmail =>
      ((_profile['email'] ?? widget.user?['email']) as String?)?.trim() ?? '';

  String get _nmlsId => (_profile['nmls_id'] as String?) ?? '—';
  String get _state  => (_profile['state']   as String?) ?? '—';

  List<Map<String, dynamic>> get _availableCourses {
    final raw = (_dashboard?['available_courses'] as List?) ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  int get _inProgressCount =>
      _availableCourses.where((c) => c['already_completed'] != true).length;

  List<Map<String, dynamic>> get _recentCompletions {
    final pe  = (_dashboard?['completions']?['PE'] as List?) ?? [];
    final ce  = (_dashboard?['completions']?['CE'] as List?) ?? [];
    final all = [...pe, ...ce]
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    all.sort((a, b) {
      final da = DateTime.tryParse(a['completed_at'] ?? '')?.millisecondsSinceEpoch ?? 0;
      final db = DateTime.tryParse(b['completed_at'] ?? '')?.millisecondsSinceEpoch ?? 0;
      return db.compareTo(da);
    });
    return all.take(5).toList();
  }

  List<Map<String, dynamic>> get _orders {
    final raw = (_dashboard?['orders'] as List?) ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Map<String, dynamic>? get _ceTracker =>
      _dashboard?['ce_tracker'] as Map<String, dynamic>?;

  // ── Headers ───────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Lifecycle ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    await _fetchAll();
  }

  // ── Fetch — mirrors web: Promise.all([dashboard, transcript, certificates])
  Future<void> _fetchAll() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final results = await Future.wait([
        _get('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/dashboard'),
        _get('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/dashboard/transcript'),
        _get('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/certificates'),
      ]);

      // ── Dashboard
      if (results[0]['statusCode'] == 200) {
        _dashboard = Map<String, dynamic>.from(results[0]['data'] as Map);
      }

      // ── Transcript
      if (results[1]['statusCode'] == 200) {
        _transcript = Map<String, dynamic>.from(results[1]['data'] as Map);
      }

      // ── Certificates — mirrors web: certsRes.data?.certificates || []
      if (results[2]['statusCode'] == 200) {
        final raw = (results[2]['data']?['certificates'] as List?) ?? [];
        _certificates = raw.map((c) {
          final m = Map<String, dynamic>.from(c as Map);
          return {
            '_id':             m['_id'],
            'course_title':    m['course_title']    ?? '—',
            'course_type':     m['course_type']     ?? '—',
            'credit_hours':    m['credit_hours'],
            'nmls_course_id':  m['nmls_course_id']  ?? '—',
            'completed_at':    m['completed_at'],
            'certificate_url': m['certificate_url'],
          };
        }).toList();
      }

      if (_dashboard == null) {
        setState(() => _error = 'Failed to load dashboard');
      }
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>> _get(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));
      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        data = {'message': res.body};
      }
      return {'statusCode': res.statusCode, 'data': data};
    } catch (e) {
      return {'statusCode': 0, 'data': {'message': '$e'}};
    }
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBg,
      appBar: AppTopBar(
        scaffoldKey: _scaffoldKey,
        userName: _userName,
        nmlsId: _nmlsId != '—' ? _nmlsId : null,
      ),
      drawer: AppSidebar(
        userName: _userName,
        userEmail: _userEmail,
        nmlsId: _nmlsId != '—' ? _nmlsId : null,
        currentRoute: '/dashboard',
        onNavigate: (route) {
          Navigator.of(context).pop(); // close drawer
          switch (route) {
            case '/my-courses':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyCoursesScreen()),
              ).then((_) => mounted ? setState(() {}) : null);
              break;
            case '/courses':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoursesScreen(
                    token: _token,
                    userName: _userName,
                    userEmail: _userEmail,
                  ),
                ),
              ).then((_) => mounted ? setState(() {}) : null);
              break;
             
            case '/orders':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrdersScreen(token: _token)),
              ).then((_) => mounted ? setState(() {}) : null);
              break;
            case '/certificates':
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MyCertificatesScreen(
                    user: {
                      'name': widget.user?['name'] ?? '',
                      'email': widget.user?['email'] ?? '',
                      'state': widget.user?['state'] ?? '',
                    },
                  ),
                ),
              );
              break;
            case '/profile':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    userName: _userName,
                    userEmail: _userEmail,
                    nmlsId: _nmlsId != '—' ? _nmlsId : '',
                  ),
                ),
              ).then((_) => mounted ? setState(() {}) : null);
              break;
              case '/support':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContactSupportPage(
                    userName: _userName,
                    userEmail: _userEmail,
                    // nmlsId:    _nmlsId,
                  ),
                ),
              ).then((_) => mounted ? setState(() {}) : null);
            case '/dashboard':
              break;
            default:
              break;
          }
        },
        
        onSignOut: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : RefreshIndicator(
              color: kBlue,
              onRefresh: _fetchAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error.isNotEmpty) _buildErrorBanner(),
                    _buildStatCards(),
                    const SizedBox(height: 16),
                    _buildSectionLabel('MY COURSES'),
                    _buildCourses(),
                    const SizedBox(height: 16),
                    _buildSectionLabel('RECENT COMPLETIONS'),
                    _buildRecentCompletions(),
                    const SizedBox(height: 16),
                    _buildSectionLabel('CE TRACKER'),
                    _buildCeTracker(),
                    const SizedBox(height: 16),
                    _buildSectionLabel('CERTIFICATES'),
                    _buildCertificates(),
                    const SizedBox(height: 16),
                    _buildSectionLabel('ORDERS'),
                    _buildOrders(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Error banner ──────────────────────────────────────────────────
  Widget _buildErrorBanner() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0x1AC0392B),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0x38C0392B)),
    ),
    child: Text(_error,
        style: const TextStyle(
            fontFamily: 'Poppins', fontSize: 12, color: Color(0xFFC0392B))),
  );

  // ── Stat Cards — mirrors web: Enrolled / Certificates / In Progress / StudentID
  Widget _buildStatCards() => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.6,
    children: [
      _StatCard(label: 'Courses Enrolled', value: '${_availableCourses.length}', color: kBlue),
      _StatCard(label: 'Certificates', value: '${_certificates.length}', color: kGreen),
      _StatCard(label: 'In Progress', value: '$_inProgressCount', color: kAmber),
      _StatCard(label: 'Student ID', value: _nmlsId != '—' ? '#NM-$_nmlsId' : '—', color: const Color(0xFF9569F7)),
    ],
  );

  // ── Courses — mirrors web CourseRow ───────────────────────────────
  Widget _buildCourses() {
    if (_availableCourses.isEmpty) return _emptyMsg('No courses enrolled yet.');
    return Column(
      children: _availableCourses.take(5).map((c) {
        final title    = (c['title'] as String?) ?? 'Untitled';
        final progress = ((c['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 100.0);
        final isDone   = c['already_completed'] == true;
        final color    = isDone ? kGreen : progress > 0 ? kAmber : kBlue;
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: kDark)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: isDone ? 1.0 : progress / 100,
                      minHeight: 6,
                      backgroundColor: kBlueFaint,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isDone ? '100%' : '${progress.round()}%',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ]),
              const SizedBox(height: 6),
              _statusBadge(isDone ? 'Complete' : progress > 0 ? 'In Progress' : 'Not Started', color),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Recent Completions — mirrors web CompletionRow ────────────────
  Widget _buildRecentCompletions() {
    if (_recentCompletions.isEmpty) return _emptyMsg('Complete a course to see your record here.');
    return Column(
      children: _recentCompletions.map((item) {
        final title = (item['course']?['title'] ?? item['course_id']?['title'] ?? '—') as String;
        final type  = (item['course']?['type']  ?? item['course_id']?['type']  ?? '') as String;
        final hrs   = item['course']?['credit_hours'] ?? item['course_id']?['credit_hours'] ?? '—';
        final date  = item['completed_at'] != null
            ? DateTime.tryParse(item['completed_at'])?.toLocal().toString().split(' ')[0] ?? '—'
            : '—';
        return _card(
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: kDark)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _typeBadge(type),
                    const SizedBox(width: 8),
                    Text('$hrs hrs · $date',
                        style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 11, color: kMuted)),
                  ]),
                ],
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  // ── CE Tracker — mirrors web CE Tracker panel ─────────────────────
  Widget _buildCeTracker() {
    final ce = _ceTracker;
    if (ce == null) return _emptyMsg('Complete a CE course to begin tracking.');
    final required  = (ce['required_hours']  as num?)?.toInt() ?? 8;
    final completed = (ce['completed_hours'] as num?)?.toInt() ?? 0;
    final deadline  = ce['deadline'] as String? ?? '—';
    final daysLeft  = ce['days_left'] as int?;
    final subjects  = (ce['subjects'] as List?) ?? [];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Annual CE Tracker',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: kDark)),
                  Text('Deadline: $deadline',
                      style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 11, color: kMuted)),
                ],
              ),
            ),
            if (daysLeft != null) Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: kBlue.withOpacity(0.4)),
              ),
              child: Text('$daysLeft days left',
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 10,
                      fontWeight: FontWeight.w700, color: kBlue)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            '$completed / $required hrs completed',
            style: const TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: kDark),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: required > 0 ? (completed / required).clamp(0.0, 1.0) : 0,
              minHeight: 8,
              backgroundColor: kBlueFaint,
              valueColor: const AlwaysStoppedAnimation<Color>(kBlue),
            ),
          ),
          if (subjects.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...subjects.map((row) {
              final m     = Map<String, dynamic>.from(row as Map);
              final label = m['label'] as String? ?? '';
              final tot   = (m['total'] as num?)?.toInt() ?? 0;
              final comp  = (m['completed'] as num?)?.toInt() ?? 0;
              final pct   = tot > 0 ? comp / tot : 0.0;
              final color = pct == 1.0 ? kGreen : pct > 0 ? kAmber : Colors.red;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(label,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: kDark))),
                      Text('$comp/$tot',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: pct.toDouble(),
                        minHeight: 5,
                        backgroundColor: Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  // ── Certificates ──────────────────────────────────────────────────
  Widget _buildCertificates() {
    if (_certificates.isEmpty) return _emptyMsg('No certificates yet.');
    return Column(
      children: _certificates.take(3).map((c) {
        final title = c['course_title'] as String? ?? '—';
        final date  = c['completed_at'] != null
            ? DateTime.tryParse(c['completed_at'])?.toLocal().toString().split(' ')[0] ?? '—'
            : '—';
        final type  = c['course_type'] as String? ?? '';
        return _card(
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: kGreen.withOpacity(0.3)),
              ),
              child: const Icon(Icons.workspace_premium, color: kGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: kDark)),
                  const SizedBox(height: 3),
                  Row(children: [
                    _typeBadge(type),
                    const SizedBox(width: 8),
                    Text('Issued $date',
                        style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 11, color: kMuted)),
                  ]),
                ],
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  // ── Orders ────────────────────────────────────────────────────────
  Widget _buildOrders() {
    if (_orders.isEmpty) return _emptyMsg('No orders yet.');
    return Column(
      children: _orders.take(3).map((order) {
        final id     = (order['_id'] as String? ?? '').characters.toList().reversed.take(6).toList().reversed.join().toUpperCase();
        final status = (order['status'] as String? ?? '').toLowerCase();
        final total  = (order['total_amount'] as num?)?.toDouble() ?? 0;
        final items  = (order['items'] as List?) ?? [];
        final statusColor = status == 'paid' || status == 'completed'
            ? kGreen : status == 'pending' ? kAmber : Colors.red;
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text('Order #$id',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: kDark)),
                ),
                _statusBadge(order['status'] ?? '—', statusColor),
              ]),
              const SizedBox(height: 8),
              ...items.map((item) {
                final m     = Map<String, dynamic>.from(item as Map);
                final title = m['course_id']?['title'] as String? ?? 'Course';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const Icon(Icons.book_outlined, size: 14, color: kBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 12, color: kDark)),
                    ),
                  ]),
                );
              }).toList(),
              const Divider(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: \$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: kDark),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label,
        style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: kDark,
            letterSpacing: 0.5)),
  );

  Widget _card({required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: child,
  );

  Widget _emptyMsg(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Center(
      child: Text(msg,
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 12, color: kMuted)),
    ),
  );

  Widget _typeBadge(String type) {
    final t = type.toUpperCase();
    final color = t == 'PE' ? kBlue : t == 'CE' ? const Color(0xFF008C8C) : kMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(t.isEmpty ? '—' : t,
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color)),
    );
  }

  Widget _statusBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label,
        style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color)),
  );
}

// ── Stat Card ──────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kWhite,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
      border: Border(bottom: BorderSide(color: color, width: 3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: kMuted)),
      ],
    ),
  );
}