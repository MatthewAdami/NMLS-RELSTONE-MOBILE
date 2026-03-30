import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/courses_screen.dart';
import 'package:nmls_mobile/orders_screen.dart';
import 'package:nmls_mobile/widgets/app_side_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/api_config.dart';
import 'course_portal_screen.dart';

// ─── Theme ────────────────────────────────────────────────────────────
const _kDark    = Color(0xFF091925);
const _kBlue    = Color(0xFF2EABFE);
const _kTeal    = Color(0xFF00B4B4);
const _kAmber   = Color(0xFFF59E0B);
const _kGreen   = Color(0xFF22C55E);
const _kBg      = Color(0xFFF0F4F8);
const _kWhite   = Colors.white;
const _kMuted   = Color(0xFF7FA8C4);
const _kBorder  = Color(0x14020817);

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({Key? key}) : super(key: key);

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  // ── State ─────────────────────────────────────────────────────────
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _transcript;
  List<Map<String, dynamic>> _myReviews = [];

  bool   _loading    = true;
  String _error      = '';
  String? _token;
  String _userName   = '';
  String _userEmail  = '';
  String _nmlsId     = '';
  String _activeTab  = 'inprogress';
  String _search     = '';
  String _stateFilter = 'all';
  String _typeFilter  = 'all';
  bool   _showFilters = false;

  final _searchCtrl  = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Derived — mirrors web useMemo ─────────────────────────────────
  List<Map<String, dynamic>> get _available =>
      ((_dashboard?['available_courses'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  List<Map<String, dynamic>> get _orders =>
      ((_dashboard?['orders'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  List<Map<String, dynamic>> get _transcriptRows =>
      ((_transcript?['transcript'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  // Completed — from transcript (mirrors web)
  List<Map<String, dynamic>> get _completed {
    return _transcriptRows.map((t) {
      final courseObj = t['course_id'] is Map
          ? Map<String, dynamic>.from(t['course_id'] as Map)
          : <String, dynamic>{};
      final courseId = courseObj['_id'] ?? t['_id'];
      return {
        'id':           courseId,
        'title':        t['course_title'] ?? courseObj['title'] ?? '—',
        'type':         t['type']         ?? courseObj['type'],
        'credit_hours': t['credit_hours'] ?? courseObj['credit_hours'],
        'nmls_id':      t['nmls_course_id'],
        'completed_at': t['completed_at'],
        'certificate_course_id': courseObj['_id'] ?? courseId,
        'state':        t['state'] ?? 'Federal',
        'progress':     100,
        'status':       'completed',
      };
    }).toList();
  }

  // In-progress — from available_courses (mirrors web)
  List<Map<String, dynamic>> get _inProgress {
    return _available.where((c) => c['already_completed'] != true).map((c) {
      return {
        'id':             c['course_id'],
        'title':          c['title'],
        'type':           c['type'],
        'credit_hours':   c['credit_hours'],
        'state':          c['state'] ?? 'Federal',
        'progress':       (c['progress'] as num?)?.toInt() ?? 0,
        'completedSteps': (c['completed_steps'] as num?)?.toInt() ?? 0,
        'totalSteps':     (c['total_steps'] as num?)?.toInt() ?? 0,
        'status':         'inprogress',
      };
    }).toList();
  }

  List<String> get _allStates {
    final s = {..._completed.map((c) => c['state'] as String? ?? ''), ..._inProgress.map((c) => c['state'] as String? ?? '')};
    return s.where((x) => x.isNotEmpty).toList();
  }

  List<String> get _allTypes {
    final t = {..._completed.map((c) => (c['type'] as String? ?? '').toUpperCase()), ..._inProgress.map((c) => (c['type'] as String? ?? '').toUpperCase())};
    return t.where((x) => x.isNotEmpty).toList();
  }

  List<Map<String, dynamic>> get _currentList {
    final list = _activeTab == 'inprogress' ? _inProgress : _activeTab == 'completed' ? _completed : <Map<String, dynamic>>[];
    return list.where((c) {
      final matchState  = _stateFilter == 'all' || c['state'] == _stateFilter;
      final matchType   = _typeFilter == 'all' || (c['type'] as String? ?? '').toUpperCase() == _typeFilter.toUpperCase();
      final matchSearch = _search.trim().isEmpty ||
          (c['title'] as String? ?? '').toLowerCase().contains(_search.toLowerCase()) ||
          (c['type']  as String? ?? '').toLowerCase().contains(_search.toLowerCase());
      return matchState && matchType && matchSearch;
    }).toList();
  }

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    // ── Load stored user for sidebar/topbar consistency ──
    final userStr = prefs.getString('user');
    if (userStr != null) {
      try {
        final user = jsonDecode(userStr) as Map<String, dynamic>;
        _userName  = (user['name']    as String?) ?? '';
        _userEmail = (user['email']   as String?) ?? '';
        _nmlsId    = (user['nmls_id'] as String?) ?? '';
      } catch (_) {}
    }
    await _fetchAll();
  }

  // ── Fetch — mirrors web Promise.all ───────────────────────────────
  Future<void> _fetchAll() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final results = await Future.wait([
        _get('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/dashboard'),
        _get('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/dashboard/transcript'),
        _get('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/testimonials/mine'),
      ]);

      if (results[0]['statusCode'] == 200) {
        _dashboard = Map<String, dynamic>.from(results[0]['data'] as Map);
      }
      if (results[1]['statusCode'] == 200) {
        _transcript = Map<String, dynamic>.from(results[1]['data'] as Map);
      }
      if (results[2]['statusCode'] == 200) {
        final raw = (results[2]['data']?['testimonials'] as List?) ?? [];
        _myReviews = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      if (_dashboard == null) setState(() => _error = 'Failed to load courses');
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>> _get(String url) async {
    try {
      final res = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));
      Map<String, dynamic> data;
      try { data = jsonDecode(res.body) as Map<String, dynamic>; }
      catch (_) { data = {'message': res.body}; }
      return {'statusCode': res.statusCode, 'data': data};
    } catch (e) {
      return {'statusCode': 0, 'data': {'message': '$e'}};
    }
  }

  bool _hasReviewed(String? courseId) =>
      _myReviews.any((r) => r['course_id']?.toString() == courseId?.toString());

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBg,
      appBar: AppTopBar(
        scaffoldKey: _scaffoldKey,
        userName: _userName,
        nmlsId: _nmlsId.isNotEmpty ? _nmlsId : null,
      ),
      drawer: AppSidebar(
        userName: _userName,
        userEmail: _userEmail,
        nmlsId: _nmlsId.isNotEmpty ? _nmlsId : null,
        currentRoute: '/my-courses',
        onNavigate: (route) {
  Navigator.of(context).pop(); // close drawer
  if (route == '/dashboard') {
    Navigator.of(context).pop();
  } else if (route == '/courses') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CoursesScreen(
        userName: _userName,
        userEmail: _userEmail,
        nmlsId: _nmlsId.isNotEmpty ? _nmlsId : null,
      )),
    );
    } else if (route == '/orders') {   // 👈 ADD THIS
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => OrdersScreen(
      token: _token,
    )),
  );

  }
},
        
        onSignOut: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false),
        
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kBlue))
          : RefreshIndicator(
              color: _kBlue,
              onRefresh: _fetchAll,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildPageHeader()),
                  SliverToBoxAdapter(child: _buildToolbar()),
                  if (_showFilters) SliverToBoxAdapter(child: _buildFilterPanel()),
                  if (_error.isNotEmpty) SliverToBoxAdapter(child: _buildErrorBanner()),
                  if (_activeTab == 'completed' && _completed.isNotEmpty)
                    SliverToBoxAdapter(child: _buildInfoBanner()),
                  if (_currentList.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                            final course = _currentList[i];
                            return _CourseCard(
                            course: course,
                            hasReviewed: _hasReviewed(course['id']?.toString()),
                            onResume: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CoursePortalScreen(
                                  courseId: course['id']?.toString() ?? '',
                                ),
                              ),
                            ),
                            onViewCertificate: () {},
                            onLeaveReview: () {},
                          );},
                          childCount: _currentList.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // ── Page Header ───────────────────────────────────────────────────
  Widget _buildPageHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MY LEARNING',
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w800,
                    color: _kBlue, letterSpacing: 0.8)),
            const Text('My Courses',
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w900,
                    color: _kDark, letterSpacing: -0.4)),
          ],
        ),
        _outlineBtn(
          label: 'Browse',
          icon: Icons.menu_book_outlined,
          onTap: () {},
        ),
      ],
    ),
  );

  // ── Toolbar: Tabs + Search + Filter ───────────────────────────────
  Widget _buildToolbar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Column(
      children: [
        // Tabs
        Row(
          children: [
            _TabChip(label: 'In Progress', count: _inProgress.length,  active: _activeTab == 'inprogress', onTap: () => setState(() => _activeTab = 'inprogress')),
            const SizedBox(width: 8),
            _TabChip(label: 'Completed',   count: _completed.length,   active: _activeTab == 'completed',  onTap: () => setState(() => _activeTab = 'completed')),
            const SizedBox(width: 8),
            _TabChip(label: 'Wishlist',    count: 0,                   active: _activeTab == 'wishlist',   onTap: () => setState(() => _activeTab = 'wishlist')),
          ],
        ),
        const SizedBox(height: 10),
        // Search + Filter row
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, size: 16, color: Color(0x72091925)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: _kDark),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search courses…',
                          hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0x72091925)),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _showFilters = !_showFilters),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _showFilters ? _kBlue.withOpacity(0.06) : _kWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _showFilters ? _kBlue.withOpacity(0.4) : _kBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: _showFilters ? _kBlue : _kDark.withOpacity(0.65)),
                    const SizedBox(width: 6),
                    Text('Filters',
                        style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800,
                            color: _showFilters ? _kBlue : _kDark.withOpacity(0.65))),
                    if (_stateFilter != 'all' || _typeFilter != 'all') ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    ),
  );

  // ── Filter Panel ──────────────────────────────────────────────────
  Widget _buildFilterPanel() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kBlue.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kBlue.withOpacity(0.18)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // State filter
        const Text('STATE', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0x80091925), letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: [
            _FilterChip(label: 'All States', active: _stateFilter == 'all', onTap: () => setState(() => _stateFilter = 'all')),
            ..._allStates.map((s) => _FilterChip(label: s, active: _stateFilter == s, onTap: () => setState(() => _stateFilter = s))),
          ],
        ),
        const SizedBox(height: 14),
        // Type filter
        const Text('COURSE TYPE', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0x80091925), letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: [
            _FilterChip(label: 'All Types', active: _typeFilter == 'all', onTap: () => setState(() => _typeFilter = 'all')),
            ..._allTypes.map((t) => _FilterChip(label: t, active: _typeFilter == t, onTap: () => setState(() => _typeFilter = t))),
          ],
        ),
        if (_stateFilter != 'all' || _typeFilter != 'all') ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() { _stateFilter = 'all'; _typeFilter = 'all'; }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: const Text('Clear all filters',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB41E1E))),
            ),
          ),
        ],
      ],
    ),
  );

  // ── Info Banner ───────────────────────────────────────────────────
  Widget _buildInfoBanner() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _kAmber.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kAmber.withOpacity(0.25)),
    ),
    child: Row(
      children: [
        const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF925400)),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF925400)),
              children: [
                TextSpan(text: 'Tap '),
                TextSpan(text: 'Review Course', style: TextStyle(fontWeight: FontWeight.w900)),
                TextSpan(text: ' on any completed course to revisit content and quiz answers.'),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ── Error Banner ──────────────────────────────────────────────────
  Widget _buildErrorBanner() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0x1AC0392B),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0x38C0392B)),
    ),
    child: Text(_error, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFFC0392B))),
  );

  // ── Empty State ───────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final configs = {
      'inprogress': ('📚', 'No courses in progress',   'Enroll in a course to start learning.'),
      'completed':  ('🏆', 'No completed courses yet', 'Finish a course to earn your certificate.'),
      'wishlist':   ('❤️', 'Your wishlist is empty',    'Save courses you\'re interested in.'),
    };
    final c = configs[_activeTab]!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.$1, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 14),
            Text(c.$2, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900, fontSize: 17, color: _kDark)),
            const SizedBox(height: 6),
            Text(c.$3, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _kMuted, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            _outlineBtn(label: 'Browse Courses', icon: Icons.chevron_right, onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _outlineBtn({required String label, required IconData icon, required VoidCallback onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _kDark.withOpacity(0.75)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: _kDark.withOpacity(0.75))),
          ],
        ),
      ),
    );
}

// ─── Course Card ──────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool hasReviewed;
  final VoidCallback onResume;
  final VoidCallback onViewCertificate;
  final VoidCallback onLeaveReview;

  const _CourseCard({
    required this.course,
    required this.hasReviewed,
    required this.onResume,
    required this.onViewCertificate,
    required this.onLeaveReview,
  });

  bool get _isCompleted  => course['status'] == 'completed';
  int  get _progress     => (course['progress'] as num?)?.toInt() ?? 0;
  String get _type       => (course['type'] as String? ?? '').toUpperCase();
  String get _state      => course['state'] as String? ?? '';
  String? get _completedAt => course['completed_at'] as String?;

  Color get _accentColor => _type == 'PE' ? _kBlue : _type == 'CE' ? _kTeal : _kAmber;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14020817)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Colored top accent bar ──
          Container(height: 4, color: _accentColor),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card header: icon + badges ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: _kDark.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kDark.withOpacity(0.07)),
                      ),
                      child: Icon(
                        _isCompleted ? Icons.workspace_premium : Icons.menu_book_outlined,
                        size: 20,
                        color: _isCompleted ? _kAmber : _kBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 6, runSpacing: 4,
                        alignment: WrapAlignment.end,
                        children: [
                          _typeBadge(_type),
                          if (_state.isNotEmpty && _state != 'Federal')
                            _stateBadge(_state),
                          if (_isCompleted)
                            _completedBadge(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Title ──
                Text(
                  course['title'] as String? ?? '—',
                  style: const TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w900,
                    fontSize: 14, color: _kDark, height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Meta row ──
                Row(
                  children: [
                    const Icon(Icons.schedule_outlined, size: 12, color: Color(0x80091925)),
                    const SizedBox(width: 4),
                    Text(
                      '${course['credit_hours'] ?? '—'} hrs',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0x80091925)),
                    ),
                    if (course['nmls_id'] != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        'NMLS #${course['nmls_id']}',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0x80091925)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // ── Progress bar (in-progress only) ──
                if (!_isCompleted) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PROGRESS', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800, color: Color(0x80091925), letterSpacing: 0.5)),
                      Text('$_progress%', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w900, color: _kBlue)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _progress / 100,
                      minHeight: 6,
                      backgroundColor: const Color(0x12020817),
                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                    ),
                  ),
                  if (course['completedSteps'] != null && course['totalSteps'] != null && (course['totalSteps'] as int) > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${course['completedSteps']} / ${course['totalSteps']} steps',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0x6A091925)),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],

                // ── Completed date row ──
                if (_isCompleted && _completedAt != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: _kGreen.withOpacity(0.22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF15803D)),
                        const SizedBox(width: 6),
                        Text(
                          'Completed · ${_formatDate(_completedAt!)}',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Action buttons ──
                if (_isCompleted) ...[
                  Row(
                    children: [
                      Expanded(child: _actionBtn(label: 'Certificate', icon: Icons.workspace_premium, color: _kAmber, bgColor: _kAmber.withOpacity(0.10), borderColor: _kAmber.withOpacity(0.4), onTap: onViewCertificate)),
                      const SizedBox(width: 8),
                      Expanded(child: _actionBtn(label: 'Review', icon: Icons.visibility_outlined, color: _kBlue, bgColor: _kBlue.withOpacity(0.08), borderColor: _kBlue.withOpacity(0.3), onTap: onResume)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!hasReviewed)
                    _fullWidthBtn(label: 'Leave a Review', icon: Icons.chat_bubble_outline_rounded, color: const Color(0xFF925400), bgColor: _kAmber.withOpacity(0.08), borderColor: _kAmber.withOpacity(0.3), onTap: onLeaveReview)
                  else
                    _fullWidthBtn(label: 'Review Submitted', icon: Icons.check_circle_rounded, color: const Color(0xFF15803D), bgColor: _kGreen.withOpacity(0.06), borderColor: _kGreen.withOpacity(0.22), onTap: () {}),
                ] else ...[
                  _fullWidthBtn(
                    label: _progress > 0 ? 'Resume Learning' : 'Start Learning',
                    icon: _progress > 0 ? Icons.play_circle_filled : Icons.play_arrow_rounded,
                    color: _kWhite,
                    bgColor: _kDark,
                    borderColor: _kDark,
                    onTap: onResume,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) { return iso; }
  }

  Widget _typeBadge(String type) {
    Color color;
    if (type == 'PE') color = _kBlue;
    else if (type == 'CE') color = _kTeal;
    else color = _kMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(type.isEmpty ? '—' : type,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _stateBadge(String state) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _kDark.withOpacity(0.05),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: _kDark.withOpacity(0.10)),
    ),
    child: Text(state, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xA5091925))),
  );

  Widget _completedBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _kGreen.withOpacity(0.10),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: _kGreen.withOpacity(0.25)),
    ),
    child: const Text('✓ Completed', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
  );

  Widget _actionBtn({required String label, required IconData icon, required Color color, required Color bgColor, required Color borderColor, required VoidCallback onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(11), border: Border.all(color: borderColor)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );

  Widget _fullWidthBtn({required String label, required IconData icon, required Color color, required Color bgColor, required Color borderColor, required VoidCallback onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(11), border: Border.all(color: borderColor)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
}

// ─── Tab Chip ─────────────────────────────────────────────────────
class _TabChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.count, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? _kDark : _kWhite,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: active ? _kDark : const Color(0x1A020817)),
        boxShadow: active ? [BoxShadow(color: _kDark.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 4))] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800,
                  color: active ? _kWhite : _kDark.withOpacity(0.60))),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: active ? _kWhite.withOpacity(0.18) : _kDark.withOpacity(0.08),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text('$count',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w900,
                    color: active ? _kWhite : _kDark.withOpacity(0.55))),
          ),
        ],
      ),
    ),
  );
}

// ─── Filter Chip ──────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? _kDark : _kWhite,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: active ? _kDark : const Color(0x1A020817)),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700,
              color: active ? _kWhite : _kDark.withOpacity(0.65))),
    ),
  );
}