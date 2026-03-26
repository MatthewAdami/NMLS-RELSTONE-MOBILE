import 'package:flutter/material.dart';
import 'package:nmls_mobile/catalog/api_client.dart' as catalog;
import 'package:nmls_mobile/catalog/token_provider.dart';
import 'package:nmls_mobile/config/api_config.dart';
import 'package:nmls_mobile/catalog/courses_catalog_screen.dart';
import 'package:nmls_mobile/widgets/app_bottom_nav.dart';

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

      final items = availableList.whereType<Map<String, dynamic>>().map((
        course,
      ) {
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

        final id = course['_id']?.toString() ?? course['id']?.toString() ?? '';
        final title = course['title']?.toString() ?? '';
        final type = course['type']?.toString() ?? '';
        final creditHours =
            course['credit_hours'] ?? course['creditHours'] ?? 0;
        final description = course['description']?.toString() ?? '';

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

        // UX: show "Start" for not-yet-started courses, "Resume" otherwise.
        final isNotStarted = !isCompleted && progress01 <= 0.001;

        final icon = type.toUpperCase() == 'PE'
            ? Icons.menu_book
            : Icons.schedule;

        return <String, dynamic>{
          'id': id,
          'title': title,
          'subtitle':
              '${type.isNotEmpty ? type : 'Course'} · ${parseNum(creditHours)} hrs',
          'description': description,
          'type': type,
          'progress': progress01,
          'action': isCompleted
              ? 'Certificate'
              : (isNotStarted ? 'Start' : 'Resume'),
          'icon': icon,
        };
      }).toList();

      setState(() => _allItems = items);
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
            return p < 1.0;
          }).toList()
        : _tabIndex == 1
        ? filtered.where((i) {
            final p = (i['progress'] as num?)?.toDouble() ?? 0.0;
            return p >= 1.0;
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
                    onPressed: () {},
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
