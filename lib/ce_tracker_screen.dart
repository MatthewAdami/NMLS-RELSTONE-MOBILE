import 'package:flutter/material.dart';
import 'package:nmls_mobile/courses_screen.dart';
import 'package:nmls_mobile/widgets/app_bottom_nav.dart';
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
                  value: 20 / 24,
                  strokeWidth: 12,
                  color: kBlue,
                  backgroundColor: kBlue.withValues(alpha: 0.15),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '20',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'of 24 hrs',
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
            'California DRE · Renewal Cycle 2024–2026',
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
                value: '24',
                label: 'Required',
                valueColor: Colors.white,
                bgColor: const Color(0xFF142C3F), // Approximate dark muted blue
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                value: '20',
                label: 'Completed',
                valueColor: const Color(0xFF4ADE80), // Green text
                bgColor: const Color(0xFF13362B), // Dark Green bg
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                value: '4',
                label: 'Remaining',
                valueColor: const Color(0xFFFF6B6B), // Red text
                bgColor: const Color(0xFF3B1E26), // Dark Red bg
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Renewal Deadline
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1C24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today_outlined, color: Color(0xFFFF6B6B), size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Renewal deadline: Jun 18, 2026 — 28 days away',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
          ),
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
    final completedCourses = [
      {'title': 'CE: Fair Housing', 'date': 'Jan 2026', 'hrs': 2},
      {'title': 'CE: Ethics & Conduct', 'date': 'Nov 2025', 'hrs': 3},
      {'title': 'CE: Agency Relationships', 'date': 'Sep 2025', 'hrs': 3},
      {'title': 'Real Estate Finance', 'date': 'Mar 2025', 'hrs': 12},
    ];

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
                                course['title'] as String,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: kDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Completed ${course['date']}',
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
                                '${course['hrs']}',
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
            '4 hrs needed by Jun 18, 2026',
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
