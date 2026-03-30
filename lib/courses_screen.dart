import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/widgets/app_side_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/api_config.dart';
import 'my_courses_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';

// ─── Theme ────────────────────────────────────────────────────────────
const _cDark       = Color(0xFF091925);
const _cBlue       = Color(0xFF2EABFE);
const _cBlueFaint  = Color(0x1A2EABFE);
const _cBlueBorder = Color(0x382EABFE);
const _cTeal       = Color(0xFF00B4B4);
const _cTealFaint  = Color(0x1A00B4B4);
const _cTealBorder = Color(0x3300B4B4);
const _cAmber      = Color(0xFFF59E0B);
const _cBg         = Color(0xFFF6F7FB);
const _cWhite      = Colors.white;
const _cMuted      = Color(0xFF7FA8C4);
const _cBorder     = Color(0x14020817);

class CoursesScreen extends StatefulWidget {
  final String? token;
  final String userName;
  final String userEmail;
  final String? nmlsId;

  const CoursesScreen({
    Key? key,
    this.token,
    this.userName = '',
    this.userEmail = '',
    this.nmlsId,
  }) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _searchCtrl  = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _token;
  String  _userName  = '';
  String  _userEmail = '';
  String  _nmlsId    = '';

  bool   _loading = true;
  String _error   = '';
  List<Map<String, dynamic>> _courses = [];

  // Cart
  List<Map<String, dynamic>> _cartItems = [];

  String _typeFilter  = 'All';
  String _stateFilter = 'All';
  String _search      = '';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Lifecycle ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text));
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = widget.token ?? prefs.getString('token');
    final userStr = prefs.getString('user');
    if (userStr != null) {
      try {
        final user = jsonDecode(userStr) as Map<String, dynamic>;
        _userName  = widget.userName.isNotEmpty  ? widget.userName  : (user['name']     as String? ?? '');
        _userEmail = widget.userEmail.isNotEmpty ? widget.userEmail : (user['email']    as String? ?? '');
        _nmlsId    = widget.nmlsId               ?? (user['nmls_id'] as String? ?? '');
      } catch (_) {}
    }
    await _loadCart();
    await _fetchCourses();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cart');
    if (raw != null) {
      setState(() {
        _cartItems = List<Map<String, dynamic>>.from(
            (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)));
      });
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart', jsonEncode(_cartItems));
  }

  Future<void> _fetchCourses() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/courses'), headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] is List)
                ? decoded['data'] as List
                : (decoded is Map && decoded['courses'] is List)
                    ? decoded['courses'] as List
                    : <dynamic>[];
        setState(() {
          _courses = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _error = 'Could not load courses (${res.statusCode}).'; });
      }
    } catch (e) {
      setState(() { _loading = false; _error = 'Network error: $e'; });
    }
  }

  // ── Cart helpers ──────────────────────────────────────────────────
  bool _isInCart(String? courseId) =>
      courseId != null && _cartItems.any((item) => item['_id'] == courseId);

  Future<void> _addToCart(Map<String, dynamic> course) async {
    final courseId = course['_id'] as String?;
    final title    = course['title'] as String? ?? 'Course';
    if (courseId == null) return;

    // Already in cart
    if (_isInCart(courseId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.info_outline_rounded, color: _cWhite, size: 16),
            SizedBox(width: 10),
            Text('Already in your cart!',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          backgroundColor: _cAmber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: _cWhite,
            onPressed: _openCart,
          ),
        ),
      );
      return;
    }

    // Add to local cart
    setState(() {
      _cartItems.add({
        '_id':              courseId,
        'title':            course['title'],
        'type':             course['type'],
        'credit_hours':     course['credit_hours'],
        'price':            course['price'],
        'has_textbook':     course['has_textbook'] ?? false,
        'textbook_price':   course['textbook_price'],
        'include_textbook': false,
      });
    });
    await _saveCart();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: _cWhite, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text('"$title" added to cart!',
                style: const TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ]),
        backgroundColor: const Color(0xFF15803D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: _cWhite,
          onPressed: _openCart,
        ),
      ),
    );
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CartScreen(token: _token)),
    ).then((_) => _loadCart());
  }

  // ── Filtered list ─────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    return _courses.where((c) {
      final type   = (c['type'] as String? ?? '').toUpperCase();
      final title  = (c['title'] as String? ?? '').toLowerCase();
      final states = ((c['states_approved'] as List?) ?? [])
          .map((s) => s.toString().toUpperCase())
          .toList();

      final matchType   = _typeFilter == 'All' || type == _typeFilter;
      final matchState  = _stateFilter == 'All' || states.contains(_stateFilter);
      final matchSearch = _search.trim().isEmpty || title.contains(_search.toLowerCase());

      return matchType && matchState && matchSearch;
    }).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _cBg,
      appBar: AppTopBar(
        scaffoldKey: _scaffoldKey,
        userName: _userName,
        nmlsId: _nmlsId.isNotEmpty ? _nmlsId : null,
      ),
      drawer: AppSidebar(
        userName: _userName,
        userEmail: _userEmail,
        nmlsId: _nmlsId.isNotEmpty ? _nmlsId : null,
        currentRoute: '/courses',
        onNavigate: (route) {
          Navigator.of(context).pop(); // close drawer
          if (route == '/dashboard') {
            Navigator.of(context).pop();
          } else if (route == '/my-courses') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MyCoursesScreen()),
            );
          } else if (route == '/orders') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrdersScreen(token: _token)),
            );
          }
        },
        onSignOut: () =>
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterRow(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _cBlue, strokeWidth: 2.5))
                : _error.isNotEmpty
                    ? _buildError()
                    : _filtered.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
          ),
        ],
      ),
    );
  }

  // ── Header with search + cart icon ────────────────────────────────
  Widget _buildHeader() => Container(
        color: _cDark,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MY LEARNING',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _cBlue,
                              letterSpacing: 0.8)),
                      Text('Browse Courses',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: _cWhite,
                              letterSpacing: -0.3)),
                    ],
                  ),
                ),
                // Cart icon with badge
                GestureDetector(
                  onTap: _openCart,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _cWhite.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _cWhite.withOpacity(0.15)),
                        ),
                        child: const Icon(Icons.shopping_cart_outlined,
                            color: _cWhite, size: 20),
                      ),
                      if (_cartItems.isNotEmpty)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                                color: _cBlue, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(
                              '${_cartItems.length}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _cWhite),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Search bar
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: _cWhite.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cWhite.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, color: Color(0xFF6B8397), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 13, color: _cWhite),
                      decoration: const InputDecoration(
                        hintText: 'Search courses…',
                        hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF6B8397)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_search.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.close_rounded,
                            color: Color(0xFF6B8397), size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Filter chips row ──────────────────────────────────────────────
  Widget _buildFilterRow() => Container(
        color: _cWhite,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _chip('All', _typeFilter == 'All', () => setState(() => _typeFilter = 'All')),
              _chip('PE',  _typeFilter == 'PE',  () => setState(() => _typeFilter = 'PE')),
              _chip('CE',  _typeFilter == 'CE',  () => setState(() => _typeFilter = 'CE')),
              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: _cBorder),
              const SizedBox(width: 12),
              _chip('All States', _stateFilter == 'All', () => setState(() => _stateFilter = 'All')),
              _chip('CA', _stateFilter == 'CA', () => setState(() => _stateFilter = 'CA')),
              _chip('TX', _stateFilter == 'TX', () => setState(() => _stateFilter = 'TX')),
              _chip('NY', _stateFilter == 'NY', () => setState(() => _stateFilter = 'NY')),
              _chip('FL', _stateFilter == 'FL', () => setState(() => _stateFilter = 'FL')),
            ],
          ),
        ),
      );

  Widget _chip(String label, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? _cBlue : _cWhite,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: active ? _cBlue : _cBorder),
          ),
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? _cWhite : _cMuted)),
        ),
      );

  // ── Course list ───────────────────────────────────────────────────
  Widget _buildList() => RefreshIndicator(
        color: _cBlue,
        onRefresh: _fetchCourses,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          itemCount: _filtered.length,
          itemBuilder: (ctx, i) => _CourseCard(
            course: _filtered[i],
            inCart: _isInCart(_filtered[i]['_id'] as String?),
            onTap: () {},
            onAddToCart: () => _addToCart(_filtered[i]),
            onViewCart: _openCart,
          ),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📚', style: TextStyle(fontSize: 42)),
              const SizedBox(height: 14),
              const Text('No courses found',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: _cDark)),
              const SizedBox(height: 6),
              const Text('Try adjusting your filters or search.',
                  style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 13, color: _cMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() {
                    _search      = '';
                    _typeFilter  = 'All';
                    _stateFilter = 'All';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: _cBlue, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Clear Filters',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _cWhite)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 44, color: _cMuted),
              const SizedBox(height: 12),
              Text(_error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 13, color: _cMuted)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _fetchCourses,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: _cBlue, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Retry',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _cWhite)),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Course Card ──────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool inCart;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onViewCart;

  const _CourseCard({
    required this.course,
    required this.inCart,
    required this.onTap,
    required this.onAddToCart,
    required this.onViewCart,
  });

  @override
  Widget build(BuildContext context) {
    final title     = course['title']        as String? ?? 'Untitled Course';
    final type      = (course['type']         as String? ?? '').toUpperCase();
    final hours     = (course['credit_hours'] as num?)?.toInt() ?? 0;
    final states    = ((course['states_approved'] as List?) ?? [])
        .map((s) => s.toString().toUpperCase())
        .toList();
    final stateText = states.isEmpty ? 'All States' : states.take(3).join(', ');
    final desc      = course['description']  as String? ?? '';
    final price     = (course['price']        as num?)?.toDouble() ?? 0;

    final Color accentColor   = type == 'PE' ? _cBlue  : type == 'CE' ? _cTeal  : _cAmber;
    final Color accentFaint   = type == 'PE' ? _cBlueFaint : type == 'CE' ? _cTealFaint : const Color(0x1AF59E0B);
    final Color accentBorder  = type == 'PE' ? _cBlueBorder : type == 'CE' ? _cTealBorder : const Color(0x38F59E0B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _cWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: inCart ? accentBorder : _cBorder,
              width: inCart ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accent bar
            Container(height: 4, color: accentColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: _cDark,
                            borderRadius: BorderRadius.circular(11)),
                        child: Icon(
                          type == 'CE'
                              ? Icons.schedule_outlined
                              : Icons.menu_book_outlined,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _badge(type, accentColor, accentFaint, accentBorder),
                            if (stateText.isNotEmpty)
                              _badge(stateText, _cMuted,
                                  _cMuted.withOpacity(0.10),
                                  _cMuted.withOpacity(0.20)),
                            if (inCart)
                              _badge('In Cart', _cBlue, _cBlueFaint,
                                  _cBlueBorder),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: _cDark,
                          height: 1.4)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: _cMuted,
                            height: 1.5)),
                  ],
                  const SizedBox(height: 12),
                  // Meta + action row
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined,
                          size: 13, color: _cMuted),
                      const SizedBox(width: 4),
                      Text('$hours credit hr${hours != 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _cMuted)),
                      const Spacer(),
                      // Enroll / In Cart button
                      GestureDetector(
                        onTap: inCart ? onViewCart : onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: inCart
                                ? _cBlueFaint
                                : _cDark,
                            borderRadius: BorderRadius.circular(10),
                            border: inCart
                                ? Border.all(color: _cBlueBorder)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (price > 0 && !inCart) ...[
                                Text(
                                  '\$${price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: _cWhite),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Icon(
                                inCart
                                    ? Icons.shopping_cart_rounded
                                    : Icons.shopping_cart_outlined,
                                size: 13,
                                color: _cBlue,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                inCart ? 'View Cart' : 'Enroll',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: _cBlue),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, Color bg, Color border) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: border),
        ),
        child: Text(
          label.isEmpty ? '—' : label,
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color),
        ),
      );
}