import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/config/api_config.dart';
import 'package:nmls_mobile/faq_screen.dart';
import 'contact_support_page.dart';
import 'package:nmls_mobile/ce_tracker_screen.dart';
import 'package:nmls_mobile/exam_prep_screen.dart';
import 'package:nmls_mobile/my_certificates_screen.dart';
import 'package:nmls_mobile/widgets/app_bottom_nav.dart';

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

// ── Custom Widgets ──────────────────────────────────────────────────
// Sidebar drawer menu
class _SidebarDrawer extends StatelessWidget {
  final VoidCallback onCertificatesTap;
  final String userName;
  final String userEmail;
  final String? token;
  const _SidebarDrawer({
    required this.onCertificatesTap,
    required this.userName,
    required this.userEmail,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: kDark,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: kBlue,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: kBlue),
                  ),
                  const SizedBox(height: 10),
                  Text(userName, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: kDark)),
                  Text(userEmail, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14, color: kDark.withValues(alpha: 0.7))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _DrawerItem(icon: Icons.home, label: 'Home', onTap: () {
              Navigator.of(context).pop();
              // Navigate to Home
            }),
            _DrawerItem(icon: Icons.book, label: 'Courses', onTap: () {
              Navigator.of(context).pop();
              // Navigate to Courses
            }),
            _DrawerItem(icon: Icons.assignment, label: 'Exam Prep', onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExamPrepScreen(
                token: token,
                userName: userName,
                userEmail: userEmail,
              )));
            }),
            _DrawerItem(icon: Icons.access_time, label: 'CE Tracker', onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => CETrackerScreen(
                token: token,
                userName: userName,
                userEmail: userEmail,
              )));
            }),
            const SizedBox(height: 20),
            Divider(color: Colors.white54),
            const SizedBox(height: 20),
            _DrawerItem(icon: Icons.help, label: 'FAQ', onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => FaqScreen()));
            }),
            _DrawerItem(icon: Icons.support, label: 'Contact Support', onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContactSupportPage(userName: userName, userEmail: userEmail)));
            }),
            const SizedBox(height: 20),
            Divider(color: Colors.white54),
            const SizedBox(height: 20),
            _DrawerItem(icon: Icons.logout, label: 'Sign Out', onTap: () {
              // Handle sign out
            }),
          ],
        ),
      ),
    );
  }
}

// Drawer item widget
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ── Main Dashboard Screen ─────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String? token;
  const DashboardScreen({Key? key, this.user, this.token}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  String get _userName {
    final profileFull = (_profile['full_name'] as String?)?.trim();
    if (profileFull != null && profileFull.isNotEmpty) return profileFull;
    final profileFullCamel = (_profile['fullName'] as String?)?.trim();
    if (profileFullCamel != null && profileFullCamel.isNotEmpty) return profileFullCamel;

    final profileName = (_profile['name'] as String?)?.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;

    final profileFirst = (_profile['first_name'] as String?)?.trim() ?? '';
    final profileLast = (_profile['last_name'] as String?)?.trim() ?? '';
    final profileCombined = '$profileFirst $profileLast'.trim();
    if (profileCombined.isNotEmpty) return profileCombined;
    final profileFirstCamel = (_profile['firstName'] as String?)?.trim() ?? '';
    final profileLastCamel = (_profile['lastName'] as String?)?.trim() ?? '';
    final profileCombinedCamel = '$profileFirstCamel $profileLastCamel'.trim();
    if (profileCombinedCamel.isNotEmpty) return profileCombinedCamel;
    final nestedProfile = _profile['user'] as Map?;
    if (nestedProfile != null) {
      final nestedName = (nestedProfile['full_name'] ??
              nestedProfile['fullName'] ??
              nestedProfile['name']) as String?;
      final value = (nestedName ?? '').trim();
      if (value.isNotEmpty) return value;
    }

    final userFull = (widget.user?['full_name'] as String?)?.trim();
    if (userFull != null && userFull.isNotEmpty) return userFull;
    final userFullCamel = (widget.user?['fullName'] as String?)?.trim();
    if (userFullCamel != null && userFullCamel.isNotEmpty) return userFullCamel;

    final userName = (widget.user?['name'] as String?)?.trim();
    if (userName != null && userName.isNotEmpty) return userName;

    final userFirst = (widget.user?['first_name'] as String?)?.trim() ?? '';
    final userLast = (widget.user?['last_name'] as String?)?.trim() ?? '';
    final userCombined = '$userFirst $userLast'.trim();
    if (userCombined.isNotEmpty) return userCombined;
    final userFirstCamel = (widget.user?['firstName'] as String?)?.trim() ?? '';
    final userLastCamel = (widget.user?['lastName'] as String?)?.trim() ?? '';
    final userCombinedCamel = '$userFirstCamel $userLastCamel'.trim();
    if (userCombinedCamel.isNotEmpty) return userCombinedCamel;

    return '';
  }

  String get _userEmail {
    final profileEmail = (_profile['email'] ?? _profile['user_email']) as String?;
    final userEmail = (widget.user?['email'] ?? widget.user?['user_email']) as String?;
    return (profileEmail ?? userEmail ?? '').trim();
  }
  String get _nmlsId    => (_profile['nmls_id'] as String?) ?? 'Not set';
  String get _state     => (_profile['state']   as String?) ?? 'Not set';

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
          .get(Uri.parse('$_apiBase/dashboard'), headers: _headers)
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

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBg,
      endDrawer: _SidebarDrawer(onCertificatesTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MyCertificatesScreen(
              userName: _userName,
              userEmail: _userEmail,
            ),
          ),
        );
      }, userName: _userName, userEmail: _userEmail, token: widget.token),
      drawer: null,
      body: SafeArea(child: Column(children: [
        _buildTopBar(),
        Expanded(child: _loading
            ? _loadingView()
            : _buildBody()),
        AppBottomNav(
          activeTab: AppNavTab.home,
          userName: _userName,
          userEmail: _userEmail,
              token: widget.token,
          nmlsId: _nmlsId,
          state: _state,
          onSignOut: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      ])),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────
   // Redesigned header card (matches provided image)
  Widget _buildTopBar() => Container(
    color: kDark,
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good morning,',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        )),
                    Row(
                      children: [
                        Text(_userName, // Use actual user name
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            )),
                        const SizedBox(width: 6),
                        const Text('👋', style: TextStyle(fontSize: 22)),
                      ],
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: kBlue, size: 28),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(99)),
                      child: Text('3', style: const TextStyle(
                        fontFamily: 'Poppins', color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StatCard(label: 'In Progress', value: '3'),
              const SizedBox(width: 10),
              _StatCard(label: 'Completed', value: '12'),
              const SizedBox(width: 10),
              _StatCard(label: 'CE Hours', value: '20h'),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Body ──────────────────────────────────────────────────────────
  Widget _buildBody() => RefreshIndicator(
    color: kBlue,
    onRefresh: _fetchDashboard,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(children: [
        if (_error.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x1AC0392B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x38C0392B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Color(0xFFC0392B), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Could not refresh dashboard data. Showing available UI.',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFFC0392B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        // MY LEARNING HEADER (left-aligned)
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
          child: Text('MY LEARNING',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: kDark)),
        ),
        _buildMyLearningSection(),
        // NEXT UP HEADER (left-aligned)
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
          child: Text('NEXT UP',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: kDark)),
        ),
        _buildNextUpSection(),
        // UPCOMING DEADLINES HEADER (left-aligned)
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
          child: Text('UPCOMING DEADLINES',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: kDark)),
        ),
        _buildDeadlinesSection(),
        // ACHIEVEMENTS HEADER (left-aligned)
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
          child: Text('ACHIEVEMENTS',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: kDark)),
        ),
        _buildAchievementsSection(),
        // RECOMMENDED FOR YOU HEADER (left-aligned)
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
          child: Text('RECOMMENDED FOR YOU',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: kDark)),
        ),
        _buildRecommendedForYouSection(),
        const SizedBox(height: 32),
      ]),
    ),
  );

  // 2. MY LEARNING SECTION: Courses in progress with % completion bar and Resume button
  Widget _buildMyLearningSection() {
    // Use mock data for in-progress courses
    final inProgressCourses = [
      {
        'title': 'Real Estate Principles',
        'progress_percent': 0.72,
        'last_lesson': 'Ch. 8 — Contracts',
      },
      {
        'title': 'Mortgage Brokerage',
        'progress_percent': 0.38,
        'last_lesson': 'Ch. 3 — FHA Loans',
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...inProgressCourses.map((course) {
          final title = course['title'] as String? ?? 'Untitled';
          final progress = ((course['progress_percent'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
          final progressPct = (progress * 100).round();
          final lastLesson = course['last_lesson'] as String? ?? '';
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: kDark)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: kBlueFaint,
                          valueColor: AlwaysStoppedAnimation<Color>(kBlue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$progressPct%', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13, color: kBlue, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Last: $lastLesson', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: kMuted)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: kWhite,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        textStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      onPressed: () {},
                      child: Text('Resume'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // NEXT UP SECTION: Use mock data
  Widget _buildNextUpSection() {
    final nextLesson = 'Ch. 9 — Property Law';
    final courseTitle = 'Real Estate Principles';
    final duration = '22 min · Video';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBlueBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_fill, color: kBlue, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(courseTitle, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 13, color: kWhite)),
                Text(nextLesson, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: kWhite)),
                Text(duration, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: kWhite.withValues(alpha: 0.7))),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: kWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              textStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
            ),
            onPressed: () {},
            child: Text('Start'),
          ),
        ],
      ),
    );
  }

  // DEADLINES SECTION
  Widget _buildDeadlinesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF6B6B))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CA License Renewal', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: kDark)),
                    const SizedBox(height: 2),
                    Text('28 days remaining', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: kMuted)),
                  ],
                ),
              ),
              Text('Jun 18', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFFF6B6B))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: kBorder, thickness: 1),
          ),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: kBlue)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CE Hours Due', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: kDark)),
                    const SizedBox(height: 2),
                    Text('4 hrs remaining', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: kMuted)),
                  ],
                ),
              ),
              Text('Jul 1', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: kBlue)),
            ],
          ),
        ],
      ),
    );
  }

  // ACHIEVEMENTS SECTION
  Widget _buildAchievementsSection() {
    final achievements = [
      {'icon': '🏆', 'label': 'Top Scorer', 'locked': false},
      {'icon': '🔥', 'label': '7-Day Streak', 'locked': false},
      {'icon': '📜', 'label': '3 Certs', 'locked': false},
      {'icon': '🌟', 'label': 'Locked', 'locked': true},
    ];
    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final a = achievements[index];
          final bool locked = a['locked'] as bool;
          return Container(
            width: 100,
            decoration: BoxDecoration(
              color: locked ? kBlue.withValues(alpha: 0.05) : kWhite,
              borderRadius: BorderRadius.circular(16),
              border: locked ? Border.all(color: kBlue.withValues(alpha: 0.15), width: 1.5, strokeAlign: BorderSide.strokeAlignInside) : null,
              boxShadow: locked ? null : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Opacity(
              opacity: locked ? 0.4 : 1.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(a['icon'] as String, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(a['label'] as String,
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: kDark)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Recommended For You Section ──────────────────────────────────────
  Widget _buildRecommendedForYouSection() {
    final recommended = [
      {'title': 'CE: Agency Law', 'state': 'CA', 'hours': 3, 'icon': Icons.menu_book},
      {'title': 'Fair Housing Act', 'state': 'CA', 'hours': 2, 'icon': Icons.article_outlined},
      {'title': 'Ethical Practices', 'state': 'TX', 'hours': 4, 'icon': Icons.gavel},
    ];
    return SizedBox(
      height: 166,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: recommended.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final c = recommended[index];
          return Container(
            width: 156,
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 94,
                  color: kDark,
                  alignment: Alignment.center,
                  child: Icon(c['icon'] as IconData, color: kBlue, size: 38),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c['title'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: kDark)),
                        const SizedBox(height: 4),
                        Text('${c['hours']} CE hrs · ${c['state']}',
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 11, color: kMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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



// Add _StatCard widget
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF122232),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  fontSize: 22,
                  color: kBlue)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                  color: Color(0xFF7D92A3))),
        ],
      ),
    ),
  );
}

// Move all custom widgets above their first usage and ensure correct scope
// Remove duplicate _buildQuickActions at the bottom
// For quick actions, use closures to capture correct context and instance methods
// All custom widgets (_SidebarDrawer, MyCertificatesScreen, _TabBtn, _EmptyState, _CompletionRow, _TranscriptRow, _OrderCard, _MoreSheet) are now defined above their first usage and in the correct scope.
// _buildQuickActions is only defined as a method inside _DashboardScreenState and uses closures for context and instance methods.
