import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/config/api_config.dart';
import 'package:nmls_mobile/widgets/app_bottom_nav.dart';

// ─── Theme ────────────────────────────────────────────────────────────
const kDark        = Color(0xFF091925);
const kBlue        = Color(0xFF2EABFE);
const kBlueFaint   = Color(0x1A2EABFE);
const kBlueBorder  = Color(0x382EABFE);
const kTeal        = Color(0xFF00B4B4);
const kBg          = Color(0xFFF6F7FB);
const kWhite       = Colors.white;
const kMuted       = Color(0x990B1220);
const kBorder      = Color(0x1A020817);
const kSurface     = Color(0xD0FFFFFF);

class CoursesScreen extends StatefulWidget {
  final String? token;
  final String userName;
  final String userEmail;
  const CoursesScreen({Key? key, this.token, this.userName = 'User', this.userEmail = 'user@example.com'}) : super(key: key);

  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _tabIndex = 0; // 0 = In Progress, 1 = Completed, 2 = Wishlist
  String _activeFilter = 'All States';
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _courses = [];

  String get _apiBase => '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}';
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
  };

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    if (widget.token == null || widget.token!.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing session token. Please sign in again.';
        _courses = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final res = await http
          .get(Uri.parse('$_apiBase/courses'), headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is List ? decoded : const [];
        setState(() {
          _courses = list
              .whereType<Map>()
              .map((raw) => Map<String, dynamic>.from(raw))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _courses = [];
          _error = 'Could not load courses (${res.statusCode}).';
        });
      }
    } catch (_) {
      setState(() {
        _loading = false;
        _courses = [];
        _error = 'Could not connect to courses service.';
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopSection(),
            _buildTabs(),
            _buildFilters(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kBlue))
                  : _error.isNotEmpty
                      ? _buildErrorView()
                      : _buildCourseList(),
            ),
            AppBottomNav(
              activeTab: AppNavTab.courses,
              userName: widget.userName,
              userEmail: widget.userEmail,
              token: widget.token,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header & Search ───────────────────────────────────────────────
  Widget _buildTopSection() {
    return Container(
      color: kDark,
      padding: const EdgeInsets.only(top: 16, bottom: 20, left: 16, right: 16),
      child: Column(
        children: [
          const Text(
            'My Courses',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF152633), // Darker blend for the search bar
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF6B8397), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search courses...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xFF6B8397),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ───────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Container(
      color: kWhite,
      child: Row(
        children: [
          _buildTabItem('In Progress', 0),
          _buildTabItem('Completed', 1),
          _buildTabItem('Wishlist', 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    bool isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                  color: isActive ? kBlue : const Color(0xFF7D92A3),
                ),
              ),
            ),
            Container(
              height: 2,
              color: isActive ? kBlue : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filters ───────────────────────────────────────────────────────
  Widget _buildFilters() {
    final filters = ['All States', 'California', 'Texas', 'CE Only'];
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((f) {
            bool isActive = _activeFilter == f;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _activeFilter = f;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? kBlue : kWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? kBlue : kBorder.withValues(alpha: 0.1)),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                    color: isActive ? kWhite : kMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Course List ───────────────────────────────────────────────────
  Widget _buildCourseList() {
    final search = _searchCtrl.text.trim().toLowerCase();
    final wantedStatus = _tabIndex == 0
        ? 'in_progress'
        : _tabIndex == 1
            ? 'completed'
            : 'wishlist';

    final items = _courses.where((course) {
      final status = (course['enrollment_status'] as String? ?? 'in_progress').toLowerCase();
      if (status != wantedStatus) return false;

      final states = ((course['states_approved'] as List?) ?? const [])
          .map((e) => e.toString().toUpperCase())
          .toList();
      final type = (course['type'] as String? ?? '').toUpperCase();

      if (_activeFilter == 'California' && !states.contains('CA')) return false;
      if (_activeFilter == 'Texas' && !states.contains('TX')) return false;
      if (_activeFilter == 'CE Only' && type != 'CE') return false;

      if (search.isEmpty) return true;
      final title = (course['title'] as String? ?? '').toLowerCase();
      final description = (course['description'] as String? ?? '').toLowerCase();
      return title.contains(search) || description.contains(search);
    }).toList();

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No assigned courses found for this tab.',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final course = items[index];
        final progress = ((course['progress_percent'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
        final title = course['title'] as String? ?? 'Untitled Course';
        final states = ((course['states_approved'] as List?) ?? const [])
            .map((e) => e.toString().toUpperCase())
            .toList();
        final stateText = states.isEmpty ? 'All States' : states.first;
        final hours = (course['credit_hours'] as num?)?.toInt() ?? 0;
        final status = (course['enrollment_status'] as String? ?? 'in_progress').toLowerCase();
        final subtitle = '$stateText · $hours hrs';
        final actionText = status == 'completed'
            ? 'Certificate'
            : status == 'wishlist'
                ? 'Enroll'
                : 'Resume';
        final type = (course['type'] as String? ?? '').toUpperCase();
        final icon = type == 'CE'
            ? Icons.schedule
            : type == 'EXAM_PREP'
                ? Icons.assignment_outlined
                : Icons.menu_book;

        // Custom styling logic for the UI image matches
        Color titleColor = kDark;
        Color progressColor;
        Color progressBgColor = kBlue.withValues(alpha: 0.15);
        Color textColor;
        
        if (progress >= 1.0 || status == 'completed') {
          progressColor = kTeal;
          progressBgColor = kTeal.withValues(alpha: 0.15);
          textColor = kTeal;
        } else if (progress > 0 || status == 'in_progress') {
          progressColor = kBlue;
          textColor = kBlue;
        } else if (status == 'wishlist') {
          progressColor = Colors.transparent;
          textColor = const Color(0xFF6B8397);
        } else {
          progressColor = const Color(0xFF6B8397);
          textColor = const Color(0xFF6B8397);
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: kBlue, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                            color: kMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (status != 'wishlist') const SizedBox(height: 16),
              if (status != 'wishlist')
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: progressBgColor,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (status != 'wishlist')
                    Text(
                      '${(progress * 100).toInt()}% complete',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: kWhite,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      actionText,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: kMuted,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchCourses,
              style: ElevatedButton.styleFrom(backgroundColor: kBlue),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

}