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
import 'package:nmls_mobile/services/auth_service.dart';
import 'package:nmls_mobile/login_screen.dart';
import 'package:nmls_mobile/catalog/course_portal_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  const _SidebarDrawer({required this.onCertificatesTap, required this.userName, required this.userEmail});

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
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExamPrepScreen(userName: userName, userEmail: userEmail)));
            }),
            _DrawerItem(icon: Icons.access_time, label: 'CE Tracker', onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => CETrackerScreen(userName: userName, userEmail: userEmail)));
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
              Navigator.of(context).pop(); // close drawer
              final nav = Navigator.of(context);
              AuthService.logout().then((_) {
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              });
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

  Future<Map<String, String>> _requestHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    var token = widget.token?.trim() ?? '';
    if (token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = (prefs.getString('token') ?? '').trim();
    }
    if (token.isNotEmpty) {
      headers['Authorization'] =
          token.toLowerCase().startsWith('bearer ') ? token : 'Bearer $token';
    }
    return headers;
  }

  num _num(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim()) ?? 0;
    return 0;
  }

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

  List<Map<String, dynamic>> get _availableCourses => _firstListFromKeys([
        'available_courses',
        'availableCourses',
        'available',
        'courses',
        'data',
      ]);

  List<Map<String, dynamic>> _mapListFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> _firstListFromKeys(List<String> keys) {
    for (final key in keys) {
      final items = _mapListFrom(_dashboard?[key]);
      if (items.isNotEmpty) return items;
    }
    return const [];
  }

  int get _completedCount {
    final stats = Map<String, dynamic>.from(_dashboard?['stats'] as Map? ?? {});
    final fromStats = stats['completed'] ?? stats['completed_count'];
    if (fromStats is num) return fromStats.toInt();
    if (_allCompletions.isNotEmpty) return _allCompletions.length;
    int count = 0;
    for (final c in _availableCourses) {
      final progressRaw = c['progress_percent'] ??
          c['progressPercent'] ??
          c['progress'] ??
          c['percent_complete'];
      var progress = _num(progressRaw).toDouble();
      if (progress > 1) progress = progress / 100.0;
      final done = (c['is_completed'] == true) ||
          (c['isCompleted'] == true) ||
          (c['completed'] == true) ||
          progress >= 1.0;
      if (done) count += 1;
    }
    return count;
  }

  int get _inProgressCount {
    final stats = Map<String, dynamic>.from(_dashboard?['stats'] as Map? ?? {});
    final fromStats = stats['in_progress'] ?? stats['in_progress_count'];
    if (fromStats is num) return fromStats.toInt();
    int count = 0;
    for (final c in _availableCourses) {
      final progressRaw = c['progress_percent'] ??
          c['progressPercent'] ??
          c['progress'] ??
          c['percent_complete'];
      var progress = _num(progressRaw).toDouble();
      if (progress > 1) progress = progress / 100.0;
      final done = (c['is_completed'] == true) ||
          (c['isCompleted'] == true) ||
          (c['completed'] == true) ||
          progress >= 1.0;
      if (!done && progress > 0) count += 1;
    }
    if (count > 0) return count;
    final learning = _myLearningItems;
    return learning.isNotEmpty ? learning.length : _orders.length;
  }

  String get _ceHoursLabel {
    bool isCe(Map<String, dynamic> item) {
      final t = (item['type'] ?? item['course_type'] ?? '').toString().trim().toUpperCase();
      return t == 'CE' || t.contains('CONTINUING');
    }

    bool isCompleted(Map<String, dynamic> item) {
      final progressRaw = item['progress_percent'] ??
          item['progressPercent'] ??
          item['progress'] ??
          item['percent_complete'] ??
          0;
      var progress = _num(progressRaw).toDouble();
      if (progress > 1) progress = progress / 100.0;
      return item['is_completed'] == true ||
          item['isCompleted'] == true ||
          item['completed'] == true ||
          progress >= 1.0;
    }

    // Primary: sum completed CE entries from completions map/list.
    final ceCompletions = <Map<String, dynamic>>[];
    final completionsRaw = _dashboard?['completions'];
    if (completionsRaw is Map) {
      ceCompletions.addAll(
        _mapListFrom(completionsRaw['CE'] ?? completionsRaw['ce']),
      );
      // Some APIs keep mixed entries under "all".
      ceCompletions.addAll(
        _mapListFrom(completionsRaw['all']).where(isCe),
      );
    } else if (completionsRaw is List) {
      ceCompletions.addAll(
        _mapListFrom(completionsRaw).where(isCe),
      );
    }

    double hours = 0;
    for (final c in ceCompletions) {
      final h = c['credit_hours'] ??
          c['creditHours'] ??
          c['hours'] ??
          c['duration_hours'] ??
          c['durationHours'];
      hours += _num(h).toDouble();
    }
    if (hours > 0) {
      return hours % 1 == 0 ? '${hours.toInt()}h' : '${hours.toStringAsFixed(1)}h';
    }

    // Fallback 1: CE hours already computed by backend in stats.
    final stats = Map<String, dynamic>.from(_dashboard?['stats'] as Map? ?? {});
    final ceStatRaw = stats['ce_hours'] ??
        stats['ceHours'] ??
        stats['ce_hours_completed'] ??
        stats['ceHoursCompleted'];
    final ceStat = _num(ceStatRaw).toDouble();
    if (ceStat > 0) {
      return ceStat % 1 == 0 ? '${ceStat.toInt()}h' : '${ceStat.toStringAsFixed(1)}h';
    }

    // Fallback 2: derive from available completed CE courses.
    for (final c in _availableCourses) {
      if (!isCe(c) || !isCompleted(c)) continue;
      final h = c['credit_hours'] ??
          c['creditHours'] ??
          c['hours'] ??
          c['duration_hours'] ??
          c['durationHours'];
      hours += _num(h).toDouble();
    }
    if (hours > 0) {
      return hours % 1 == 0 ? '${hours.toInt()}h' : '${hours.toStringAsFixed(1)}h';
    }

    return '0h';
  }

  List<Map<String, dynamic>> get _myLearningItems => _firstListFromKeys([
        'in_progress',
        'inProgress',
        'my_learning',
        'myLearning',
        'courses_in_progress',
      ]);

  List<Map<String, dynamic>> get _nextUpItems =>
      _firstListFromKeys(['next_up', 'nextUp']);

  List<Map<String, dynamic>> get _deadlineItems => _firstListFromKeys([
        'deadlines',
        'upcoming_deadlines',
        'upcomingDeadlines',
      ]);

  List<Map<String, dynamic>> get _achievementItems =>
      _firstListFromKeys(['achievements']);

  List<Map<String, dynamic>> get _recommendedItems => _firstListFromKeys([
        'recommended',
        'recommended_for_you',
        'recommendedForYou',
      ]);

  List<Map<String, dynamic>> get _inProgressCoursesForDashboard {
    final fromDashboard = _myLearningItems;
    if (fromDashboard.isNotEmpty) return fromDashboard;
    return _availableCourses.where((c) {
      final progressRaw = c['progress_percent'] ??
          c['progressPercent'] ??
          c['progress'] ??
          c['percent_complete'];
      var progress = _num(progressRaw).toDouble();
      if (progress > 1) progress = progress / 100.0;
      final done = (c['is_completed'] == true) ||
          (c['isCompleted'] == true) ||
          (c['completed'] == true) ||
          progress >= 1.0;
      return !done && progress > 0;
    }).toList();
  }

  String _courseIdFrom(Map<String, dynamic> course) {
    return (course['id'] ??
            course['_id'] ??
            course['course_id'] ??
            course['courseId'] ??
            course['nmls_course_id'] ??
            course['nmlsCourseId'] ??
            '')
        .toString();
  }

  double _courseProgress01(Map<String, dynamic> course) {
    final raw = course['progress_percent'] ??
        course['progressPercent'] ??
        course['progress'] ??
        course['completion_percent'] ??
        course['percent_complete'] ??
        0;
    var value = _num(raw).toDouble();
    if (value > 1) value = value / 100.0;
    return value.clamp(0.0, 1.0);
  }

  String _nextLessonLabelFrom(Map<String, dynamic> item) {
    final direct = (item['next_lesson'] ??
            item['next_lesson_title'] ??
            item['nextLesson'] ??
            item['nextLessonTitle'] ??
            item['current_lesson'] ??
            item['currentLesson'] ??
            item['current_lesson_title'] ??
            item['currentLessonTitle'] ??
            item['lesson_name'] ??
            item['lessonName'] ??
            item['lesson'] ??
            item['last_lesson'] ??
            item['lastLesson'])
        ?.toString()
        .trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final currentModule = item['current_module'] ?? item['currentModule'];
    if (currentModule is Map) {
      final moduleMap = Map<String, dynamic>.from(currentModule);
      final moduleTitle = (moduleMap['title'] ??
              moduleMap['name'] ??
              moduleMap['module_title'] ??
              moduleMap['moduleTitle'])
          ?.toString()
          .trim();
      if (moduleTitle != null && moduleTitle.isNotEmpty) return moduleTitle;
    }

    final modules = _mapListFrom(item['modules']);
    if (modules.isNotEmpty) {
      int moduleNum(Map<String, dynamic> m) {
        return _num(m['order'] ?? m['module_order'] ?? m['idx']).toInt();
      }

      String moduleTitle(Map<String, dynamic> m) {
        return (m['title'] ?? m['name'] ?? m['module_title'] ?? m['moduleTitle'] ?? '')
            .toString()
            .trim();
      }

      final moduleOrder = _num(item['module_order'] ?? item['moduleOrder']).toInt();
      if (moduleOrder > 0) {
        for (final m in modules) {
          if (moduleNum(m) == moduleOrder) {
            final t = moduleTitle(m);
            if (t.isNotEmpty) return t;
          }
        }
      }

      final currentIdx = _num(item['current_idx'] ?? item['currentIdx']).toInt();
      if (currentIdx >= 0 && currentIdx < modules.length) {
        final t = moduleTitle(modules[currentIdx]);
        if (t.isNotEmpty) return t;
      }

      final progress = _courseProgress01(item);
      final inferred = (progress * modules.length).floor().clamp(0, modules.length - 1);
      final inferredTitle = moduleTitle(modules[inferred]);
      if (inferredTitle.isNotEmpty) return inferredTitle;
    }

    final currentIdxRaw = item['current_idx'] ?? item['currentIdx'];
    final moduleOrderRaw = item['module_order'] ?? item['moduleOrder'];
    final totalStepsRaw = item['total_steps'] ?? item['totalSteps'];

    final currentIdx = _num(currentIdxRaw).toInt();
    final moduleOrder = _num(moduleOrderRaw).toInt();
    final totalSteps = _num(totalStepsRaw).toInt();

    // Preferred fallback: module order if backend exposes it.
    if (moduleOrder > 0) return 'Module $moduleOrder';

    // Next fallback: infer step number from current index.
    if (currentIdx > 0) return 'Lesson ${currentIdx + 1}';

    // Last fallback: infer from progress and total steps.
    final progress = _courseProgress01(item);
    if (totalSteps > 0) {
      final inferred = ((progress * totalSteps).floor() + 1).clamp(1, totalSteps);
      return 'Lesson $inferred';
    }

    return 'Continue current lesson';
  }

  Future<void> _openCourseFromDashboard(Map<String, dynamic> course) async {
    final courseId = _courseIdFrom(course);
    if (courseId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course id missing; cannot open course.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CoursePortalScreen(courseId: courseId)),
    );
    if (!mounted) return;
    await _fetchDashboard();
  }

  Map<String, dynamic> _normalizeDashboardPayload(Map<String, dynamic> raw) {
    final nested = raw['data'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return raw;
  }

  bool _hasDashboardData(Map<String, dynamic> data) {
    const keys = <String>{
      'profile',
      'stats',
      'completions',
      'available_courses',
      'availableCourses',
      'in_progress',
      'my_learning',
      'orders',
    };
    for (final key in keys) {
      if (data.containsKey(key)) return true;
    }
    return false;
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
      final headers = await _requestHeaders();
      final resDashboard = await http
          .get(Uri.parse('$_apiBase/dashboard'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (resDashboard.statusCode == 200) {
        final parsed = _normalizeDashboardPayload(
          Map<String, dynamic>.from(jsonDecode(resDashboard.body) as Map),
        );
        if (_hasDashboardData(parsed) || _dashboard == null) {
          setState(() => _dashboard = parsed);
        }
      } else {
        final resData = await http
            .get(Uri.parse('$_apiBase/data'), headers: headers)
            .timeout(const Duration(seconds: 10));
        if (resData.statusCode == 200) {
          final parsed = _normalizeDashboardPayload(
            Map<String, dynamic>.from(jsonDecode(resData.body) as Map),
          );
          if (_hasDashboardData(parsed) || _dashboard == null) {
            setState(() => _dashboard = parsed);
          }
        } else {
          if (_dashboard == null) {
            setState(() => _error = 'Failed to load (${resData.statusCode})');
          }
        }
      }
    } catch (e) {
      if (_dashboard == null) {
        setState(() => _error = 'Network error: $e');
      }
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
      }, userName: _userName, userEmail: _userEmail),
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
              _StatCard(label: 'In Progress', value: '$_inProgressCount'),
              const SizedBox(width: 10),
              _StatCard(label: 'Completed', value: '$_completedCount'),
              const SizedBox(width: 10),
              _StatCard(label: 'CE Hours', value: _ceHoursLabel),
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
    final inProgressCourses = _inProgressCoursesForDashboard;
    if (inProgressCourses.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Text(
          'No courses in progress yet.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: kMuted,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...inProgressCourses.map((course) {
          final title = (course['title'] ?? course['course_title'] ?? 'Untitled').toString();
          final normalized = _courseProgress01(course);
          final progressPct = (normalized * 100).round();
          final lastLesson = (course['last_lesson'] ?? course['lastLesson'] ?? '').toString();
          final isStart = normalized <= 0.001;
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
                          value: normalized,
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
                      onPressed: () => _openCourseFromDashboard(course),
                      child: Text(isStart ? 'Start' : 'Resume'),
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
    final fallbackInProgress = _inProgressCoursesForDashboard.isNotEmpty
        ? _inProgressCoursesForDashboard.first
        : const <String, dynamic>{};
    final item = _nextUpItems.isNotEmpty ? _nextUpItems.first : fallbackInProgress;
    final courseTitle = (item['course_title'] ??
            item['courseTitle'] ??
            item['course_name'] ??
            item['courseName'] ??
            item['course'] ??
            item['title'] ??
            'Up next')
        .toString();
    final nextLesson = _nextLessonLabelFrom(item);
    final duration = (item['duration'] ?? item['meta'] ?? '').toString();
    final isStart = _courseProgress01(item) <= 0.001;
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
                Text(
                  duration.isEmpty ? 'No duration' : duration,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: kWhite.withValues(alpha: 0.7)),
                ),
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
            onPressed: item.isEmpty ? null : () => _openCourseFromDashboard(item),
            child: Text(isStart ? 'Start' : 'Resume'),
          ),
        ],
      ),
    );
  }

  // DEADLINES SECTION
  Widget _buildDeadlinesSection() {
    final deadlines = _deadlineItems;
    if (deadlines.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Text(
          'No upcoming deadlines.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: kMuted),
        ),
      );
    }
    final first = deadlines.first;
    final second = deadlines.length > 1 ? deadlines[1] : null;
    Widget rowFrom(Map<String, dynamic> d, {required Color dotColor, required Color dateColor}) {
      final title = (d['title'] ?? d['name'] ?? 'Deadline').toString();
      final subtitle = (d['subtitle'] ?? d['remaining'] ?? '').toString();
      final date = (d['date'] ?? d['due_date'] ?? '').toString();
      return Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: kDark)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: kMuted)),
                ],
              ],
            ),
          ),
          Text(date, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: dateColor)),
        ],
      );
    }
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
          rowFrom(first, dotColor: const Color(0xFFFF6B6B), dateColor: const Color(0xFFFF6B6B)),
          if (second != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: kBorder, thickness: 1),
            ),
            rowFrom(second, dotColor: kBlue, dateColor: kBlue),
          ],
        ],
      ),
    );
  }

  // ACHIEVEMENTS SECTION
  Widget _buildAchievementsSection() {
    final achievements = _achievementItems.isNotEmpty
        ? _achievementItems
        : [
            {'icon': '🏆', 'label': 'Top Scorer', 'locked': false},
            {'icon': '🔥', 'label': '7-Day Streak', 'locked': false},
            {'icon': '📜', 'label': '3 Certs', 'locked': false},
            {'icon': '🌟', 'label': 'Locked', 'locked': true},
          ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final crossAxisCount = available >= 920
            ? 5
            : available >= 700
                ? 4
                : 3;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: achievements.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.12,
            ),
            itemBuilder: (context, index) {
              final a = achievements[index];
              final bool locked = a['locked'] == true;
              return Container(
                decoration: BoxDecoration(
                  color: locked ? kBlue.withValues(alpha: 0.05) : kWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: locked
                      ? Border.all(
                          color: kBlue.withValues(alpha: 0.15),
                          width: 1.5,
                          strokeAlign: BorderSide.strokeAlignInside,
                        )
                      : null,
                  boxShadow: locked
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Opacity(
                  opacity: locked ? 0.4 : 1.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (a['icon'] ?? '🏅').toString(),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          (a['label'] ?? 'Achievement').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: kDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Recommended For You Section ──────────────────────────────────────
  Widget _buildRecommendedForYouSection() {
    final recommended = _recommendedItems.isNotEmpty
        ? _recommendedItems
        : [
            {'title': 'CE: Agency Law', 'state': 'CA', 'hours': 3, 'icon': Icons.menu_book},
            {'title': 'Fair Housing Act', 'state': 'CA', 'hours': 2, 'icon': Icons.article_outlined},
            {'title': 'Ethical Practices', 'state': 'TX', 'hours': 4, 'icon': Icons.gavel},
          ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final crossAxisCount = available >= 1050
            ? 5
            : available >= 760
                ? 4
                : 3;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommended.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.02,
            ),
            itemBuilder: (context, index) {
              final c = recommended[index];
              return Container(
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Container(
                        width: double.infinity,
                        color: kDark,
                        alignment: Alignment.center,
                        child: Icon(
                          (c['icon'] as IconData?) ?? Icons.menu_book,
                          color: kBlue,
                          size: 28,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (c['title'] ?? 'Recommended').toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: kDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${c['hours'] ?? 0} CE hrs · ${c['state'] ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                                color: kMuted,
                              ),
                            ),
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
      },
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
