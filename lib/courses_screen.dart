import 'package:flutter/material.dart';
import 'package:nmls_mobile/catalog/api_client.dart' as catalog;
import 'package:nmls_mobile/catalog/token_provider.dart';
import 'package:nmls_mobile/config/api_config.dart';
import 'package:nmls_mobile/catalog/courses_catalog_screen.dart';
import 'package:nmls_mobile/catalog/course_portal_screen.dart';
import 'package:nmls_mobile/my_certificates_screen.dart';
import 'package:nmls_mobile/widgets/app_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme ────────────────────────────────────────────────────────────
const kDark = Color(0xFF091925);
const kBlue = Color(0xFF2EABFE);
const kBlueFaint = Color(0x1A2EABFE);
const kBlueBorder = Color(0x382EABFE);
const kTeal = Color(0xFF00B4B4);
const kBg = Color(0xFFF6F7FB);
const kWhite = Colors.white;
const kMuted = Color(0x990B1220);
const kBorder = Color(0x1A020817);
const kSurface = Color(0xD0FFFFFF);

class CoursesScreen extends StatefulWidget {
  final String? token;
  final String userName;
  final String userEmail;
  const CoursesScreen({
    super.key,
    this.token,
    this.userName = 'User',
    this.userEmail = 'user@example.com',
  });

  @override
  CoursesScreenState createState() => CoursesScreenState();
}

class CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _tabIndex = 0; // 0 = In Progress, 1 = Completed, 2 = Wishlist
  // Nullable to prevent hot-reload stale state from crashing.
  String? _selectedType = 'All'; // All, CE, PE
  String _searchQuery = '';

  bool _loading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _allItems = <Map<String, dynamic>>[];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchMyCourses();
  }

  Future<void> _fetchMyCourses() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Local completion fallback (persists across sign-in).
      final prefs = await SharedPreferences.getInstance();
      final locallyCompletedIds =
          (prefs.getStringList('completed_course_ids') ?? const <String>[])
              .map((e) => e.toString())
              .toSet();
      final locallyCompletedTitles =
          (prefs.getStringList('completed_course_titles') ?? const <String>[])
              .map((e) => e.toString().trim().toLowerCase())
              .where((e) => e.isNotEmpty)
              .toSet();

      final apiClient = catalog.ApiClient(
        baseUrl: ApiConfig.baseUrl,
        tokenProvider: SharedPreferencesTokenProvider(),
      );

      // Backend "My Courses" / dashboard payload is usually under /api/dashboard.
      // Keep /api/data as a fallback for older server versions.
      final res = await (() async {
        try {
          return await apiClient.getJson('/api/dashboard');
        } on catalog.HttpErrorException catch (e) {
          if (e.statusCode == 404) {
            return await apiClient.getJson('/api/data');
          }
          rethrow;
        }
      })();

      final dynamic availableRaw =
          res['available_courses'] ??
          res['availableCourses'] ??
          res['available'] ??
          res['courses'] ??
          res['data'];

      final availableList = (availableRaw is List) ? availableRaw : <dynamic>[];

      num parseNum(dynamic value) {
        if (value is num) return value;
        if (value is String) return num.tryParse(value.trim()) ?? 0;
        return 0;
      }

      bool parseBool(dynamic value) {
        if (value is bool) return value;
        if (value is num) return value != 0;
        if (value is String) {
          final v = value.trim().toLowerCase();
          return v == 'true' || v == '1' || v == 'yes';
        }
        return false;
      }

      String normalizeCompletedAt(dynamic raw) {
        if (raw == null) return '';
        if (raw is String) return raw;
        if (raw is DateTime) return raw.toIso8601String();
        if (raw is num) {
          final dt =
              DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true);
          return dt.toIso8601String();
        }
        return raw.toString();
      }

      final baseItems = availableList
          .whereType<Map<String, dynamic>>()
          .map((course) {
        final id = course['_id']?.toString() ??
            course['id']?.toString() ??
            course['course_id']?.toString() ??
            course['courseId']?.toString() ??
            course['nmls_course_id']?.toString() ??
            course['nmlsCourseId']?.toString() ??
            '';
        final title = course['title']?.toString() ?? '';
        final type = course['type']?.toString() ?? '';
        final creditHours = course['credit_hours'] ??
            course['creditHours'] ??
            course['hours'] ??
            course['duration_hours'] ??
            course['durationHours'] ??
            0;
        final state = course['state']?.toString() ??
            course['license_state']?.toString() ??
            course['licenseState']?.toString() ??
            '';
        final description = course['description']?.toString() ?? '';
        final nmlsCourseId =
            course['nmls_course_id']?.toString() ??
                course['nmlsCourseId']?.toString() ??
                course['nmls_courseid']?.toString() ??
                '';
        final completedAtRaw = course['completed_at'] ??
            course['completedAt'] ??
            course['completedAtIso'] ??
            course['completed'];

        // Normalize into something DateTime.parse can read.
        final completedAtStr = normalizeCompletedAt(completedAtRaw);

        // If backend doesn't provide review_submitted flag yet, default to false
        // so "Review Course" remains clickable in the Completed tab.
        final reviewSubmitted = parseBool(
          course['review_submitted'] ??
              course['reviewSubmitted'] ??
              course['review_submitted_at'] ??
              false,
        );

        final progressRaw =
            course['progress_percent'] ??
            course['progressPercent'] ??
            course['progress'] ??
            course['percent_complete'];

        num progressNum = parseNum(progressRaw);
        if (progressNum > 1) progressNum = progressNum / 100;
        final progress01 = progressNum.clamp(0.0, 1.0).toDouble();

        final isCompleted =
            parseBool(
              course['is_completed'] ??
                  course['isCompleted'] ??
                  course['completed'],
            ) ||
            progress01 >= 1.0;

        final isLocallyCompleted = locallyCompletedIds.contains(id) ||
            locallyCompletedIds.contains(nmlsCourseId) ||
            (title.trim().isNotEmpty &&
                locallyCompletedTitles.contains(title.trim().toLowerCase()));

        // UX: show "Start" for not-yet-started courses, "Resume" otherwise.
        final effectiveCompleted = isCompleted || isLocallyCompleted;
        final isNotStarted = !effectiveCompleted && progress01 <= 0.001;

        final icon = type.toUpperCase() == 'PE'
            ? Icons.menu_book
            : Icons.schedule;

        final localCompletedAt = (() {
          final byId = id.trim().isEmpty ? '' : (prefs.getString('completed_course_at_$id') ?? '');
          if (byId.trim().isNotEmpty) return byId;
          final byNmls = nmlsCourseId.trim().isEmpty
              ? ''
              : (prefs.getString('completed_course_at_${nmlsCourseId.trim()}') ?? '');
          if (byNmls.trim().isNotEmpty) return byNmls;
          final tKey = title.trim().isEmpty ? '' : 'completed_course_at_title_${title.trim().toLowerCase()}';
          return tKey.isEmpty ? '' : (prefs.getString(tKey) ?? '');
        })();

        return <String, dynamic>{
          'id': id,
          'title': title,
          'subtitle':
              '${type.isNotEmpty ? type : 'Course'} · ${parseNum(creditHours)} hrs',
          'description': description,
          'type': type,
          'state': state,
          'nmls_course_id': nmlsCourseId,
          'duration_hours': parseNum(creditHours),
          'completed_at': (completedAtStr.trim().isNotEmpty)
              ? completedAtStr
              : localCompletedAt,
          'review_submitted': reviewSubmitted,
          'progress': effectiveCompleted ? 1.0 : progress01,
          'action': effectiveCompleted
              ? 'Certificate'
              : (isNotStarted ? 'Start' : 'Resume'),
          'icon': icon,
        };
      }).toList();

      // Completed courses should use `res.completions` when available because
      // `available_courses` may not contain `completed_at`.
      final completedItems = <Map<String, dynamic>>[];
      final completionsRaw = res['completions'];
      if (completionsRaw is Map) {
        for (final typeEntry in completionsRaw.entries) {
          final typeKey = typeEntry.key.toString();
          final listRaw = typeEntry.value;
          if (listRaw is! List) continue;

          for (final completion in listRaw) {
            if (completion is! Map) continue;
            final c = completion.cast<String, dynamic>();

            final title = c['title']?.toString() ??
                c['course_title']?.toString() ??
                c['courseTitle']?.toString() ??
                '';

            final state = c['state']?.toString() ??
                c['license_state']?.toString() ??
                c['licenseState']?.toString() ??
                '';

            final nmlsCourseId =
                c['nmls_course_id']?.toString() ??
                    c['nmlsCourseId']?.toString() ??
                    c['nmls_courseid']?.toString() ??
                    c['nmlsCourseId']?.toString() ??
                    '';

            final hoursRaw = c['credit_hours'] ??
                c['creditHours'] ??
                c['hours'] ??
                c['duration_hours'] ??
                c['durationHours'] ??
                0;

            final completedAtRaw = c['completed_at'] ??
                c['completedAt'] ??
                c['completedAtIso'] ??
                c['completed'];

            final completedAtIso = normalizeCompletedAt(completedAtRaw);

            final reviewSubmitted = parseBool(
              c['review_submitted'] ??
                  c['reviewSubmitted'] ??
                  c['review_submitted_at'] ??
                  false,
            );

            // Use course id if backend provides it; otherwise fall back to nmls_course_id.
            final courseId = c['course_id']?.toString() ??
                c['courseId']?.toString() ??
                c['course']?.toString() ??
                c['_id']?.toString() ??
                nmlsCourseId;

            completedItems.add({
              'id': courseId,
              'title': title,
              'subtitle': '',
              'description': '',
              'type': typeKey,
              'state': state,
              'nmls_course_id': nmlsCourseId,
              'duration_hours': parseNum(hoursRaw),
              'completed_at': completedAtIso,
              'review_submitted': reviewSubmitted,
              'progress': 1.0, // mark as completed for the Completed tab filter
              'action': 'Certificate',
              'icon': typeKey.toUpperCase() == 'PE' ? Icons.menu_book : Icons.schedule,
            });
          }
        }
      }

      // Merge completion fields into the base list so completed courses
      // don't disappear if `res['completions']` is empty/different-shaped.
      if (completedItems.isNotEmpty) {
        final updatesById = <String, Map<String, dynamic>>{};
        for (final c in completedItems) {
          final id = c['id']?.toString() ?? '';
          final nmlsCourseId = c['nmls_course_id']?.toString() ?? '';
          if (id.isNotEmpty) updatesById[id] = c;
          if (nmlsCourseId.isNotEmpty) updatesById[nmlsCourseId] = c;
        }

        for (final item in baseItems) {
          final id = item['id']?.toString() ?? '';
          final nmlsCourseId = item['nmls_course_id']?.toString() ?? '';
          final update = (id.isNotEmpty ? updatesById[id] : null) ??
              (nmlsCourseId.isNotEmpty ? updatesById[nmlsCourseId] : null);
          if (update == null) continue;

          item['completed_at'] = update['completed_at'] ?? item['completed_at'];
          item['duration_hours'] = update['duration_hours'] ?? item['duration_hours'];
          item['review_submitted'] =
              update['review_submitted'] ?? item['review_submitted'];
          item['type'] = update['type'] ?? item['type'];
          item['state'] = update['state'] ?? item['state'];
          item['nmls_course_id'] = update['nmls_course_id'] ?? item['nmls_course_id'];
          item['progress'] = 1.0;
          item['action'] = 'Certificate';
        }
      }

      setState(() => _allItems = baseItems);
    } on catalog.UnauthorizedException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } on catalog.NetworkException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } on catalog.ApiClientException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatCompletedDate(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    final dt = DateTime.tryParse(v);
    if (dt == null) return v;
    const months = <String>[
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
    final m = (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : 'Mon';
    return '$m ${dt.day}, ${dt.year}';
  }

  Widget _buildStateChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 11),
      ),
      backgroundColor: kBlue.withValues(alpha: 0.10),
      side: BorderSide(color: kBlue.withValues(alpha: 0.25)),
    );
  }

  Widget _buildCompletedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kTeal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kTeal.withValues(alpha: 0.35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: kTeal, size: 16),
          SizedBox(width: 6),
          Text(
            'Completed',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: kTeal,
            ),
          ),
        ],
      ),
    );
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
            Expanded(child: _buildCourseList()),
            AppBottomNav(
              activeTab: AppNavTab.courses,
              userName: widget.userName,
              userEmail: widget.userEmail,
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
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CoursesCatalogScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kBlue),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Browse Courses',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
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
            Container(height: 2, color: isActive ? kBlue : Colors.transparent),
          ],
        ),
      ),
    );
  }

  // ─── Filters ───────────────────────────────────────────────────────
  Widget _buildFilters() {
    final selectedType = _selectedType ?? 'All';
    final filters = <String>['All', 'CE', 'PE'];
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((type) {
            bool isActive = selectedType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? kBlue : kWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? kBlue : kBorder.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  type,
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _fetchMyCourses,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final selectedType = (_selectedType ?? 'All').toUpperCase();
    final q = _searchQuery.trim().toLowerCase();

    final filtered = _allItems.where((item) {
      final itemType = (item['type'] as String?)?.toUpperCase() ?? '';
      final matchesType = selectedType == 'ALL'
          ? true
          : itemType == selectedType;

      final title = (item['title'] as String?)?.toLowerCase() ?? '';
      final desc = (item['description'] as String?)?.toLowerCase() ?? '';
      final matchesQuery = q.isEmpty
          ? true
          : (title.contains(q) || desc.contains(q));

      return matchesType && matchesQuery;
    }).toList();

    final items = _tabIndex == 0
        ? filtered.where((i) {
            final p = (i['progress'] as num?)?.toDouble() ?? 0.0;
            final completedFlag = (i['action'] as String?) == 'Certificate';
            return !completedFlag && p < 1.0;
          }).toList()
        : _tabIndex == 1
        ? filtered.where((i) {
            final p = (i['progress'] as num?)?.toDouble() ?? 0.0;
            final completedFlag = (i['action'] as String?) == 'Certificate';
            return completedFlag || p >= 1.0;
          }).toList()
        : <Map<String, dynamic>>[];

    if (items.isEmpty) {
      final message = q.isNotEmpty
          ? 'No results for "$q".'
          : _tabIndex == 2
          ? 'No wishlist items yet.'
          : 'No courses available for your filters.';

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final course = items[index];
        final bool isCompletedTab = _tabIndex == 1;
        if (isCompletedTab) {
          final typeChip = (course['type'] as String?)?.toString() ?? '';
          final stateChip = (course['state'] as String?)?.toString() ?? '';
          final courseTitle = course['title'] as String? ?? '';
          final durationHours = course['duration_hours'] ?? course['credit_hours'] ?? 0;
          final durationStr = (durationHours is num) ? durationHours.toStringAsFixed(durationHours.toInt() == durationHours ? 0 : 1) : durationHours.toString();
          final nmlsCourseId = (course['nmls_course_id'] as String?)?.toString() ?? '';
          final completedAtRaw = (course['completed_at'] as String?)?.toString() ??
              (course['completedAt'] as String?)?.toString() ??
              '';
          final completedAtStr = _formatCompletedDate(completedAtRaw);
          final reviewSubmitted = course['review_submitted'] as bool? ??
              course['reviewSubmitted'] as bool? ??
              false;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kTeal.withValues(alpha: 0.25)),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _buildStateChip(typeChip.isEmpty ? 'CE' : typeChip.toUpperCase()),
                        _buildStateChip(stateChip.isEmpty ? 'CA' : stateChip.toUpperCase()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      courseTitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: kDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Duration: $durationStr hrs',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: kMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'NMLS course id: ${nmlsCourseId.isEmpty ? 'Not set' : nmlsCourseId}',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: kBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kTeal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: kTeal.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        completedAtStr.isEmpty
                            ? 'Completed'
                            : 'Completed · $completedAtStr',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: kTeal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MyCertificatesScreen(
                                    userName: widget.userName,
                                    userEmail: widget.userEmail,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              foregroundColor: kWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Certificate',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: reviewSubmitted
                                ? null
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Review flow not implemented yet.'),
                                      ),
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: reviewSubmitted ? kBorder : kBlue,
                              ),
                            ),
                            child: Text(
                              reviewSubmitted ? 'Review Submitted' : 'Review Course',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: reviewSubmitted ? kMuted : kBlue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (reviewSubmitted)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x1AD0F5E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x3300B4B4)),
                        ),
                        child: const Text(
                          'Review Submitted',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00B4B4),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: _buildCompletedBadge(),
                ),
              ],
            ),
          );
        }
        final progress = (course['progress'] as double? ?? 0.0);
        final title = course['title'] as String? ?? '';
        final subtitle = course['subtitle'] as String? ?? '';
        final actionText = course['action'] as String? ?? 'Resume';
        final icon = course['icon'] as IconData? ?? Icons.menu_book;

        // Custom styling logic for the UI image matches
        Color titleColor = kDark;
        Color progressColor;
        Color progressBgColor = kBlue.withValues(alpha: 0.15);
        Color textColor;

        if (progress == 0.72) {
          progressColor = kBlue;
          textColor = kBlue;
        } else if (progress >= 1.0) {
          progressColor = kTeal;
          progressBgColor = kTeal.withValues(alpha: 0.15);
          textColor = kTeal;
        } else if (progress > 0) {
          progressColor = const Color(0xFF6B8397);
          textColor = const Color(0xFF6B8397);
        } else {
          progressColor = Colors.transparent;
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
              if (_tabIndex != 2) const SizedBox(height: 16),
              if (_tabIndex != 2)
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
                  if (_tabIndex != 2)
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
                    onPressed: () async {
                      final courseId = course['id']?.toString() ?? '';
                      if (courseId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Course id missing; cannot start course.'),
                          ),
                        );
                        return;
                      }
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CoursePortalScreen(courseId: courseId),
                        ),
                      );
                      if (!mounted) return;
                      await _fetchMyCourses();
                      if (!mounted) return;

                      // If backend doesn't reflect completion immediately,
                      // apply a fallback local update AFTER the fetch (so it won't be overwritten).
                      if (result is Map && result['completed'] == true) {
                        final completedCourseId = result['courseId']?.toString() ?? '';
                        if (completedCourseId.isNotEmpty) {
                          final nowIso = DateTime.now().toUtc().toIso8601String();
                          bool updated = false;
                          for (final item in _allItems) {
                            final id = item['id']?.toString() ?? '';
                            final nmlsId = item['nmls_course_id']?.toString() ?? '';
                            final isAlreadyCompleted =
                                (item['action'] as String?) == 'Certificate' ||
                                    ((item['progress'] as num?)?.toDouble() ?? 0) >= 1.0;
                            if (isAlreadyCompleted) continue;
                            if (id == completedCourseId || nmlsId == completedCourseId) {
                              item['progress'] = 1.0;
                              item['action'] = 'Certificate';
                              item['completed_at'] =
                                  (item['completed_at']?.toString().trim().isNotEmpty == true)
                                      ? item['completed_at']
                                      : nowIso;
                              updated = true;
                            }
                          }
                          if (updated) setState(() {});
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: kWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
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
}
