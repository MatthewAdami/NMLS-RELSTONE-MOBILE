import 'package:flutter/material.dart';
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
              child: _buildCourseList(),
            ),
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
    List<Map<String, dynamic>> items = [];

    if (_tabIndex == 0) {
      // IN PROGRESS
      items = [
        {
          'title': 'Real Estate Principles',
          'subtitle': 'CA License · 45 hrs · 2 days ago',
          'icon': Icons.menu_book,
          'progress': 0.72,
          'action': 'Resume',
        },
        {
          'title': 'Mortgage Brokerage Basics',
          'subtitle': 'TX License · 30 hrs · 5 days ago',
          'icon': Icons.feed_outlined, // approximate icon
          'progress': 0.38,
          'action': 'Resume',
        },
        {
          'title': 'CE: Ethics & Conduct',
          'subtitle': 'CA CE · 3 hrs · 1 week ago',
          'icon': Icons.schedule,
          'progress': 0.15,
          'action': 'Resume',
        },
      ];
    } else if (_tabIndex == 1) {
      // COMPLETED
      items = [
        {
          'title': 'Real Estate Practice',
          'subtitle': 'CA License · 45 hrs · Completed Oct 2025',
          'icon': Icons.check_circle_outline,
          'progress': 1.0,
          'action': 'Certificate',
        },
        {
          'title': 'CE: Fair Housing',
          'subtitle': 'CA CE · 2 hrs · Completed Jan 2026',
          'icon': Icons.check_circle_outline,
          'progress': 1.0,
          'action': 'Certificate',
        },
      ];
    } else {
      // WISHLIST
      items = [
        {
          'title': 'Advanced Property Management',
          'subtitle': 'CA License · 12 hrs · Added 2 days ago',
          'icon': Icons.favorite_border,
          'progress': 0.0,
          'action': 'Enroll',
        },
        {
          'title': 'Commercial Real Estate Basics',
          'subtitle': 'All States · 8 hrs · Added 1 month ago',
          'icon': Icons.favorite_border,
          'progress': 0.0,
          'action': 'Enroll',
        },
      ];
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final course = items[index];
        final progress = (course['progress'] as double);
        final title = course['title'] as String;
        final subtitle = course['subtitle'] as String;
        final actionText = course['action'] as String;
        final icon = course['icon'] as IconData;

        // Custom styling logic for the UI image matches
        Color titleColor = kDark;
        Color progressColor;
        Color progressBgColor = kBlue.withValues(alpha: 0.15);
        Color textColor;
        
        if (progress == 0.72) {
          progressColor = kBlue;
          textColor = kBlue;
        } else if (progress == 1.0) {
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

}