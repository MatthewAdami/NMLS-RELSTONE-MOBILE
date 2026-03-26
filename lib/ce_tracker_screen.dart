import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/courses_screen.dart';
import 'package:nmls_mobile/config/api_config.dart';
import 'package:nmls_mobile/widgets/app_bottom_nav.dart';
import 'package:nmls_mobile/catalog/token_provider.dart';
import 'package:nmls_mobile/services/auth_service.dart';
// ─── Theme ────────────────────────────────────────────────────────────
const kDark        = Color(0xFF091925);
const kBlue        = Color(0xFF2EABFE);
const kBlueFaint   = Color(0x1A2EABFE);
const kBlueBorder  = Color(0x382EABFE);
const kTeal        = Color(0xFF00B4B4);
const kTealFaint   = Color(0x1A00B4B4);
const kTealBorder  = Color(0x3300B4B4);
const kBg          = Color(0xFFF6F7FB);
const kWhite       = Colors.white;
const kMuted       = Color(0x990B1220);
const kBorder      = Color(0x1A020817);
const kSurface     = Color(0xD0FFFFFF);

class CETrackerScreen extends StatefulWidget {
  final String? token;
  final String userName;
  final String userEmail;
  const CETrackerScreen({
    Key? key,
    this.token,
    this.userName = 'User',
    this.userEmail = 'user@example.com',
  }) : super(key: key);

  @override
  State<CETrackerScreen> createState() => _CETrackerScreenState();
}

class _CETrackerScreenState extends State<CETrackerScreen> {
  bool _loading = true;
  String _error = '';

  String _stateCode = '';
  String _stateName = '';

  int _requiredHours = 0;
  int _completedHours = 0;

  List<_CeCompletionRow> _completedCourses = const [];

  // Authorization headers can be missing when the screen is opened from a
  // navigation path that does not pass `token`. We fallback to
  // SharedPreferences inside `_loadCeData()`.

  @override
  void initState() {
    super.initState();
    _loadCeData();
  }

  Future<void> _loadCeData() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final token = (widget.token != null && widget.token!.trim().isNotEmpty)
          ? widget.token!.trim()
          : await SharedPreferencesTokenProvider().getToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final dashRes = await http
          .get(Uri.parse(ApiConfig.dashboard), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (dashRes.statusCode != 200) {
        if (dashRes.statusCode == 401 || dashRes.statusCode == 403) {
          await AuthService.logout();
          setState(() {
            _error = 'Session expired. Please sign in again.';
            _loading = false;
          });
          return;
        }
        setState(() {
          _error = 'Failed to load dashboard (${dashRes.statusCode}).';
          _loading = false;
        });
        return;
      }

      final dash = jsonDecode(dashRes.body) as Map<String, dynamic>;
      final profile = Map<String, dynamic>.from((dash['profile'] as Map?) ?? {});
      final completions = Map<String, dynamic>.from((dash['completions'] as Map?) ?? {});
      final ceListRaw = (completions['CE'] as List?) ?? const [];

      final stateCode = (profile['state'] ?? '').toString().trim().toUpperCase();

      final ceRows = ceListRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(_CeCompletionRow.fromApi)
          .whereType<_CeCompletionRow>()
          .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

      final completedHours = ceRows.fold<int>(0, (sum, e) => sum + e.creditHours);

      int requiredHours = 0;
      String stateName = '';
      if (stateCode.isNotEmpty && stateCode != 'NOT SET') {
        final reqRes = await http
            .get(
              Uri.parse(ApiConfig.stateRequirementDetail(stateCode)),
            )
            .timeout(const Duration(seconds: 15));

        if (reqRes.statusCode == 200) {
          final req = jsonDecode(reqRes.body) as Map<String, dynamic>;
          stateName = (req['stateName'] ?? '').toString().trim();
          final ceRenewal = Map<String, dynamic>.from((req['ceRenewal'] as Map?) ?? {});
          requiredHours = (ceRenewal['hours'] as num?)?.toInt() ?? 0;
        }
      }

      setState(() {
        _stateCode = stateCode;
        _stateName = stateName;
        _requiredHours = requiredHours;
        _completedHours = completedHours;
        _completedCourses = ceRows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to reach CE API. Please retry.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTopSection(),
                    _buildBottomSection(),
                  ],
                ),
              ),
            ),
            AppBottomNav(
              activeTab: AppNavTab.ceTracker,
              userName: widget.userName,
              userEmail: widget.userEmail,
              token: widget.token,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    final required = _requiredHours <= 0 ? 8 : _requiredHours;
    final completed = _completedHours.clamp(0, required);
    final remaining = (required - completed).clamp(0, required);
    final progress = required == 0 ? 0.0 : (completed / required).clamp(0.0, 1.0);
    final stateLabel = _stateName.isNotEmpty
        ? _stateName
        : (_stateCode.isNotEmpty && _stateCode != 'NOT SET' ? _stateCode : 'Your State');

    return Container(
      color: kDark,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'CE Tracker',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Circular Progress Indicator
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  color: kBlue,
                  backgroundColor: kBlue.withValues(alpha: 0.15),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$completed',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'of $required hrs',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$stateLabel · Continuing Education',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          // Stats row
          Row(
            children: [
              _buildStatCard(
                value: '$required',
                label: 'Required',
                valueColor: Colors.white,
                bgColor: const Color(0xFF142C3F), // Approximate dark muted blue
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                value: '$completed',
                label: 'Completed',
                valueColor: const Color(0xFF4ADE80), // Green text
                bgColor: const Color(0xFF13362B), // Dark Green bg
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                value: '$remaining',
                label: 'Remaining',
                valueColor: const Color(0xFFFF6B6B), // Red text
                bgColor: const Color(0xFF3B1E26), // Dark Red bg
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  Text(
                    _error,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _loadCeData,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kBlue,
                      side: BorderSide(color: kBlue.withValues(alpha: 0.6)),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color valueColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final completedCourses = _completedCourses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'COMPLETED CE COURSES',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: kDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              children: List.generate(completedCourses.length, (index) {
                final course = completedCourses[index];
                final isLast = index == completedCourses.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: kDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Completed ${course.completedLabel}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: kMuted,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${course.creditHours}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: kBlue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'hrs',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: kBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: kBorder.withValues(alpha: 0.05),
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => CoursesScreen(
                  token: widget.token,
                  userName: widget.userName,
                  userEmail: widget.userEmail,
                )));
              },
              child: const Text(
                'Browse More CE Courses',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _requiredHours > 0
                ? '${(_requiredHours - _completedHours).clamp(0, _requiredHours)} hrs remaining'
                : 'Complete your annual CE hours to stay compliant.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: kMuted,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

}

class _CeCompletionRow {
  final String title;
  final int creditHours;
  final DateTime completedAt;

  const _CeCompletionRow({
    required this.title,
    required this.creditHours,
    required this.completedAt,
  });

  static _CeCompletionRow? fromApi(Map<String, dynamic> data) {
    final courseId = data['course_id'];
    final course = courseId is Map ? Map<String, dynamic>.from(courseId) : null;
    final title = (course?['title'] ?? '').toString().trim();
    final hours = (course?['credit_hours'] as num?)?.toInt() ?? 0;
    final completedAtRaw = (data['completed_at'] ?? '').toString().trim();
    final completedAt = DateTime.tryParse(completedAtRaw);
    if (title.isEmpty || completedAt == null) return null;
    return _CeCompletionRow(title: title, creditHours: hours, completedAt: completedAt);
  }

  String get completedLabel {
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
    final m = months[(completedAt.month - 1).clamp(0, 11)];
    return '$m ${completedAt.year}';
  }
}
