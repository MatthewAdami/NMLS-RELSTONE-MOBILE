import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/config/api_config.dart';

// ─── Theme constants (shared with dashboard_screen.dart) ──────────────
const kDark = Color(0xFF091925);
const kBlue = Color(0xFF2EABFE);
const kBlueFaint = Color(0x1A2EABFE);
const kBlueBorder = Color(0x382EABFE);
const kTeal = Color(0xFF00B4B4);
const kTealFaint = Color(0x1A00B4B4);
const kTealBorder = Color(0x3300B4B4);
const kBg = Color(0xFFF6F7FB);
const kWhite = Colors.white;
const kTextColor = Color(0xEB0B1220);
const kMuted = Color(0x990B1220);
const kBorder = Color(0x1A020817);
const kSurface = Color(0xD0FFFFFF);

// ─── API base URL pulled from your shared ApiConfig ──────────────────
// Import your config file, e.g.:
// import 'package:your_app/config/api_config.dart';
//
// Then replace _kApiBase usage with ApiConfig.baseUrl + ApiConfig.apiPrefix
String get _kApiBase => '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}';

// ─── US States list ───────────────────────────────────────────────────
const _kUsStates = [
  'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
  'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
  'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
  'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
  'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
];

// ─── Courses Screen ───────────────────────────────────────────────────
class CoursesScreen extends StatefulWidget {
  final String? token;
  const CoursesScreen({Key? key, this.token}) : super(key: key);

  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  // Data
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;
  String _error = '';

  // Filters
  final TextEditingController _searchCtrl = TextEditingController();
  String _typeFilter = '';
  String _stateFilter = '';
  String _query = '';

  // Cart
  List<Map<String, dynamic>> _cart = [];
  bool _drawerOpen = false;
  bool _orderSuccess = false;
  bool _ordering = false;

  // Expanded modules
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── API ────────────────────────────────────────────────────────────
  Future<void> _fetchCourses() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final params = <String, String>{};
      if (_typeFilter.isNotEmpty) params['type'] = _typeFilter;
      if (_stateFilter.isNotEmpty) params['state'] = _stateFilter;

      final uri = Uri.parse('$_kApiBase/courses').replace(queryParameters: params);
      final res = await http.get(uri, headers: _headers);

      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _courses = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          });
        }
      } else {
        setState(() => _error = 'Failed to load courses (${res.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Network error. Please retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty || !mounted) return;
    setState(() => _ordering = true);
    try {
      final items = _cart.map((c) => {
        'course_id': c['_id'],
        'include_textbook': c['include_textbook'] ?? false,
      }).toList();

      final res = await http.post(
        Uri.parse('$_kApiBase/orders'),
        headers: _headers,
        body: jsonEncode({'items': items}),
      );

      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() { _cart = []; _drawerOpen = false; _orderSuccess = true; });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _orderSuccess = false);
        });
      } else {
        final body = jsonDecode(res.body);
        if (mounted) _snack(body['message'] ?? 'Checkout failed');
      }
    } catch (e) {
      if (mounted) _snack('Network error. Please retry.');
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
  };

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFC0392B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Computed ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return _courses;
    final needle = _query.toLowerCase();
    return _courses.where((c) {
      final title  = (c['title']       as String? ?? '').toLowerCase();
      final desc   = (c['description'] as String? ?? '').toLowerCase();
      final states = (c['states_approved'] as List?)?.join(',').toLowerCase() ?? '';
      return title.contains(needle) || desc.contains(needle) || states.contains(needle);
    }).toList();
  }

  bool _inCart(String id) => _cart.any((c) => c['_id'] == id);

  double get _total => _cart.fold(0.0, (s, c) =>
      s + _num(c['price']) + (c['include_textbook'] == true ? _num(c['textbook_price']) : 0.0));

  double _num(dynamic v) => v is num ? v.toDouble() : 0.0;

  // ── Cart helpers ───────────────────────────────────────────────────
  void _addToCart(Map<String, dynamic> course) {
    if (_inCart(course['_id'] as String)) return;
    setState(() { _cart = [..._cart, {...course, 'include_textbook': false}]; _drawerOpen = true; });
  }

  void _removeFromCart(String id) =>
      setState(() => _cart = _cart.where((c) => c['_id'] != id).toList());

  void _toggleTextbook(String id) {
    setState(() {
      _cart = _cart.map((c) => c['_id'] == id
          ? {...c, 'include_textbook': !(c['include_textbook'] as bool)}
          : c).toList();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [
        SafeArea(
          child: Column(children: [
            _buildTopBar(),
            _buildFiltersBar(),
            Expanded(child: _buildBody()),
          ]),
        ),

        // Toast
        if (_orderSuccess)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16, right: 16,
            child: _SuccessToast(onClose: () => setState(() => _orderSuccess = false)),
          ),

        // Dim overlay
        if (_drawerOpen)
          GestureDetector(
            onTap: () => setState(() => _drawerOpen = false),
            child: Container(color: Colors.black.withOpacity(0.42)),
          ),

        // Slide-in cart
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          top: 0, bottom: 0,
          right: _drawerOpen ? 0 : -340,
          width: 320,
          child: SafeArea(child: _buildCartDrawer()),
        ),
      ]),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // ← Dashboard
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
                color: kWhite,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(99)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.arrow_back_rounded, size: 15, color: kDark),
              SizedBox(width: 6),
              Text('Dashboard',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kDark)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Course Catalog',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                    color: kDark, letterSpacing: -0.2)),
            Text('Browse NMLS-approved PE and CE courses',
                style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w700)),
          ]),
        ),
        // Cart button
        GestureDetector(
          onTap: () => setState(() => _drawerOpen = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
                color: kWhite,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10, offset: const Offset(0, 3))]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.shopping_cart_outlined, size: 16, color: kDark),
              const SizedBox(width: 6),
              const Text('Cart',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kDark)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: kBlueFaint,
                    border: Border.all(color: kBlueBorder),
                    borderRadius: BorderRadius.circular(99)),
                child: Text('${_cart.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kDark)),
              ),
              if (_cart.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: kDark, borderRadius: BorderRadius.circular(99)),
                  child: Text('\$${_total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kWhite)),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Filters bar ────────────────────────────────────────────────────
  Widget _buildFiltersBar() {
    final hasFilter = _typeFilter.isNotEmpty || _stateFilter.isNotEmpty || _query.isNotEmpty;

    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Search box
        Container(
          decoration: BoxDecoration(
              color: kWhite,
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(99)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          child: Row(children: [
            const Icon(Icons.search_rounded, size: 16, color: kMuted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextColor),
                decoration: const InputDecoration(
                  hintText: 'Search courses, description, states…',
                  hintStyle: TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.w600),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
                child: const Icon(Icons.close_rounded, size: 16, color: kMuted),
              ),
          ]),
        ),
        const SizedBox(height: 10),

        // Chip row (scrollable so it never overflows)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _FCChip(label: 'All',  active: _typeFilter == '', onTap: () { setState(() => _typeFilter = ''); _fetchCourses(); }),
            const SizedBox(width: 8),
            _FCChip(label: 'PE', active: _typeFilter == 'PE', tone: 'blue',
                onTap: () { setState(() => _typeFilter = 'PE'); _fetchCourses(); }),
            const SizedBox(width: 8),
            _FCChip(label: 'CE', active: _typeFilter == 'CE', tone: 'teal',
                onTap: () { setState(() => _typeFilter = 'CE'); _fetchCourses(); }),
            const SizedBox(width: 12),

            // State dropdown
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: _stateFilter.isNotEmpty ? kBlueFaint : kWhite,
                  border: Border.all(color: _stateFilter.isNotEmpty ? kBlueBorder : kBorder),
                  borderRadius: BorderRadius.circular(99)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _stateFilter.isEmpty ? null : _stateFilter,
                  hint: const Text('All States',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kMuted)),
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: kMuted),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kDark),
                  items: [
                    const DropdownMenuItem<String>(
                        value: '', child: Text('All States',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kMuted))),
                    ..._kUsStates.map((s) => DropdownMenuItem<String>(
                        value: s, child: Text(s,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kDark)))),
                  ],
                  onChanged: (v) { setState(() => _stateFilter = v ?? ''); _fetchCourses(); },
                ),
              ),
            ),

            if (hasFilter) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() { _query = ''; _typeFilter = ''; _stateFilter = ''; });
                  _fetchCourses();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                      color: kWhite, border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(99)),
                  child: const Text('Clear',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kMuted)),
                ),
              ),
            ],
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: kWhite, border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(99)),
              child: Text('${_filtered.length} courses',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kDark)),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 32, height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(kBlue))),
          SizedBox(height: 12),
          Text('Loading courses…',
              style: TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w700)),
        ]),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: const Color(0x1AC0392B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x38C0392B))),
              child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFC0392B), size: 22),
            ),
            const SizedBox(height: 12),
            Text(_error,
                style: const TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _fetchCourses,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(12)),
                child: const Text('Retry',
                    style: TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
          ]),
        ),
      );
    }

    final courses = _filtered;
    if (courses.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
                color: kBlueFaint, borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBlueBorder)),
            child: const Icon(Icons.search_off_rounded, color: kBlue, size: 22),
          ),
          const SizedBox(height: 12),
          const Text('No courses found',
              style: TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Try adjusting your filters or search.',
              style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w700)),
        ]),
      );
    }

    return RefreshIndicator(
      color: kBlue,
      onRefresh: _fetchCourses,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final course = courses[i];
          final id = course['_id'] as String? ?? i.toString();
          return _CourseCard(
            course: course,
            inCart: _inCart(id),
            isExpanded: _expanded.contains(id),
            onAddToCart: () => _addToCart(course),
            onToggleExpand: () => setState(() {
              _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
            }),
          );
        },
      ),
    );
  }

  // ── Cart drawer ────────────────────────────────────────────────────
  Widget _buildCartDrawer() {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(left: BorderSide(color: kBorder)),
        boxShadow: [BoxShadow(color: Color(0x2D020817), blurRadius: 40, offset: Offset(-10, 0))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
          child: Row(children: [
            const Icon(Icons.shopping_cart_outlined, size: 18, color: kDark),
            const SizedBox(width: 10),
            const Text('Your Cart',
                style: TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 15)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _drawerOpen = false),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: kWhite, border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.close_rounded, size: 16, color: kDark),
              ),
            ),
          ]),
        ),

        if (_cart.isEmpty)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Your cart is empty',
                      style: TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 14)),
                  SizedBox(height: 6),
                  Text('Add a course to checkout.',
                      style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          )
        else ...[
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _cart.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = _cart[i];
                final price = _num(c['price']);
                final tbPrice = _num(c['textbook_price']);
                final hasTextbook = c['has_textbook'] == true;
                final includeTb = c['include_textbook'] == true;
                final id = c['_id'] as String? ?? '';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: kWhite, border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Text(c['title'] as String? ?? 'Course',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kDark)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeFromCart(id),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              border: Border.all(color: kBorder),
                              borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.close_rounded, size: 14, color: kMuted),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text('\$${price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 13)),
                    if (hasTextbook) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _toggleTextbook(id),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 18, height: 18,
                            decoration: BoxDecoration(
                                color: includeTb ? kBlue : kWhite,
                                border: Border.all(color: includeTb ? kBlue : kBorder, width: 1.5),
                                borderRadius: BorderRadius.circular(5)),
                            child: includeTb
                                ? const Icon(Icons.check_rounded, size: 12, color: kWhite)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text('Add textbook (+\$${tbPrice.toStringAsFixed(2)})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
                        ]),
                      ),
                    ],
                  ]),
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.w700, color: kMuted, fontSize: 14)),
                Text('\$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 15)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _ordering ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: kWhite,
                      disabledBackgroundColor: kBlue.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: Text(_ordering ? 'Placing order…' : 'Checkout',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => _drawerOpen = false),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: kDark,
                      side: const BorderSide(color: kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Continue browsing',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ─── Course Card ──────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool inCart;
  final bool isExpanded;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleExpand;

  const _CourseCard({
    required this.course,
    required this.inCart,
    required this.isExpanded,
    required this.onAddToCart,
    required this.onToggleExpand,
  });

  double _num(dynamic v) => v is num ? v.toDouble() : 0.0;

  @override
  Widget build(BuildContext context) {
    final type       = (course['type'] as String? ?? '').toUpperCase();
    final isPE       = type == 'PE';
    final isCE       = type == 'CE';
    final title      = course['title']       as String? ?? 'Untitled';
    final desc       = course['description'] as String? ?? '';
    final creditHrs  = course['credit_hours'] ?? 0;
    final price      = _num(course['price']);
    final tbPrice    = _num(course['textbook_price']);
    final hasTextbook= course['has_textbook'] == true;
    final states     = (course['states_approved'] as List?)?.cast<String>() ?? [];
    final modules    = (course['modules']          as List?) ?? [];

    // Badge colours
    final Color badgeColor  = isPE ? kBlue  : isCE ? kTeal  : kMuted;
    final Color badgeBg     = isPE ? kBlueFaint  : isCE ? kTealFaint  : const Color(0x0F020817);
    final Color badgeBorder = isPE ? kBlueBorder : isCE ? kTealBorder : kBorder;

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Body ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Header row: icon | title+desc | badge
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: kBlueFaint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBlueBorder)),
                child: const Icon(Icons.menu_book_outlined, color: kDark, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900, color: kDark, height: 1.2)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(desc, style: const TextStyle(
                        fontSize: 12, color: kMuted, fontWeight: FontWeight.w600, height: 1.4),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ]),
              ),
              // ← The type badge is ALWAYS shown here
              if (type.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: badgeBorder)),
                  child: Text(type, style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900, color: badgeColor)),
                ),
              ],
            ]),
            const SizedBox(height: 12),

            // Meta chips
            Wrap(spacing: 8, runSpacing: 8, children: [
              _MetaChip(icon: Icons.access_time_outlined,
                  label: '$creditHrs credit hr${creditHrs == 1 ? '' : 's'}'),
              if (states.isNotEmpty)
                _MetaChip(
                  icon: Icons.location_on_outlined,
                  label: states.length > 4
                      ? '${states.take(4).join(', ')} +${states.length - 4}'
                      : states.join(', '),
                ),
            ]),

            // Modules expander
            if (modules.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onToggleExpand,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF6F7FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder)),
                  child: Row(children: [
                    Text('Modules (${modules.length})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kDark)),
                    const Spacer(),
                    Icon(isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                        size: 18, color: kMuted),
                  ]),
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 8),
                ...modules.map((m) {
                  final mod = Map<String, dynamic>.from(m as Map);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: kBlueFaint,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: kBlueBorder)),
                        child: Text('M${mod['order'] ?? ''}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kDark)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(mod['title'] as String? ?? '',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextColor))),
                    ]),
                  );
                }),
              ],
            ],
          ]),
        ),

        // ── Footer: price + Add button ────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                      color: kDark, letterSpacing: -0.3)),
              if (hasTextbook)
                Text('+ Textbook (\$${tbPrice.toStringAsFixed(2)})',
                    style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w700)),
            ]),
            GestureDetector(
              onTap: inCart ? null : onAddToCart,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                    color: inCart ? kTealFaint : kBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: inCart ? kTealBorder : kBlueBorder)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(inCart ? Icons.check_rounded : Icons.shopping_cart_outlined,
                      size: 15, color: inCart ? kTeal : kWhite),
                  const SizedBox(width: 6),
                  Text(inCart ? 'Added' : 'Add to Cart',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                          color: inCart ? kTeal : kWhite)),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Success Toast ────────────────────────────────────────────────────
class _SuccessToast extends StatelessWidget {
  final VoidCallback onClose;
  const _SuccessToast({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12),
              blurRadius: 24, offset: const Offset(0, 8))]),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: kTealFaint,
              border: Border.all(color: kTealBorder),
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.check_circle_outline_rounded, color: kTeal, size: 18),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Order placed successfully',
                style: TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 13)),
            SizedBox(height: 2),
            Text('Check your dashboard for your courses.',
                style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w700)),
          ]),
        ),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.close_rounded, size: 15, color: kMuted),
          ),
        ),
      ]),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────
class _FCChip extends StatelessWidget {
  final String label;
  final bool active;
  final String tone;
  final VoidCallback onTap;

  const _FCChip({
    required this.label,
    required this.active,
    this.tone = 'default',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, border, fg;
    if (active && tone == 'blue')       { bg = kBlueFaint; border = kBlueBorder; fg = kBlue; }
    else if (active && tone == 'teal')  { bg = kTealFaint; border = kTealBorder; fg = kTeal; }
    else if (active)                    { bg = kDark;       border = kDark;       fg = kWhite; }
    else                                { bg = kWhite;      border = kBorder;     fg = kMuted; }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: bg, border: Border.all(color: border),
            borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: fg)),
      ),
    );
  }
}

// ─── Meta Chip ────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: kBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: kMuted),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
      ]),
    );
  }
}