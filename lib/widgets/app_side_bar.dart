import 'package:flutter/material.dart';
import 'package:nmls_mobile/contact_support_page.dart';
import 'package:nmls_mobile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Colors ───────────────────────────────────────────────────────
const kDark   = Color(0xFF091925);
const kBlue   = Color(0xFF2EABFE);
const kBlue60 = Color(0xFF60C3FF);
const kWhite  = Colors.white;
const kMuted  = Color(0xFF7FA8C4);
const kRed    = Color(0xFFEF4444);
const kBg     = Color(0xFFF0F4F8);
const kBorder = Color(0x40020817);

// ─── Nav Item Model ───────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label, sub;
  final String? route;
  final bool danger;
  const _NavItem({
    required this.icon, required this.label, required this.sub,
    this.route, this.danger = false,
  });
}

// ═══════════════════════════════════════════════════════════════════
// APP SHELL
// ═══════════════════════════════════════════════════════════════════
class AppShell extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String nmlsId;

  const AppShell({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.nmlsId,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _currentRoute = '/dashboard';
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigate(String route) {
    _scaffoldKey.currentState?.closeDrawer();
    setState(() => _currentRoute = route);
  }

  void _signOut() {
    _scaffoldKey.currentState?.closeDrawer();
    // TODO: push to your login screen
    debugPrint('signed out');
  }

  Widget _buildBody() {
    switch (_currentRoute) {

      // ── PROFILE ──────────────────────────────────────────────
      case '/profile':
        return ProfilePage(
          userName:  widget.userName,
          userEmail: widget.userEmail,
          nmlsId:    widget.nmlsId,
        );
        case '/support':
        return ContactSupportPage(
          userName:  widget.userName,
          userEmail: widget.userEmail,
          // nmlsId:    widget.nmlsId,
        );

      // case '/dashboard':  return DashboardPage();
      // case '/my-courses': return MyCoursesScreen();
      // case '/courses':    return CoursesScreen(token: _token, ...);
      // case '/orders':     return OrdersScreen(token: _token);
      // case '/certificates': return MyCertificatesScreen(...);

      default:
        return Center(
          child: Text(
            '$_currentRoute\n(coming soon)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: kMuted, fontWeight: FontWeight.w600),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBg,
      appBar: AppTopBar(
        userName:     widget.userName,
        nmlsId:       widget.nmlsId,
        scaffoldKey:  _scaffoldKey,
        onProfileTap: () => _navigate('/profile'), // ← user chip shortcut
      ),
      drawer: AppSidebar(
        userName:     widget.userName,
        userEmail:    widget.userEmail,
        nmlsId:       widget.nmlsId,
        currentRoute: _currentRoute,
        onNavigate:   _navigate,
        onSignOut:    _signOut,
      ),
      body: _buildBody(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// APP SIDEBAR
// ═══════════════════════════════════════════════════════════════════
class AppSidebar extends StatefulWidget {
  final String userName, userEmail;
  final String? nmlsId;
  final String currentRoute;
  final void Function(String route) onNavigate;
  final VoidCallback onSignOut;

  const AppSidebar({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.currentRoute,
    required this.onNavigate,
    required this.onSignOut,
    this.nmlsId,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _showLogoutConfirm = false;

  static const _myAccount = [
    _NavItem(icon: Icons.dashboard_outlined,    label: 'Dashboard',      sub: 'Home / Overview & Summary',              route: '/dashboard'),
    _NavItem(icon: Icons.menu_book_outlined,     label: 'My Courses',     sub: 'Progress & Certificates',               route: '/my-courses'),
    _NavItem(icon: Icons.workspace_premium,      label: 'Certificates',   sub: 'Download & Verify',                     route: '/certificates'),
    _NavItem(icon: Icons.school_outlined,        label: 'Browse Courses', sub: 'Find PE and CE courses',                route: '/courses'),
  ];

  static const _settings = [
    _NavItem(icon: Icons.person_outline,         label: 'My Profile',     sub: 'Personal info & preferences',           route: '/profile'),
    _NavItem(icon: Icons.tune_outlined,          label: 'Account Setup',  sub: 'NMLS ID, license goals & notifications',route: '/account-setup'),
    _NavItem(icon: Icons.shopping_cart_outlined, label: 'My Orders',      sub: 'Purchase History & Receipts',           route: '/orders'),
    _NavItem(icon: Icons.help_outline,           label: 'Contact Support',sub: 'Get Help from RELS NMLS',               route: '/support'),
  ];

  String get _initials {
    final parts = widget.userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return 'AC';
  }

  String get _studentId =>
      (widget.nmlsId != null && widget.nmlsId!.isNotEmpty) ? '#NM-${widget.nmlsId}' : 'Student';

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          _buildDrawer(context),
          if (_showLogoutConfirm) _buildLogoutDialog(context),
        ],
      );

  Widget _buildDrawer(BuildContext context) => Container(
        width: 300,
        color: kWhite,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(color: kBlue, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(_initials,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: kDark)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userName.isEmpty ? 'Student' : widget.userName,
                            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: kDark),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(_studentId,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: kBlue, letterSpacing: 0.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _divider(),
            _sectionLabel('MY ACCOUNT'),
            ..._myAccount.map((item) => _NavTile(
              item: item,
              active: widget.currentRoute == item.route,
              onTap: () { if (item.route != null) widget.onNavigate(item.route!); },
            )),
            _divider(),
            _sectionLabel('SETTINGS & SUPPORT'),
            ..._settings.map((item) => _NavTile(
              item: item,
              active: widget.currentRoute == item.route,
              onTap: () { if (item.route != null) widget.onNavigate(item.route!); },
            )),
            _divider(),
            _NavTile(
              item: const _NavItem(icon: Icons.logout, label: 'Sign out', sub: 'End Your Session', danger: true),
              active: false,
              onTap: () => setState(() => _showLogoutConfirm = true),
            ),
            const Spacer(),
          ],
        ),
      );

  Widget _divider() => Container(
        height: 0.5,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: kMuted.withOpacity(0.4),
      );

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
        child: Text(label,
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 11,
                color: kMuted, letterSpacing: 0.07 * 11)),
      );

  Widget _buildLogoutDialog(BuildContext context) => Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showLogoutConfirm = false),
                child: Container(color: const Color(0xFF091925).withOpacity(0.55)),
              ),
              Center(
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 26),
                  decoration: BoxDecoration(
                    color: kWhite, borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: kDark.withOpacity(0.20), blurRadius: 70, offset: const Offset(0, 28))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: kRed.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kRed.withOpacity(0.18)),
                        ),
                        child: const Icon(Icons.logout, color: kRed, size: 22),
                      ),
                      const SizedBox(height: 16),
                      const Text('Sign out?',
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: kDark)),
                      const SizedBox(height: 8),
                      Text('Are you sure you want to sign out of your account?',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: kDark.withOpacity(0.52))),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _showLogoutConfirm = false),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: kDark.withOpacity(0.04), borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kDark.withOpacity(0.10)),
                                ),
                                alignment: Alignment.center,
                                child: Text('No, stay',
                                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                                        fontSize: 14, color: kDark.withOpacity(0.72))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                setState(() => _showLogoutConfirm = false);
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.remove('token');
                                await prefs.remove('user');
                                widget.onSignOut();
                              },
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: kRed.withOpacity(0.90), borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Text('Yes, sign out',
                                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                                        fontSize: 14, color: kWhite)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Nav Tile ─────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _NavTile({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = item.danger ? kRed : active ? kBlue : const Color(0xFF5B7384);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: active ? kBlue.withOpacity(0.10) : Colors.transparent,
          border: Border(left: BorderSide(color: active ? kBlue : Colors.transparent, width: 3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: item.danger
                    ? kRed.withOpacity(0.10)
                    : active ? kBlue.withOpacity(0.12) : kMuted.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? kBlue.withOpacity(0.22) : Colors.transparent),
              ),
              child: Icon(item.icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: TextStyle(fontFamily: 'Poppins',
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14, color: item.danger ? kRed : kDark)),
                  const SizedBox(height: 2),
                  Text(item.sub,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: kMuted),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// APP TOP BAR
// ═══════════════════════════════════════════════════════════════════
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? nmlsId;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback? onProfileTap;

  const AppTopBar({
    super.key,
    required this.userName,
    required this.scaffoldKey,
    this.nmlsId,
    this.onProfileTap,
  });

  String get _initials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return 'AC';
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 85,
        color: kDark,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => scaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: kWhite.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kWhite.withOpacity(0.15)),
                ),
                child: const Icon(Icons.menu, color: kWhite, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NMLS',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900, fontSize: 18, color: kWhite)),
                Text('Mortgage Licensing Education',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
                        color: kWhite.withOpacity(0.70), letterSpacing: 0.4)),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                decoration: BoxDecoration(
                  color: kWhite.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: kBlue60),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(color: kBlue, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(_initials,
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12, color: kDark)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      userName.split(' ').firstWhere((p) => p.isNotEmpty, orElse: () => 'Student'),
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: kWhite),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Size get preferredSize => const Size.fromHeight(85);
}