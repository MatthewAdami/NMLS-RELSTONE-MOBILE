import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/config/api_config.dart';
import 'package:nmls_mobile/courses_screen.dart';
import 'package:nmls_mobile/how_it_works_screen.dart';
import 'package:nmls_mobile/about_relstone_screen.dart';

// ─── Theme ────────────────────────────────────────────────────────────
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
const kBg          = Color(0xFFF6F7FB);
const kWhite       = Colors.white;
const kMuted       = Color(0x990B1220);
const kBorder      = Color(0x1A020817);
const kSurface     = Color(0xD0FFFFFF);

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String? token;
  const DashboardScreen({Key? key, this.user, this.token}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {

  // Tabs: 0=Overview, 1=Transcript, 2=Orders
  int _tab = 0;
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  Map<String, dynamic>? _dashboard;
  bool   _loading = true;
  String _error   = '';

  String get _apiBase => '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}';
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
  };

  // ── Derived getters ───────────────────────────────────────────────
  Map<String, dynamic> get _profile =>
      Map<String, dynamic>.from(_dashboard?['profile'] as Map? ?? {});

  String get _userName  => (_profile['name']    as String?) ?? (widget.user?['name']  as String?) ?? 'Student';
  String get _userEmail => (_profile['email']   as String?) ?? (widget.user?['email'] as String?) ?? '';
  String get _nmlsId    => (_profile['nmls_id'] as String?) ?? 'Not set';
  String get _state     => (_profile['state']   as String?) ?? 'Not set';
  String get _initial   => _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';

  int get _peCount => (_dashboard?['completions']?['PE'] as List?)?.length ?? 0;
  int get _ceCount => (_dashboard?['completions']?['CE'] as List?)?.length ?? 0;

  List<Map<String, dynamic>> get _allCompletions {
    final pe = (_dashboard?['completions']?['PE'] as List?) ?? [];
    final ce = (_dashboard?['completions']?['CE'] as List?) ?? [];
    final all = [...pe, ...ce].map((e) => Map<String, dynamic>.from(e as Map)).toList();
    all.sort((a, b) {
      final da = a['completed_at'] != null ? DateTime.tryParse(a['completed_at'])?.millisecondsSinceEpoch ?? 0 : 0;
      final db = b['completed_at'] != null ? DateTime.tryParse(b['completed_at'])?.millisecondsSinceEpoch ?? 0 : 0;
      return db.compareTo(da);
    });
    return all;
  }

  List<Map<String, dynamic>> get _recentCompletions => _allCompletions.take(5).toList();

  List<Map<String, dynamic>> get _orders {
    final raw = (_dashboard?['orders'] as List?) ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  int get _pendingOrderCount => _orders.where((o) => o['status'] == 'pending').length;

  // ── Lifecycle ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _fetchDashboard();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _fetchDashboard() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await http
          .get(Uri.parse('$_apiBase/data'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        setState(() => _dashboard = Map<String, dynamic>.from(jsonDecode(res.body) as Map));
      } else {
        setState(() => _error = 'Failed to load (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToCourses() => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => CoursesScreen(token: widget.token)),
  );

  void _switchTab(int t) {
    if (t == _tab) return;
    _fadeCtrl.reset();
    setState(() => _tab = t);
    _fadeCtrl.forward();
  }

    void _goToHowItWorks() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HowItWorksScreen()),
    );
    }

  void _goToAboutRelstone() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AboutRelstonePage()),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Column(children: [
        _buildTopBar(),
        Expanded(child: _loading
            ? _loadingView()
            : _error.isNotEmpty
                ? _errorView()
                : _buildBody()),
        _buildBottomNav(),
      ])),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────
  Widget _buildTopBar() => Container(
    decoration: const BoxDecoration(color: kSurface,
        border: Border(bottom: BorderSide(color: kBorder))),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('NMLS Student Portal', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w900, color: kDark, letterSpacing: -0.2)),
        const Text('Your learning status, transcript, and orders', style: TextStyle(
            fontSize: 11, color: kMuted, fontWeight: FontWeight.w700)),
      ]),
      const Spacer(),
      _Avatar(initial: _initial, size: 36),
    ]),
  );

  // ── Body ──────────────────────────────────────────────────────────
  Widget _buildBody() => RefreshIndicator(
    color: kBlue,
    onRefresh: _fetchDashboard,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(children: [
        _buildHero(),
        _buildTabCard(),
      ]),
    ),
  );

  // ── Hero ──────────────────────────────────────────────────────────
  Widget _buildHero() => Container(
    margin: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF091925), Color(0xFF0B2A3A), kBlue],
          stops: [0.0, 0.45, 1.0],
          begin: Alignment.centerLeft, end: Alignment.centerRight),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: kDark.withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 8))],
    ),
    child: Stack(children: [
      Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(22),
          child: CustomPaint(painter: _GlowPainter()))),
      Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Account Snapshot', style: TextStyle(
                color: Color(0xBFFFFFFF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            const Text('Stay on track with your NMLS progress.', style: TextStyle(
                color: kWhite, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
          ])),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _goToCourses,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.menu_book_outlined, color: kWhite, size: 14),
                SizedBox(width: 6),
                Text('Browse courses', style: TextStyle(
                    color: kWhite, fontSize: 12, fontWeight: FontWeight.w900)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, color: kWhite, size: 14),
              ]),
            ),
          ),
        ]),

        const SizedBox(height: 12),

        Wrap(spacing: 8, runSpacing: 8, children: [
          _ProfileChip(icon: Icons.tag, label: 'NMLS ID: $_nmlsId'),
          _ProfileChip(icon: Icons.location_on_outlined, label: 'State: $_state'),
          _ProfileChip(icon: Icons.check_circle_outline, label: 'Total Completions: ${_peCount + _ceCount}'),
        ]),

        const SizedBox(height: 14),

        Row(children: [
          Expanded(child: _KpiCard(icon: Icons.menu_book_outlined, title: 'Pre-Licensing (PE)', value: '$_peCount', caption: 'Completed')),
          const SizedBox(width: 8),
          Expanded(child: _KpiCard(icon: Icons.file_copy_outlined, title: 'Continuing Ed (CE)', value: '$_ceCount', caption: 'Completed', tone: 'teal')),
          const SizedBox(width: 8),
          Expanded(child: _KpiCard(icon: Icons.access_time_outlined, title: 'Pending Orders', value: '$_pendingOrderCount', caption: 'Awaiting', tone: 'amber')),
        ]),
      ])),
    ]),
  );

  // ── Tab Card ──────────────────────────────────────────────────────
  Widget _buildTabCard() => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
    decoration: BoxDecoration(
      color: kWhite,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: kBorder),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8))],
    ),
    child: Column(children: [
      Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Row(children: [
          _TabBtn(label: 'Overview',   active: _tab == 0, onTap: () => _switchTab(0)),
          const SizedBox(width: 8),
          _TabBtn(label: 'Transcript', active: _tab == 1, onTap: () => _switchTab(1)),
          const SizedBox(width: 8),
          _TabBtn(label: 'Orders',     active: _tab == 2, onTap: () => _switchTab(2)),
        ]),
      ),
      FadeTransition(
        opacity: _fadeAnim,
        child: IndexedStack(index: _tab, children: [
          _buildOverviewTab(),
          _buildTranscriptTab(),
          _buildOrdersTab(),
        ]),
      ),
    ]),
  );

  // ── Overview Tab ──────────────────────────────────────────────────
    Widget _buildOverviewTab() => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _PanelHeader(title: 'Recent completions', actionLabel: 'View transcript', onAction: () => _switchTab(1)),
      const SizedBox(height: 10),
      if (_recentCompletions.isEmpty)
        _EmptyState(icon: Icons.workspace_premium_outlined,
          title: 'No completions yet',
          subtitle: 'Once you complete a course, it will show here.',
          actionLabel: 'Browse courses', onAction: _goToCourses)
      else
        ..._recentCompletions.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _CompletionRow(item: c))),
      const SizedBox(height: 18),
      const Text('Quick actions', style: TextStyle(
          fontWeight: FontWeight.w900, color: kDark, fontSize: 14)),
      const SizedBox(height: 10),
      _ActionCard(icon: Icons.menu_book_outlined,    title: 'Browse courses',   subtitle: 'Find PE and CE courses',        onTap: _goToCourses),
      const SizedBox(height: 8),
      _ActionCard(icon: Icons.file_copy_outlined,    title: 'View transcript',  subtitle: 'Download and verify details',   onTap: () => _switchTab(1)),
      const SizedBox(height: 8),
      _ActionCard(icon: Icons.receipt_long_outlined, title: 'Check orders',     subtitle: 'Track payment and status',      onTap: () => _switchTab(2)),
      const SizedBox(height: 8),
      _ActionCard(
        icon: Icons.info_outline,
        title: 'How It Works',
        subtitle: 'See the step-by-step NMLS process',
        onTap: _goToHowItWorks,
      ),
      const SizedBox(height: 8),
      _ActionCard(
        icon: Icons.business_outlined,
        title: 'About Relstone',
        subtitle: 'Learn more about Relstone',
        onTap: _goToAboutRelstone,
      ),
      const SizedBox(height: 8),
      _ActionCard(icon: Icons.person_outline,        title: 'My Profile',       subtitle: 'View account info & sign out',  onTap: () => _showProfileSheet()),
      const SizedBox(height: 8),
    ]),
    );

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(
        userName: _userName, userEmail: _userEmail,
        nmlsId: _nmlsId, state: _state, initial: _initial,
        onSignOut: () { Navigator.of(context).pop(); Navigator.of(context).pop(); },
        onHowItWorks: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => HowItWorksScreen()));
        },
      ),
    );
  }

  // ── Transcript Tab ────────────────────────────────────────────────
  Widget _buildTranscriptTab() => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Transcript', style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w900, color: kDark, letterSpacing: -0.2)),
      const SizedBox(height: 2),
      Text('${_allCompletions.length} course${_allCompletions.length == 1 ? '' : 's'} completed',
          style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      if (_allCompletions.isEmpty)
        _EmptyState(icon: Icons.file_copy_outlined,
          title: 'No completed courses yet',
          subtitle: 'Complete a course to populate your transcript.',
          actionLabel: 'Browse courses', onAction: _goToCourses)
      else
        ..._allCompletions.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _TranscriptRow(item: c))),
    ]),
  );

  // ── Orders Tab ────────────────────────────────────────────────────
  Widget _buildOrdersTab() => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Orders', style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w900, color: kDark, letterSpacing: -0.2)),
      const SizedBox(height: 2),
      const Text('Your purchases and payment status',
          style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      if (_orders.isEmpty)
        _EmptyState(icon: Icons.receipt_long_outlined,
          title: 'No orders yet',
          subtitle: 'When you purchase courses, your orders will show here.',
          actionLabel: 'Browse courses', onAction: _goToCourses)
      else
        ..._orders.reversed.map((order) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OrderCard(order: order))),
    ]),
  );

  // ── Bottom Nav ────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined,      'active': Icons.home_rounded,      'label': 'Overview'},
      {'icon': Icons.menu_book_outlined,  'active': Icons.menu_book_rounded,  'label': 'Courses'},
      {'icon': Icons.file_copy_outlined,  'active': Icons.file_copy_rounded,  'label': 'Transcript'},
      {'icon': Icons.person_outline,     'active': Icons.person_rounded,    'label': 'Profile'},
    ];

    bool isActive(int i) {
      if (i == 0) return _tab == 0;
      if (i == 2) return _tab == 1;
      if (i == 3) return false;
      return false;
    }

    void onNavTap(int i) {
      if (i == 0) { _switchTab(0); return; }
      if (i == 1) { _goToCourses(); return; }
      if (i == 2) { _switchTab(1); return; }
      if (i == 3) { _showProfileSheet(); return; }
    }

    return Container(
      decoration: const BoxDecoration(color: kSurface,
          border: Border(top: BorderSide(color: kBorder))),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: List.generate(items.length, (i) {
        final active = isActive(i);
        return Expanded(child: GestureDetector(
          onTap: () => onNavTap(i),
          behavior: HitTestBehavior.opaque,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: active ? kBlueFaint : Colors.transparent,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(
                active ? items[i]['active'] as IconData : items[i]['icon'] as IconData,
                color: active ? kBlue : const Color(0xFFBBBBBB), size: 20),
            ),
            const SizedBox(height: 3),
            Text(items[i]['label'] as String, style: TextStyle(
                fontSize: 10,
                color: active ? kBlue : const Color(0xFFBBBBBB),
                fontWeight: active ? FontWeight.w900 : FontWeight.w500)),
          ]),
        ));
      })),
    );
  }

  Widget _loadingView() => const Center(child: SizedBox(
    width: 32, height: 32,
    child: CircularProgressIndicator(strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(kBlue)),
  ));

  Widget _errorView() => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 52, height: 52,
          decoration: BoxDecoration(color: const Color(0x1AC0392B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x38C0392B))),
          child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFC0392B), size: 22)),
      const SizedBox(height: 12),
      Text(_error, textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 14)),
      const SizedBox(height: 16),
      GestureDetector(onTap: _fetchDashboard, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(12)),
        child: const Text('Retry',
            style: TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 13)),
      )),
    ]),
  ));
}

// ─── Profile Bottom Sheet ─────────────────────────────────────────────
class _ProfileSheet extends StatelessWidget {
  final String userName, userEmail, nmlsId, state, initial;
  final VoidCallback onSignOut;
  final VoidCallback onHowItWorks;
  const _ProfileSheet({required this.userName, required this.userEmail,
      required this.nmlsId, required this.state, required this.initial,
      required this.onSignOut, required this.onHowItWorks});

  @override
  Widget build(BuildContext context) {
    final fields = [
      {'label': 'Full Name',     'value': userName},
      {'label': 'Email Address', 'value': userEmail.isNotEmpty ? userEmail : '—'},
      {'label': 'NMLS ID',       'value': nmlsId},
      {'label': 'License State', 'value': state},
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(99))),
        const SizedBox(height: 20),
        _Avatar(initial: initial, size: 64),
        const SizedBox(height: 12),
        Text(userName, style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w900, color: kDark, letterSpacing: -0.3)),
        const SizedBox(height: 4),
        Text(userEmail, style: const TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        ...fields.map((f) => Column(children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(f['label']!, style: const TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w700)),
              Text(f['value']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kDark)),
            ])),
          const Divider(color: kBorder, height: 1),
        ])),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity,
          child: OutlinedButton(
            onPressed: onSignOut,
            style: OutlinedButton.styleFrom(foregroundColor: kMuted,
                side: const BorderSide(color: kBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Sign Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity,
          child: OutlinedButton(
            onPressed: onHowItWorks,
            style: OutlinedButton.styleFrom(foregroundColor: kBlue,
                side: const BorderSide(color: kBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('How It Works', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)))),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ─── Completion Row ───────────────────────────────────────────────────
class _CompletionRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CompletionRow({required this.item});

  String _fmt(String? iso) {
    if (iso == null) return '-';
    try { final d = DateTime.parse(iso); return '${d.month}/${d.day}/${d.year}'; }
    catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    final course = item['course'] is Map
        ? Map<String, dynamic>.from(item['course'] as Map)
        : item['course_id'] is Map
            ? Map<String, dynamic>.from(item['course_id'] as Map)
            : <String, dynamic>{};
    final title   = course['title']        as String? ?? 'Course';
    final type    = (course['type']        as String? ?? '').toUpperCase();
    final hrs     = course['credit_hours'] ?? 0;
    final date    = _fmt(item['completed_at'] as String?);
    final certUrl = item['certificate_url'] as String?;
    final isPE    = type == 'PE';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0x050B1220),
          borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(
                fontWeight: FontWeight.w900, color: kDark, fontSize: 13))),
            const SizedBox(width: 8),
            _TypeBadge(type: type, isPE: isPE),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 12, children: [
            _MetaChip(icon: Icons.access_time_outlined, label: '$hrs hrs'),
            _MetaChip(icon: Icons.check_circle_outline, label: date, color: kTeal),
            if (certUrl != null)
              _MetaChip(icon: Icons.workspace_premium_outlined, label: 'Certificate', color: kAmber),
          ]),
        ])),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, size: 18, color: kMuted),
      ]),
    );
  }
}

// ─── Transcript Row ───────────────────────────────────────────────────
class _TranscriptRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _TranscriptRow({required this.item});

  String _fmt(String? iso) {
    if (iso == null) return '-';
    try { final d = DateTime.parse(iso); return '${d.month}/${d.day}/${d.year}'; }
    catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    final course = item['course'] is Map
        ? Map<String, dynamic>.from(item['course'] as Map)
        : item['course_id'] is Map
            ? Map<String, dynamic>.from(item['course_id'] as Map)
            : <String, dynamic>{};
    final title   = course['title']          as String? ?? 'Course';
    final nmlsId  = course['nmls_course_id'] as String? ?? '—';
    final type    = (course['type']          as String? ?? '').toUpperCase();
    final hrs     = course['credit_hours']   ?? 0;
    final date    = _fmt(item['completed_at'] as String?);
    final certUrl = item['certificate_url']  as String?;
    final isPE    = type == 'PE';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kWhite,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: const TextStyle(
              fontWeight: FontWeight.w900, color: kDark, fontSize: 13))),
          _TypeBadge(type: type, isPE: isPE),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 16, runSpacing: 6, children: [
          _MetaChip(icon: Icons.tag, label: nmlsId),
          _MetaChip(icon: Icons.access_time_outlined, label: '$hrs hrs'),
          _MetaChip(icon: Icons.check_circle_outline, label: date, color: kTeal),
          if (certUrl != null)
            _MetaChip(icon: Icons.workspace_premium_outlined, label: 'Certificate', color: kAmber),
        ]),
      ]),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  String _fmtDate(String? iso) {
    if (iso == null) return '-';
    try {
      final d = DateTime.parse(iso).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[d.month-1]} ${d.day}, ${d.year}';
    } catch (_) { return iso; }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'paid': case 'completed': case 'success': return kTeal;
      case 'pending': return kAmber;
      default: return const Color(0xFFC0392B);
    }
  }
  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'paid': case 'completed': case 'success': return kTealFaint;
      case 'pending': return kAmberFaint;
      default: return const Color(0x1AC0392B);
    }
  }
  Color _statusBorder(String s) {
    switch (s.toLowerCase()) {
      case 'paid': case 'completed': case 'success': return kTealBorder;
      case 'pending': return kAmberBorder;
      default: return const Color(0x38C0392B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status  = (order['status']  as String?) ?? 'pending';
    final total   = order['total_amount'] ?? 0;
    final date    = _fmtDate(order['createdAt'] as String?);
    final orderId = (order['_id']     as String?) ?? '';
    final shortId = orderId.length > 6 ? orderId.substring(orderId.length - 6).toUpperCase() : orderId.toUpperCase();
    final items   = (order['items']   as List?) ?? [];

    return Container(
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          const Icon(Icons.receipt_long_outlined, size: 16, color: kDark),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Order #$shortId', style: const TextStyle(
                fontWeight: FontWeight.w900, color: kDark, fontSize: 14)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.access_time_outlined, size: 13, color: kMuted),
              const SizedBox(width: 4),
              Text(date, style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w700)),
            ]),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _statusBg(status),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _statusBorder(status))),
            child: Text(status[0].toUpperCase() + status.substring(1),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                    color: _statusColor(status))),
          ),
        ])),

        if (items.isNotEmpty) ...[
          const Divider(color: kBorder, height: 1),
          ...items.map((item) {
            final courseData = item['course_id'];
            final course = courseData is Map ? Map<String, dynamic>.from(courseData) : <String, dynamic>{};
            final title   = course['title'] as String? ?? 'Course';
            final textbook = item['include_textbook'] == true;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                const Icon(Icons.menu_book_outlined, size: 15, color: kMuted),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: kDark))),
                if (textbook)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0x0A020817),
                        border: Border.all(color: kBorder),
                        borderRadius: BorderRadius.circular(99)),
                    child: const Text('+ Textbook',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kMuted))),
              ]),
            );
          }),
        ],

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
          child: Text('Total:  \$${total is num ? total.toStringAsFixed(2) : total}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: kDark, fontSize: 14)),
        ),
      ]),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final String type; final bool isPE;
  const _TypeBadge({required this.type, required this.isPE});
  @override
  Widget build(BuildContext context) {
    if (type.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPE ? kBlueFaint : kTealFaint,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: isPE ? kBlueBorder : kTealBorder),
      ),
      child: Text(type, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w900, color: isPE ? kBlue : kTeal)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _MetaChip({required this.icon, required this.label, this.color = kMuted});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: color),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
  ]);
}

class _TabBtn extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: active ? kBlueBorder : kBorder),
        boxShadow: active ? [BoxShadow(color: kBlue.withValues(alpha: 0.18), blurRadius: 12, spreadRadius: 2)] : null,
      ),
      child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w900,
          color: active ? kDark : kMuted)),
    ),
  );
}

class _PanelHeader extends StatelessWidget {
  final String title, actionLabel; final VoidCallback onAction;
  const _PanelHeader({required this.title, required this.actionLabel, required this.onAction});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 14)),
    GestureDetector(onTap: onAction,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: const Color(0x05020817),
            border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(actionLabel, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w900, color: kMuted)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: kMuted),
        ]),
      )),
  ]);
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0x050B1220),
          borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(color: kBlueFaint, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBlueBorder)),
            child: Icon(icon, color: kDark, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 13)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w700)),
        ])),
        const Icon(Icons.chevron_right, size: 18, color: kMuted),
      ]),
    ),
  );
}

class _ProfileChip extends StatelessWidget {
  final IconData icon; final String label;
  const _ProfileChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: kBlue, size: 13), const SizedBox(width: 6),
      Text(label, style: const TextStyle(
          color: Color(0xE0FFFFFF), fontSize: 12, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _KpiCard extends StatelessWidget {
  final IconData icon; final String title, value, caption; final String tone;
  const _KpiCard({required this.icon, required this.title, required this.value,
      required this.caption, this.tone = 'blue'});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 34, height: 34,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: kWhite, size: 16)),
      const SizedBox(height: 8),
      Text(title, style: const TextStyle(
          color: Color(0xBFFFFFFF), fontWeight: FontWeight.w800, fontSize: 10),
          maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(
          color: kWhite, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.4)),
      Text(caption, style: const TextStyle(
          color: Color(0xB3FFFFFF), fontWeight: FontWeight.w700, fontSize: 11)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String title, subtitle, actionLabel;
  final VoidCallback onAction;
  const _EmptyState({required this.icon, required this.title,
      required this.subtitle, required this.actionLabel, required this.onAction});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: kBorder),
      color: const Color(0x050B1220),
    ),
    child: Column(children: [
      Container(width: 44, height: 44,
          decoration: BoxDecoration(color: kBlueFaint, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBlueBorder)),
          child: Icon(icon, color: kDark, size: 18)),
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 14)),
      const SizedBox(height: 6),
      Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w700, height: 1.5)),
      const SizedBox(height: 14),
      GestureDetector(onTap: onAction,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(actionLabel, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, color: kDark)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: kDark),
          ]),
        )),
    ]),
  );
}

class _Avatar extends StatelessWidget {
  final String initial; final double size;
  const _Avatar({required this.initial, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kDark, Color(0xFF0B2A3A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        shape: BoxShape.circle),
    child: Center(child: Text(initial, style: const TextStyle(
        color: kBlue, fontWeight: FontWeight.w900, fontSize: 15))),
  );
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()
      ..shader = RadialGradient(center: const Alignment(-0.6, -0.5), radius: 1.2,
          colors: [kBlue.withValues(alpha: 0.18), Colors.transparent])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }
  @override bool shouldRepaint(_) => false;
}


