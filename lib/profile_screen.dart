import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════
// COLORS  (unified — matches web + sidebar)
// ═══════════════════════════════════════════════════════════════════
const kDark      = Color(0xFF091925);
const kBlue      = Color(0xFF2EABFE);
const kBlue60    = Color(0xFF60C3FF);
const kWhite     = Colors.white;
const kMuted     = Color(0xFF7FA8C4);
const kRed       = Color(0xFFEF4444);
const kBg        = Color(0xFFF0F4F8);
const kBorder    = Color(0x14020817);
const kTeal      = Color(0xFF00B4B4);
const kTextMuted = Color(0x80091925);
const kCardBg    = Color(0xFFFFFFFF);

// ═══════════════════════════════════════════════════════════════════
// ENTRY POINT
// ═══════════════════════════════════════════════════════════════════
void main() => runApp(const NMLSApp());

class NMLSApp extends StatelessWidget {
  const NMLSApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Relstone NMLS',
        theme: ThemeData(
          fontFamily: 'Poppins',
          scaffoldBackgroundColor: kBg,
          colorScheme: ColorScheme.fromSeed(seedColor: kBlue),
        ),
        home: const AppShell(initialRoute: '/profile'),
      );
}

// ═══════════════════════════════════════════════════════════════════
// APP SHELL  — Scaffold with AppTopBar + AppSidebar drawer
// ═══════════════════════════════════════════════════════════════════
class AppShell extends StatefulWidget {
  final String initialRoute;
  const AppShell({super.key, this.initialRoute = '/dashboard'});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late String _currentRoute;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Swap with real auth context
  final String _userName  = 'Johan Angeles';
  final String _userEmail = 'johan@relstone.com';
  final String _nmlsId    = '12345678';

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.initialRoute;
  }

  void _navigate(String route) {
    _scaffoldKey.currentState?.closeDrawer();
    setState(() => _currentRoute = route);
  }

  void _signOut() {
    _scaffoldKey.currentState?.closeDrawer();
    debugPrint('Signed out');
  }

  Widget _buildBody() => switch (_currentRoute) {
    '/profile' => ProfilePage(
        userName:  _userName,
        userEmail: _userEmail,
        nmlsId:    _nmlsId,
      ),
    _ => _PlaceholderPage(route: _currentRoute),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        key: _scaffoldKey,
        backgroundColor: kBg,
        appBar: AppTopBar(
          userName:    _userName,
          nmlsId:      _nmlsId,
          scaffoldKey: _scaffoldKey,
        ),
        drawer: AppSidebar(
          userName:     _userName,
          userEmail:    _userEmail,
          nmlsId:       _nmlsId,
          currentRoute: _currentRoute,
          onNavigate:   _navigate,
          onSignOut:    _signOut,
        ),
        body: _buildBody(),
      );
}

class _PlaceholderPage extends StatelessWidget {
  final String route;
  const _PlaceholderPage({required this.route});
  @override
  Widget build(BuildContext context) => Center(
        child: Text('$route\n(coming soon)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: kMuted, fontWeight: FontWeight.w600)),
      );
}

// ═══════════════════════════════════════════════════════════════════
// APP TOP BAR
// ═══════════════════════════════════════════════════════════════════
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? nmlsId;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const AppTopBar({
    super.key,
    required this.userName,
    required this.scaffoldKey,
    this.nmlsId,
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
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: kWhite)),
                Text('Mortgage Licensing Education',
                    style: TextStyle(fontSize: 10, color: kWhite.withOpacity(0.70), letterSpacing: 0.4)),
              ],
            ),
            const Spacer(),
            Container(
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
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kDark)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    userName.split(' ').firstWhere((p) => p.isNotEmpty, orElse: () => 'Student'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kWhite),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  Size get preferredSize => const Size.fromHeight(85);
}

// ═══════════════════════════════════════════════════════════════════
// APP SIDEBAR
// ═══════════════════════════════════════════════════════════════════
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

class AppSidebar extends StatefulWidget {
  final String userName, userEmail;
  final String? nmlsId;
  final String currentRoute;
  final void Function(String) onNavigate;
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
    _NavItem(icon: Icons.dashboard_outlined,     label: 'Dashboard',      sub: 'Home / Overview & Summary',               route: '/dashboard'),
    _NavItem(icon: Icons.menu_book_outlined,      label: 'My Courses',     sub: 'Progress & Certificates',                route: '/my-courses'),
    _NavItem(icon: Icons.workspace_premium,       label: 'Certificates',   sub: 'Download & Verify',                      route: '/certificates'),
    _NavItem(icon: Icons.school_outlined,         label: 'Browse Courses', sub: 'Find PE and CE courses',                 route: '/courses'),
  ];

  static const _settings = [
    _NavItem(icon: Icons.person_outline,          label: 'My Profile',     sub: 'Personal info & preferences',            route: '/profile'),
    _NavItem(icon: Icons.tune_outlined,           label: 'Account Setup',  sub: 'NMLS ID, license goals & notifications', route: '/account-setup'),
    _NavItem(icon: Icons.shopping_cart_outlined,  label: 'My Orders',      sub: 'Purchase History & Receipts',            route: '/orders'),
    _NavItem(icon: Icons.help_outline,            label: 'Contact Support',sub: 'Get Help from RELS NMLS',                route: '/support'),
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
          _buildDrawer(),
          if (_showLogoutConfirm) _buildLogoutDialog(),
        ],
      );

  Widget _buildDrawer() => Container(
        width: 300,
        color: kWhite,
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(color: kBlue, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(_initials,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kDark)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userName.isEmpty ? 'Student' : widget.userName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kDark),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(_studentId,
                            style: const TextStyle(fontSize: 12, color: kBlue, letterSpacing: 0.3)),
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
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 11,
                color: kMuted, letterSpacing: 0.07 * 11)),
      );

  Widget _buildLogoutDialog() => Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showLogoutConfirm = false),
                child: Container(color: kDark.withOpacity(0.55)),
              ),
              Center(
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 26),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(
                        color: kDark.withOpacity(0.20), blurRadius: 70, offset: const Offset(0, 28))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: kRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kRed.withOpacity(0.18)),
                        ),
                        child: const Icon(Icons.logout, color: kRed, size: 22),
                      ),
                      const SizedBox(height: 16),
                      const Text('Sign out?',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: kDark)),
                      const SizedBox(height: 8),
                      Text('Are you sure you want to sign out of your account?',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: kDark.withOpacity(0.52))),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _showLogoutConfirm = false),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: kDark.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kDark.withOpacity(0.10)),
                                ),
                                alignment: Alignment.center,
                                child: Text('No, stay',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                                        color: kDark.withOpacity(0.72))),
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
                                  color: kRed.withOpacity(0.90),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Text('Yes, sign out',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kWhite)),
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
                      style: TextStyle(
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                          color: item.danger ? kRed : kDark)),
                  const SizedBox(height: 2),
                  Text(item.sub,
                      style: const TextStyle(fontSize: 11, color: kMuted),
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
// PROFILE PAGE
// ═══════════════════════════════════════════════════════════════════
enum ProfileSection { personal, password, notifications, license, payment, orders }

extension ProfileSectionExt on ProfileSection {
  String get label => const {
    ProfileSection.personal:      'Personal Info',
    ProfileSection.password:      'Change Password',
    ProfileSection.notifications: 'Notifications',
    ProfileSection.license:       'License Goals',
    ProfileSection.payment:       'Payment Methods',
    ProfileSection.orders:        'Order History',
  }[this]!;

  IconData get icon => const {
    ProfileSection.personal:      Icons.person_outline_rounded,
    ProfileSection.password:      Icons.lock_outline_rounded,
    ProfileSection.notifications: Icons.notifications_none_rounded,
    ProfileSection.license:       Icons.check_circle_outline_rounded,
    ProfileSection.payment:       Icons.credit_card_rounded,
    ProfileSection.orders:        Icons.receipt_long_outlined,
  }[this]!;
}

class ProfilePage extends StatefulWidget {
  final String userName, userEmail, nmlsId;
  const ProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.nmlsId,
  });
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileSection _active = ProfileSection.personal;
  String? _toastMsg;
  bool _toastError = false;

  void _showToast(String msg, {bool error = false}) {
    setState(() { _toastMsg = msg; _toastError = error; });
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _toastMsg = null);
    });
  }

 @override
Widget build(BuildContext context) {
  final wide = MediaQuery.of(context).size.width > 768;
  return Scaffold(                    // ← ADD
    backgroundColor: kBg,            // ← ADD
    body: Stack(                      // ← was: return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 28 : 14,
              vertical: wide ? 24 : 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACCOUNT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kBlue, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                const Text('Profile & Settings',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kDark, letterSpacing: -0.4)),
                const SizedBox(height: 20),
                wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 256,
                            child: _ProfileSidebar(
                              active:    _active,
                              onSelect:  (s) => setState(() => _active = s),
                              userName:  widget.userName,
                              userEmail: widget.userEmail,
                              nmlsId:    widget.nmlsId,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _ProfileContent(
                              section:   _active,
                              onToast:   _showToast,
                              userName:  widget.userName,
                              userEmail: widget.userEmail,
                              nmlsId:    widget.nmlsId,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _ProfileContent(
                            section:   _active,
                            onToast:   _showToast,
                            userName:  widget.userName,
                            userEmail: widget.userEmail,
                            nmlsId:    widget.nmlsId,
                          ),
                          const SizedBox(height: 20),
                          _ProfileSidebar(
                            active:    _active,
                            onSelect:  (s) => setState(() => _active = s),
                            userName:  widget.userName,
                            userEmail: widget.userEmail,
                            nmlsId:    widget.nmlsId,
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
        if (_toastMsg != null)
          _Toast(msg: _toastMsg!, error: _toastError, onClose: () => setState(() => _toastMsg = null)),
      ],
    ),                                // ← close Stack
  );                                  // ← close Scaffold
}
}

// ─── Profile inner sidebar (avatar card + section nav) ────────────
class _ProfileSidebar extends StatelessWidget {
  final ProfileSection active;
  final ValueChanged<ProfileSection> onSelect;
  final String userName, userEmail, nmlsId;
  const _ProfileSidebar({
    required this.active, required this.onSelect,
    required this.userName, required this.userEmail, required this.nmlsId,
  });

  String get _initials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return 'AC';
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Avatar card
          _Card(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [kBlue, kTeal],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(_initials,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kWhite)),
                ),
                const SizedBox(height: 12),
                Text(userName,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kDark)),
                const SizedBox(height: 4),
                Text(userEmail,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted)),
                const SizedBox(height: 8),
                if (nmlsId.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x1A2EABFE),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x382EABFE)),
                    ),
                    child: Text('NMLS #$nmlsId',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kBlue)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Section nav
          _Card(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: ProfileSection.values
                  .map((s) => _ProfileNavBtn(section: s, isActive: s == active, onTap: () => onSelect(s)))
                  .toList(),
            ),
          ),
        ],
      );
}

class _ProfileNavBtn extends StatefulWidget {
  final ProfileSection section;
  final bool isActive;
  final VoidCallback onTap;
  const _ProfileNavBtn({required this.section, required this.isActive, required this.onTap});
  @override
  State<_ProfileNavBtn> createState() => _ProfileNavBtnState();
}

class _ProfileNavBtnState extends State<_ProfileNavBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: widget.isActive
                  ? const Color(0x142EABFE)
                  : _hover ? const Color(0x08020817) : Colors.transparent,
              border: Border.all(
                  color: widget.isActive ? const Color(0x2E2EABFE) : Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(widget.section.icon, size: 15,
                    color: widget.isActive ? kDark : kTextMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.section.label,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: widget.isActive ? kDark : kTextMuted)),
                ),
                Icon(Icons.chevron_right_rounded, size: 14,
                    color: kTextMuted.withOpacity(0.45)),
              ],
            ),
          ),
        ),
      );
}

// ─── Profile content router ───────────────────────────────────────
class _ProfileContent extends StatelessWidget {
  final ProfileSection section;
  final Function(String, {bool error}) onToast;
  final String userName, userEmail, nmlsId;
  const _ProfileContent({
    required this.section, required this.onToast,
    required this.userName, required this.userEmail, required this.nmlsId,
  });

  @override
  Widget build(BuildContext context) => switch (section) {
    ProfileSection.personal      => _PersonalInfo(userName: userName, userEmail: userEmail, nmlsId: nmlsId, onToast: onToast),
    ProfileSection.password      => _ChangePassword(onToast: onToast),
    ProfileSection.notifications => _Notifications(onToast: onToast),
    ProfileSection.license       => _LicenseGoals(onToast: onToast),
    ProfileSection.payment       => const _PaymentMethods(),
    ProfileSection.orders        => const _OrderHistory(),
  };
}

// ═══════════════════════════════════════════════════════════════════
// SECTION: Personal Info
// ═══════════════════════════════════════════════════════════════════
class _PersonalInfo extends StatefulWidget {
  final String userName, userEmail, nmlsId;
  final Function(String, {bool error}) onToast;
  const _PersonalInfo({required this.userName, required this.userEmail, required this.nmlsId, required this.onToast});
  @override
  State<_PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<_PersonalInfo> {
  late final TextEditingController _name, _email, _phone, _address, _nmlsId;
  String _state = 'CA';
  bool _saving  = false;

  static const _states = [
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA',
    'KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
    'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT',
    'VA','WA','WV','WI','WY',
  ];

  @override
  void initState() {
    super.initState();
    _name    = TextEditingController(text: widget.userName);
    _email   = TextEditingController(text: widget.userEmail);
    _phone   = TextEditingController();
    _address = TextEditingController();
    _nmlsId  = TextEditingController(text: widget.nmlsId);
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _address, _nmlsId]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SectionCard(
        title: 'Personal Information',
        subtitle: 'Update your name, contact details, and address',
        child: Column(
          children: [
            _TwoCol(
              left:  _LabeledField(label: 'Full Name', required: true,
                child: _InputField(ctrl: _name, icon: Icons.person_outline_rounded, placeholder: 'Your full name')),
              right: _LabeledField(label: 'Email Address', required: true,
                hint: 'Email address cannot be changed',
                child: _InputField(ctrl: _email, icon: Icons.mail_outline_rounded,
                    placeholder: 'name@email.com', readOnly: true)),
            ),
            const SizedBox(height: 14),
            _TwoCol(
              left:  _LabeledField(label: 'Phone Number',
                child: _InputField(ctrl: _phone, icon: Icons.phone_outlined, placeholder: '+1 (555) 000-0000')),
              right: _LabeledField(label: 'NMLS ID',
                child: _InputField(ctrl: _nmlsId, icon: Icons.badge_outlined, placeholder: 'Your NMLS ID')),
            ),
            const SizedBox(height: 14),
            _LabeledField(label: 'Street Address',
              child: _InputField(ctrl: _address, icon: Icons.location_on_outlined, placeholder: '123 Main St, City, State')),
            const SizedBox(height: 14),
            _LabeledField(label: 'State',
              child: _DropdownField<String>(
                value: _state,
                icon: Icons.location_on_outlined,
                items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _state = v!),
              ),
            ),
            const SizedBox(height: 20),
            _FormFooter(
              label: _saving ? 'Saving…' : 'Save Changes',
              saving: _saving,
              onTap: () async {
                setState(() => _saving = true);
                await Future.delayed(const Duration(seconds: 1));
                setState(() => _saving = false);
                widget.onToast('Profile updated successfully!');
              },
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
// SECTION: Change Password
// ═══════════════════════════════════════════════════════════════════
class _ChangePassword extends StatefulWidget {
  final Function(String, {bool error}) onToast;
  const _ChangePassword({required this.onToast});
  @override
  State<_ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<_ChangePassword> {
  final _current = TextEditingController();
  final _newPw   = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCur = false, _showNew = false, _showConf = false;
  bool _saving  = false;

  String get _strength => _newPw.text.length < 6 ? 'weak' : _newPw.text.length < 10 ? 'good' : 'strong';
  Color  get _strengthColor => {'weak': kRed, 'good': const Color(0xFFF59E0B), 'strong': const Color(0xFF22C55E)}[_strength]!;
  double get _strengthWidth => {'weak': 0.28, 'good': 0.62, 'strong': 1.0}[_strength]!;

  @override
  Widget build(BuildContext context) => _SectionCard(
        title: 'Change Password',
        subtitle: 'Keep your account secure with a strong password',
        child: Column(
          children: [
            _LabeledField(label: 'Current Password', required: true,
              child: _InputField(ctrl: _current, icon: Icons.lock_outline_rounded,
                  placeholder: 'Your current password', obscure: !_showCur,
                  suffix: _EyeBtn(show: _showCur, onTap: () => setState(() => _showCur = !_showCur)))),
            const SizedBox(height: 14),
            _LabeledField(label: 'New Password', required: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _InputField(ctrl: _newPw, icon: Icons.lock_outline_rounded,
                    placeholder: 'At least 8 characters', obscure: !_showNew,
                    suffix: _EyeBtn(show: _showNew, onTap: () => setState(() => _showNew = !_showNew)),
                    onChanged: (_) => setState(() {})),
                if (_newPw.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _strengthWidth, minHeight: 4,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation(_strengthColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${_strength[0].toUpperCase()}${_strength.substring(1)} password',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _strengthColor)),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            _LabeledField(label: 'Confirm New Password', required: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _InputField(ctrl: _confirm, icon: Icons.lock_outline_rounded,
                    placeholder: 'Repeat new password', obscure: !_showConf,
                    suffix: _EyeBtn(show: _showConf, onTap: () => setState(() => _showConf = !_showConf)),
                    onChanged: (_) => setState(() {})),
                if (_confirm.text.isNotEmpty && _newPw.text != _confirm.text)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text("Passwords don't match",
                        style: TextStyle(fontSize: 11, color: kRed, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
            const SizedBox(height: 20),
            _FormFooter(
              label: _saving ? 'Saving…' : 'Update Password',
              saving: _saving,
              onTap: () async {
                if (_newPw.text != _confirm.text) { widget.onToast('Passwords do not match', error: true); return; }
                if (_newPw.text.length < 8) { widget.onToast('Password must be at least 8 characters', error: true); return; }
                setState(() => _saving = true);
                await Future.delayed(const Duration(seconds: 1));
                setState(() { _saving = false; _current.clear(); _newPw.clear(); _confirm.clear(); });
                widget.onToast('Password changed successfully!');
              },
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
// SECTION: Notifications
// ═══════════════════════════════════════════════════════════════════
class _Notifications extends StatefulWidget {
  final Function(String, {bool error}) onToast;
  const _Notifications({required this.onToast});
  @override
  State<_Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<_Notifications> {
  final Map<String, bool> _prefs = {
    'email_course_updates': true,  'sms_course_updates': false,
    'email_reminders':      true,  'sms_reminders':      true,
    'email_completions':    true,  'sms_completions':    false,
    'email_promotions':     false, 'sms_promotions':     false,
  };

  static const _rows = [
    {'key': 'course_updates', 'label': 'Course Updates',     'sub': 'New content, module releases'},
    {'key': 'reminders',      'label': 'Learning Reminders', 'sub': 'Nudges to keep you on track'},
    {'key': 'completions',    'label': 'Completion Alerts',  'sub': 'Certificate and progress updates'},
    {'key': 'promotions',     'label': 'Promotions & Offers','sub': 'Discounts and new course announcements'},
  ];

  @override
  Widget build(BuildContext context) => _SectionCard(
        title: 'Notification Preferences',
        subtitle: 'Choose how and when we contact you',
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Expanded(child: SizedBox()),
                  _ColLabel(icon: Icons.mail_outline_rounded, label: 'Email'),
                  const SizedBox(width: 12),
                  _ColLabel(icon: Icons.phone_outlined, label: 'SMS'),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: _rows.asMap().entries.map((e) {
                  final i = e.key; final row = e.value;
                  return Column(children: [
                    if (i > 0) const Divider(height: 1, color: Color(0x0A020817)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(row['label']!,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xD9091925))),
                          const SizedBox(height: 2),
                          Text(row['sub']!,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextMuted)),
                        ])),
                        _Toggle(
                          on: _prefs['email_${row['key']}']!,
                          onChange: () => setState(() => _prefs['email_${row['key']}'] = !_prefs['email_${row['key']}']!),
                        ),
                        const SizedBox(width: 24),
                        _Toggle(
                          on: _prefs['sms_${row['key']}']!,
                          onChange: () => setState(() => _prefs['sms_${row['key']}'] = !_prefs['sms_${row['key']}']!),
                        ),
                      ]),
                    ),
                  ]);
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            _FormFooter(
              label: 'Save Preferences',
              saving: false,
              onTap: () => widget.onToast('Notification preferences saved!'),
            ),
          ],
        ),
      );
}

class _ColLabel extends StatelessWidget {
  final IconData icon; final String label;
  const _ColLabel({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 64,
        child: Column(children: [
          Icon(icon, size: 13, color: kTextMuted), const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kTextMuted)),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════
// SECTION: License Goals
// ═══════════════════════════════════════════════════════════════════
class _LicenseGoals extends StatefulWidget {
  final Function(String, {bool error}) onToast;
  const _LicenseGoals({required this.onToast});
  @override
  State<_LicenseGoals> createState() => _LicenseGoalsState();
}

class _LicenseGoalsState extends State<_LicenseGoals> {
  String _licenseType = '', _targetState = '', _experience = '';
  bool _saving = false;

  static const _states = [
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA',
    'KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
    'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT',
    'VA','WA','WV','WI','WY',
  ];

  @override
  Widget build(BuildContext context) => _SectionCard(
        title: 'License Goals',
        subtitle: 'Tell us your goals so we can recommend the right courses',
        child: Column(
          children: [
            _LabeledField(label: 'License Type',
              child: _DropdownField<String>(
                value: _licenseType.isEmpty ? null : _licenseType,
                icon: Icons.school_outlined, hint: 'Select license type',
                items: const [
                  DropdownMenuItem(value: 'new',     child: Text('New License (20hr PE)')),
                  DropdownMenuItem(value: 'renewal', child: Text('Annual Renewal (CE)')),
                  DropdownMenuItem(value: 'both',    child: Text('Both PE and CE')),
                ],
                onChanged: (v) => setState(() => _licenseType = v ?? ''),
              ),
            ),
            const SizedBox(height: 14),
            _TwoCol(
              left: _LabeledField(label: 'Target State',
                child: _DropdownField<String>(
                  value: _targetState.isEmpty ? null : _targetState,
                  icon: Icons.location_on_outlined, hint: 'Select state',
                  items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _targetState = v ?? ''),
                ),
              ),
              right: _LabeledField(label: 'Experience Level',
                child: _DropdownField<String>(
                  value: _experience.isEmpty ? null : _experience,
                  icon: Icons.workspace_premium_outlined, hint: 'Select level',
                  items: const [
                    DropdownMenuItem(value: 'none',        child: Text('No experience')),
                    DropdownMenuItem(value: 'some',        child: Text('< 2 years')),
                    DropdownMenuItem(value: 'experienced', child: Text('2+ years')),
                    DropdownMenuItem(value: 'renewing',    child: Text('Renewing CE')),
                  ],
                  onChanged: (v) => setState(() => _experience = v ?? ''),
                ),
              ),
            ),
            if (_licenseType.isNotEmpty || _targetState.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0x072EABFE), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x332EABFE)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('📋 Your Learning Path',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xCC091925))),
                  const SizedBox(height: 10),
                  if (_licenseType == 'new' || _licenseType == 'both')
                    _GoalItem(icon: Icons.check_circle_outline_rounded, color: const Color(0xFF22C55E), text: '20-Hour SAFE Act Pre-License Course'),
                  if (_licenseType == 'renewal' || _licenseType == 'both')
                    _GoalItem(icon: Icons.check_circle_outline_rounded, color: const Color(0xFF22C55E), text: '8-Hour Annual CE Course'),
                  if (_targetState.isNotEmpty)
                    _GoalItem(icon: Icons.location_on_outlined, color: kBlue, text: 'State: $_targetState'),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            _FormFooter(
              label: _saving ? 'Saving…' : 'Save Goals',
              saving: _saving,
              onTap: () async {
                setState(() => _saving = true);
                await Future.delayed(const Duration(seconds: 1));
                setState(() => _saving = false);
                widget.onToast('License goals updated!');
              },
            ),
          ],
        ),
      );
}

class _GoalItem extends StatelessWidget {
  final IconData icon; final Color color; final String text;
  const _GoalItem({required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, size: 13, color: color), const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xBF091925))),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════
// SECTION: Payment Methods
// ═══════════════════════════════════════════════════════════════════
class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods();
  @override
  Widget build(BuildContext context) => _SectionCard(
        title: 'Payment Methods',
        subtitle: 'Manage your saved payment methods',
        child: _EmptyState(
          icon: Icons.credit_card_rounded,
          title: 'No saved payment methods',
          subtitle: 'Payment methods are saved securely via Authorize.net when you complete a purchase.',
          extra: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF22C55E)),
            const SizedBox(width: 8),
            const Flexible(child: Text(
              'All payments processed securely through Authorize.net.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xD915803D)),
            )),
          ]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
// SECTION: Order History
// ═══════════════════════════════════════════════════════════════════
class _OrderHistory extends StatelessWidget {
  const _OrderHistory();
  @override
  Widget build(BuildContext context) => _SectionCard(
        title: 'Order History',
        subtitle: 'Your purchases and payment receipts',
        child: _EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No orders yet',
          subtitle: 'When you purchase courses, your orders will appear here.',
          extra: _PillButton(label: 'Browse Courses', icon: Icons.chevron_right_rounded, onTap: () {}),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
// SHARED ATOMS
// ═══════════════════════════════════════════════════════════════════
class _Card extends StatelessWidget {
  final Widget child; final EdgeInsets padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity, padding: padding,
        decoration: BoxDecoration(
          color: kCardBg, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: child,
      );
}

class _SectionCard extends StatelessWidget {
  final String title; final String? subtitle; final Widget child;
  const _SectionCard({required this.title, this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: kCardBg, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
        ),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0x0F020817)))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: kDark)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextMuted)),
              ],
            ]),
          ),
          Padding(padding: const EdgeInsets.all(24), child: child),
        ]),
      );
}

class _LabeledField extends StatelessWidget {
  final String label; final bool required; final Widget child; final String? hint;
  const _LabeledField({required this.label, required this.child, this.required = false, this.hint});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextMuted)),
            if (required) const Text(' *', style: TextStyle(fontSize: 12, color: kRed)),
          ]),
          const SizedBox(height: 7),
          child,
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(hint!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0x6B091925))),
          ],
        ],
      );
}

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final IconData icon;
  final String placeholder;
  final bool readOnly, obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  const _InputField({
    required this.ctrl, required this.icon, required this.placeholder,
    this.readOnly = false, this.obscure = false, this.suffix, this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(children: [
          Padding(padding: const EdgeInsets.only(left: 12),
              child: Icon(icon, size: 15, color: kTextMuted)),
          Expanded(
            child: TextField(
              controller: ctrl, readOnly: readOnly, obscureText: obscure, onChanged: onChanged,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: readOnly ? kTextMuted : kDark),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0x60091925)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ]),
      );
}

class _DropdownField<T> extends StatelessWidget {
  final T? value; final IconData icon; final String? hint;
  final List<DropdownMenuItem<T>> items; final ValueChanged<T?> onChanged;
  const _DropdownField({this.value, required this.icon, required this.items, required this.onChanged, this.hint});
  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.only(left: 12, right: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(children: [
          Icon(icon, size: 15, color: kTextMuted), const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<T>(
              value: value,
              hint: hint != null
                  ? Text(hint!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0x60091925)))
                  : null,
              items: items, onChanged: onChanged, isExpanded: true,
              underline: const SizedBox(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kDark, fontFamily: 'Poppins'),
              dropdownColor: kCardBg, borderRadius: BorderRadius.circular(12),
            ),
          ),
        ]),
      );
}

class _EyeBtn extends StatelessWidget {
  final bool show; final VoidCallback onTap;
  const _EyeBtn({required this.show, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.only(right: 10),
            child: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 15, color: kTextMuted)),
      );
}

class _TwoCol extends StatelessWidget {
  final Widget left, right;
  const _TwoCol({required this.left, required this.right});
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 600;
    return wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: left), const SizedBox(width: 14), Expanded(child: right),
          ])
        : Column(children: [left, const SizedBox(height: 14), right]);
  }
}

class _Toggle extends StatelessWidget {
  final bool on; final VoidCallback onChange;
  const _Toggle({required this.on, required this.onChange});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onChange,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40, height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: on ? kBlue : const Color(0xFFE2E8F0),
          ),
          child: Stack(children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: 3, left: on ? 21 : 3,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: kWhite,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 4)],
                ),
              ),
            ),
          ]),
        ),
      );
}

class _FormFooter extends StatelessWidget {
  final String label; final VoidCallback onTap; final bool saving;
  const _FormFooter({required this.label, required this.onTap, required this.saving});
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: _PillButton(label: label, icon: Icons.save_outlined, onTap: saving ? () {} : onTap),
      );
}

class _PillButton extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap; final bool dark;
  const _PillButton({required this.label, required this.icon, required this.onTap, this.dark = true});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: dark ? kDark : kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: dark ? null : Border.all(color: kBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: dark ? kWhite : kDark), const SizedBox(width: 7),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                color: dark ? kWhite : kDark)),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String title, subtitle; final Widget? extra;
  const _EmptyState({required this.icon, required this.title, required this.subtitle, this.extra});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(children: [
          Icon(icon, size: 32, color: const Color(0x40091925)),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xCC091925))),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextMuted)),
          if (extra != null) ...[const SizedBox(height: 16), extra!],
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════
// TOAST
// ═══════════════════════════════════════════════════════════════════
class _Toast extends StatelessWidget {
  final String msg; final bool error; final VoidCallback onClose;
  const _Toast({required this.msg, required this.error, required this.onClose});
  @override
  Widget build(BuildContext context) => Positioned(
        bottom: 24, right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: error ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: error ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
              boxShadow: [BoxShadow(
                  color: const Color(0x1F020817), blurRadius: 28, offset: const Offset(0, 8))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  size: 16, color: error ? const Color(0xFFB91C1C) : const Color(0xFF15803D)),
              const SizedBox(width: 10),
              Flexible(child: Text(msg, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                  color: error ? const Color(0xFFB91C1C) : const Color(0xFF15803D)))),
              const SizedBox(width: 4),
              GestureDetector(onTap: onClose,
                  child: Icon(Icons.close_rounded, size: 14,
                      color: error ? const Color(0xFFB91C1C) : const Color(0xFF15803D))),
            ]),
          ),
        ),
      );
}