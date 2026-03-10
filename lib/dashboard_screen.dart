import 'package:flutter/material.dart';

// ─── Theme Constants ─────────────────────────────────────────────────
const kRed = Color(0xFFC0392B);
const kRedLight = Color(0xFFFDF0EF);
const kRedBorder = Color(0xFFF5C6C2);
const kDark = Color(0xFF1A1A1A);
const kGrey = Color(0xFF888888);
const kGreyLight = Color(0xFFF5F5F0);
const kWhite = Colors.white;

// ─── Dashboard Screen ─────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  const DashboardScreen({Key? key, this.user}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _courses = [
    {
      'title': 'SAFE Act PE: 20-Hour Pre-Licensing',
      'category': 'Pre-Licensing',
      'hours': 20,
      'progress': 0.75,
      'status': 'in-progress',
    },
    {
      'title': 'Ethics & Consumer Protection',
      'category': 'CE',
      'hours': 3,
      'progress': 1.0,
      'status': 'completed',
    },
    {
      'title': 'Federal Law & Regulations',
      'category': 'CE',
      'hours': 3,
      'progress': 0.4,
      'status': 'in-progress',
    },
    {
      'title': 'Nontraditional Mortgage Products',
      'category': 'CE',
      'hours': 2,
      'progress': 0.0,
      'status': 'not-started',
    },
  ];

  String get _userName => widget.user?['name'] ?? 'Student';
  String get _userEmail => widget.user?['email'] ?? '';
  String get _userInitial =>
      (_userName.isNotEmpty ? _userName[0] : 'U').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGreyLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildOverviewTab(),
                  _buildCoursesTab(),
                  _buildCertificatesTab(),
                  _buildProfileTab(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final titles = ['Overview', 'My Courses', 'Certificates', 'Profile'];
    final subtitles = [
      'Welcome back, ${_userName.split(' ').first} 👋',
      'Track your progress',
      'Your credentials',
      'Manage your account',
    ];

    return Container(
      color: kWhite,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titles[_selectedTab],
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: kDark),
              ),
              Text(
                subtitles[_selectedTab],
                style: const TextStyle(fontSize: 12, color: kGrey),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kRed, Color(0xFFE74C3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _userInitial,
                style: const TextStyle(
                    color: kWhite, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Overview Tab ─────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: const [
              _StatCard('4', 'Courses Enrolled', Icons.menu_book_outlined),
              _StatCard('18', 'Hours Completed', Icons.access_time_outlined),
              _StatCard('1', 'Certificates', Icons.workspace_premium_outlined),
              _StatCard('3', 'States Approved', Icons.map_outlined),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Continue Learning',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: kDark),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: const Text(
                  'View all →',
                  style: TextStyle(
                      fontSize: 13, color: kRed, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._courses
              .where((c) => c['status'] == 'in-progress')
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CourseCard(course: c),
                  )),

          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhite,
              border: Border.all(color: kRedBorder),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: kRedLight,
                      borderRadius: BorderRadius.circular(8)),
                  child:
                      const Icon(Icons.info_outline, color: kRed, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NMLS CE Deadline Reminder',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kDark),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Complete your 8 hours of CE by December 31st to maintain your license.',
                        style:
                            TextStyle(fontSize: 12, color: kGrey, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Courses Tab ──────────────────────────────────────────────────────
  Widget _buildCoursesTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _CourseCard(course: _courses[i]),
    );
  }

  // ── Certificates Tab ─────────────────────────────────────────────────
  Widget _buildCertificatesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1 Certificate Earned',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: kDark),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: const Color(0xFFF0F0F0), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: kRedLight,
                      borderRadius: BorderRadius.circular(99)),
                  child: const Text(
                    'NMLS APPROVED',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: kRed,
                        letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ethics & Consumer Protection',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  '3 Credit Hours · Completed Jan 2025',
                  style: TextStyle(fontSize: 12, color: kGrey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRed,
                      foregroundColor: kWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
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

  // ── Profile Tab ──────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    final fields = [
      {'label': 'Full Name', 'value': _userName},
      {'label': 'Email Address', 'value': _userEmail.isNotEmpty ? _userEmail : '—'},
      {'label': 'NMLS ID', 'value': widget.user?['nmlsId'] ?? 'Not set'},
      {'label': 'License State', 'value': widget.user?['state'] ?? 'Not set'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kRed, Color(0xFFE74C3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _userInitial,
                  style: const TextStyle(
                      color: kWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _userName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: kDark),
            ),
            const SizedBox(height: 4),
            Text(
              _userEmail,
              style: const TextStyle(fontSize: 13, color: kGrey),
            ),
            const SizedBox(height: 24),

            ...fields.map((f) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(f['label']!,
                              style: const TextStyle(
                                  fontSize: 13, color: kGrey)),
                          Text(f['value']!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kDark)),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFFF5F5F0), height: 1),
                  ],
                )),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRed,
                  foregroundColor: kWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Edit Profile',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kGrey,
                  side: const BorderSide(color: Color(0xFFE2E2E2)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Sign Out',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Overview'},
      {'icon': Icons.menu_book_outlined, 'activeIcon': Icons.menu_book, 'label': 'Courses'},
      {'icon': Icons.workspace_premium_outlined, 'activeIcon': Icons.workspace_premium, 'label': 'Certs'},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: kWhite,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active
                        ? items[i]['activeIcon'] as IconData
                        : items[i]['icon'] as IconData,
                    color: active ? kRed : const Color(0xFFBBBBBB),
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i]['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: active ? kRed : const Color(0xFFBBBBBB),
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard(this.value, this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: kRedLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kRed, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: kDark)),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: kGrey)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Course Card ─────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final status = course['status'] as String;
    final progress = course['progress'] as double;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'completed':
        statusColor = const Color(0xFF27AE60);
        statusLabel = 'Completed';
        break;
      case 'in-progress':
        statusColor = kRed;
        statusLabel = 'In Progress';
        break;
      default:
        statusColor = const Color(0xFFAAAAAA);
        statusLabel = 'Not Started';
    }

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: kRedLight,
                    borderRadius: BorderRadius.circular(99)),
                child: Text(
                  course['category'],
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kRed),
                ),
              ),
              Text(statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            course['title'],
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: kDark),
          ),
          const SizedBox(height: 4),
          Text(
            '${course['hours']} Credit Hours',
            style: const TextStyle(fontSize: 12, color: kGrey),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                status == 'completed'
                    ? const Color(0xFF27AE60)
                    : kRed,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% complete',
                style: const TextStyle(fontSize: 11, color: kGrey),
              ),
              if (status == 'in-progress')
                _MiniButton('Resume', kRed, kWhite)
              else if (status == 'not-started')
                _MiniButton('Start Course', const Color(0xFFF5F5F0), kDark)
              else
                const Text(
                  '✓ Certified',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF27AE60)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Mini Button ─────────────────────────────────────────────────────
class _MiniButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _MiniButton(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: fg),
        ),
      ),
    );
  }
}