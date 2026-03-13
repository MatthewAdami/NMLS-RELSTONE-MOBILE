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
  'AL',
  'AK',
  'AZ',
  'AR',
  'CA',
  'CO',
  'CT',
  'DE',
  'FL',
  'GA',
  'HI',
  'ID',
  'IL',
  'IN',
  'IA',
  'KS',
  'KY',
  'LA',
  'ME',
  'MD',
  'MA',
  'MI',
  'MN',
  'MS',
  'MO',
  'MT',
  'NE',
  'NV',
  'NH',
  'NJ',
  'NM',
  'NY',
  'NC',
  'ND',
  'OH',
  'OK',
  'OR',
  'PA',
  'RI',
  'SC',
  'SD',
  'TN',
  'TX',
  'UT',
  'VT',
  'VA',
  'WA',
  'WV',
  'WI',
  'WY',
];

// ─── Courses Screen ───────────────────────────────────────────────────
class CoursesScreen extends StatefulWidget {
  final String? token;
  const CoursesScreen({super.key, this.token});

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
  String _query = '';
  String _stateFilter = 'All';
  String _courseTypeFilter = 'All';
  String _formatFilter = 'All';
  RangeValues _priceRange = const RangeValues(0, 250);
  RangeValues _durationRange = const RangeValues(1, 40);
  String _sortBy = 'Most Popular';
  bool _gridView = true;
  bool _filterOpen = false;

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
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final uri = Uri.parse('$_kApiBase/courses');
      final res = await http.get(uri, headers: _headers);

      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _courses = data
                .map(
                  (e) => _decorateCourse(Map<String, dynamic>.from(e as Map)),
                )
                .toList();
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

  Map<String, dynamic> _decorateCourse(Map<String, dynamic> raw) {
    final course = {...raw};
    final id = (course['_id'] ?? course['id'] ?? course['title'] ?? '')
        .toString();
    final hash = id.codeUnits.fold<int>(0, (a, b) => a + b);

    final formats = ['Self-Paced', 'Live Online', 'Hybrid'];
    final rating = 3.8 + ((hash % 13) / 10);
    final reviews = 12 + (hash % 420);
    final popularity = 60 + (hash % 40);
    final duration =
        ((course['credit_hours'] is num)
                ? (course['credit_hours'] as num).toDouble()
                : 8.0)
            .clamp(1, 40)
            .toDouble();

    final badges = <String>[];
    if (popularity >= 85) badges.add('Bestseller');
    if (((course['states_approved'] as List?) ?? []).isNotEmpty)
      badges.add('State Approved');
    if (hash % 4 == 0) badges.add('New');

    course['format'] = course['format'] ?? formats[hash % formats.length];
    course['rating'] =
        (course['rating'] as num?)?.toDouble() ?? rating.clamp(0, 5).toDouble();
    course['review_count'] =
        (course['review_count'] as num?)?.toInt() ?? reviews;
    course['popularity'] =
        (course['popularity'] as num?)?.toInt() ?? popularity;
    course['duration_hours'] =
        (course['duration_hours'] as num?)?.toDouble() ?? duration;
    course['created_at'] =
        course['created_at'] ??
        DateTime.now().subtract(Duration(days: hash % 240)).toIso8601String();
    course['catalog_type'] = _resolveCourseType(course);
    course['badges'] = badges;
    return course;
  }

  String _resolveCourseType(Map<String, dynamic> course) {
    final raw = (course['catalog_type'] ?? course['type'] ?? '')
        .toString()
        .toUpperCase();
    if (raw == 'PE' || raw.contains('PRE')) return 'Pre-Licensing';
    if (raw == 'CE' || raw.contains('CONTINUING')) return 'CE';
    if (raw.contains('EXAM')) return 'Exam Prep';
    return 'Pre-Licensing';
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty || !mounted) return;
    setState(() => _ordering = true);
    try {
      final items = _cart
          .map(
            (c) => {
              'course_id': c['_id'],
              'include_textbook': c['include_textbook'] ?? false,
            },
          )
          .toList();

      final res = await http.post(
        Uri.parse('$_kApiBase/orders'),
        headers: _headers,
        body: jsonEncode({'items': items}),
      );

      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _cart = [];
          _drawerOpen = false;
          _orderSuccess = true;
        });
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFC0392B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Computed ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    final list = _courses.where((c) {
      final title = (c['title'] as String? ?? '').toLowerCase();
      final desc = (c['description'] as String? ?? '').toLowerCase();
      final states =
          (c['states_approved'] as List?)?.join(',').toLowerCase() ?? '';
      final format = (c['format'] as String? ?? '').toLowerCase();

      final needle = _query.trim().toLowerCase();
      final matchesSearch =
          needle.isEmpty ||
          title.contains(needle) ||
          desc.contains(needle) ||
          states.contains(needle) ||
          format.contains(needle);

      final type = (c['catalog_type'] as String? ?? 'Pre-Licensing');
      final matchesType =
          _courseTypeFilter == 'All' || type == _courseTypeFilter;

      final statesList = ((c['states_approved'] as List?) ?? [])
          .map((e) => e.toString())
          .toList();
      final matchesState =
          _stateFilter == 'All' || statesList.contains(_stateFilter);

      final courseFormat = (c['format'] as String? ?? 'Self-Paced');
      final matchesFormat =
          _formatFilter == 'All' || courseFormat == _formatFilter;

      final price = _num(c['price']);
      final matchesPrice =
          price >= _priceRange.start && price <= _priceRange.end;

      final duration = (c['duration_hours'] as num?)?.toDouble() ?? 0;
      final matchesDuration =
          duration >= _durationRange.start && duration <= _durationRange.end;

      return matchesSearch &&
          matchesType &&
          matchesState &&
          matchesFormat &&
          matchesPrice &&
          matchesDuration;
    }).toList();

    list.sort((a, b) {
      switch (_sortBy) {
        case 'Highest Rated':
          return ((b['rating'] as num?) ?? 0).compareTo(
            (a['rating'] as num?) ?? 0,
          );
        case 'Newest':
          final ad =
              DateTime.tryParse((a['created_at'] ?? '').toString()) ??
              DateTime(1970);
          final bd =
              DateTime.tryParse((b['created_at'] ?? '').toString()) ??
              DateTime(1970);
          return bd.compareTo(ad);
        case 'Price':
          return _num(a['price']).compareTo(_num(b['price']));
        case 'Most Popular':
        default:
          return ((b['popularity'] as num?) ?? 0).compareTo(
            (a['popularity'] as num?) ?? 0,
          );
      }
    });

    return list;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_stateFilter != 'All') count++;
    if (_courseTypeFilter != 'All') count++;
    if (_formatFilter != 'All') count++;
    if (_priceRange.start > 0 || _priceRange.end < 250) count++;
    if (_durationRange.start > 1 || _durationRange.end < 40) count++;
    return count;
  }

  void _clearFilters() {
    setState(() {
      _stateFilter = 'All';
      _courseTypeFilter = 'All';
      _formatFilter = 'All';
      _priceRange = const RangeValues(0, 250);
      _durationRange = const RangeValues(1, 40);
    });
  }

  bool _inCart(String id) => _cart.any((c) => c['_id'] == id);

  double get _total => _cart.fold(
    0.0,
    (s, c) =>
        s +
        _num(c['price']) +
        (c['include_textbook'] == true ? _num(c['textbook_price']) : 0.0),
  );

  double _num(dynamic v) => v is num ? v.toDouble() : 0.0;

  // ── Cart helpers ───────────────────────────────────────────────────
  void _addToCart(Map<String, dynamic> course) {
    if (_inCart(course['_id'] as String)) return;
    setState(() {
      _cart = [
        ..._cart,
        {...course, 'include_textbook': false},
      ];
      _drawerOpen = true;
    });
  }

  void _removeFromCart(String id) =>
      setState(() => _cart = _cart.where((c) => c['_id'] != id).toList());

  void _toggleTextbook(String id) {
    setState(() {
      _cart = _cart
          .map(
            (c) => c['_id'] == id
                ? {...c, 'include_textbook': !(c['include_textbook'] as bool)}
                : c,
          )
          .toList();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildFiltersBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),

          // Toast
          if (_orderSuccess)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: _SuccessToast(
                onClose: () => setState(() => _orderSuccess = false),
              ),
            ),

          // Dim overlay
          if (_drawerOpen || _filterOpen)
            GestureDetector(
              onTap: () => setState(() {
                _drawerOpen = false;
                _filterOpen = false;
              }),
              child: Container(color: Colors.black.withOpacity(0.42)),
            ),

          // Slide-in filter sidebar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            top: 0,
            bottom: 0,
            left: _filterOpen ? 0 : -340,
            width: 320,
            child: SafeArea(child: _buildFilterSidebar()),
          ),

          // Slide-in cart
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            top: 0,
            bottom: 0,
            right: _drawerOpen ? 0 : -340,
            width: 320,
            child: SafeArea(child: _buildCartDrawer()),
          ),
        ],
      ),
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
      child: Row(
        children: [
          // ← Dashboard
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: kWhite,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 15, color: kDark),
                  SizedBox(width: 6),
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: kDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Catalog',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: kDark,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Pre-Licensing, Exam Prep, and CE catalog',
                  style: TextStyle(
                    fontSize: 11,
                    color: kMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Cart button
          GestureDetector(
            onTap: () => setState(() {
              _filterOpen = false;
              _drawerOpen = true;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: kWhite,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 16,
                    color: kDark,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Cart',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: kDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: kBlueFaint,
                      border: Border.all(color: kBlueBorder),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${_cart.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: kDark,
                      ),
                    ),
                  ),
                  if (_cart.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: kDark,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '\$${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: kWhite,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filters bar ────────────────────────────────────────────────────
  Widget _buildFiltersBar() {
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: kWhite,
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(99),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 16, color: kMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kTextColor,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search title, state, format, or keyword...',
                      hintStyle: TextStyle(
                        color: kMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: kMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _drawerOpen = false;
                  _filterOpen = true;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _activeFilterCount > 0 ? kBlueFaint : kWhite,
                    border: Border.all(
                      color: _activeFilterCount > 0 ? kBlueBorder : kBorder,
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded, size: 15, color: kDark),
                      const SizedBox(width: 6),
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: kDark,
                        ),
                      ),
                      if (_activeFilterCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kDark,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(
                              fontSize: 10,
                              color: kWhite,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: kWhite,
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isDense: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: kMuted,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: kDark,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Most Popular',
                          child: Text('Sort: Most Popular'),
                        ),
                        DropdownMenuItem(
                          value: 'Highest Rated',
                          child: Text('Sort: Highest Rated'),
                        ),
                        DropdownMenuItem(
                          value: 'Newest',
                          child: Text('Sort: Newest'),
                        ),
                        DropdownMenuItem(
                          value: 'Price',
                          child: Text('Sort: Price'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _sortBy = v);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildViewToggle(
                active: !_gridView,
                icon: Icons.view_list_rounded,
                onTap: () => setState(() => _gridView = false),
              ),
              const SizedBox(width: 6),
              _buildViewToggle(
                active: _gridView,
                icon: Icons.grid_view_rounded,
                onTap: () => setState(() => _gridView = true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_filtered.length} courses',
            style: const TextStyle(
              fontSize: 12,
              color: kMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle({
    required bool active,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? kDark : kWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? kDark : kBorder),
        ),
        child: Icon(icon, size: 17, color: active ? kWhite : kMuted),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(kBlue),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading courses…',
              style: TextStyle(
                fontSize: 13,
                color: kMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0x1AC0392B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x38C0392B)),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFC0392B),
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: kDark,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _fetchCourses,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: kBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: kWhite,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final courses = _filtered;
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kBlueFaint,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBlueBorder),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: kBlue,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No courses found',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: kDark,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try adjusting your filters or search.',
              style: TextStyle(
                fontSize: 12,
                color: kMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: kBlue,
      onRefresh: _fetchCourses,
      child: _gridView
          ? LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 1100
                    ? 3
                    : width >= 620
                    ? 2
                    : 1;
                if (crossAxisCount == 1) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final course = courses[i];
                      final id = course['_id'] as String? ?? i.toString();
                      return _CourseCard(
                        course: course,
                        inCart: _inCart(id),
                        isExpanded: false,
                        compact: true,
                        onAddToCart: () => _addToCart(course),
                        onToggleExpand: () {},
                      );
                    },
                  );
                }

                final aspectRatio = 0.86;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: courses.length,
                  itemBuilder: (_, i) {
                    final course = courses[i];
                    final id = course['_id'] as String? ?? i.toString();
                    return _CourseCard(
                      course: course,
                      inCart: _inCart(id),
                      isExpanded: false,
                      compact: true,
                      onAddToCart: () => _addToCart(course),
                      onToggleExpand: () {},
                    );
                  },
                );
              },
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final course = courses[i];
                final id = course['_id'] as String? ?? i.toString();
                return _CourseCard(
                  course: course,
                  inCart: _inCart(id),
                  isExpanded: _expanded.contains(id),
                  compact: false,
                  onAddToCart: () => _addToCart(course),
                  onToggleExpand: () => setState(() {
                    _expanded.contains(id)
                        ? _expanded.remove(id)
                        : _expanded.add(id);
                  }),
                );
              },
            ),
    );
  }

  Widget _buildFilterSidebar() {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(right: BorderSide(color: kBorder)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, size: 18, color: kDark),
                const SizedBox(width: 10),
                const Text(
                  'Filter Catalog',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: kDark,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _filterOpen = false),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: kWhite,
                      border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: kMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'State',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: kDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: kWhite,
                      border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _stateFilter,
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Text('All States'),
                          ),
                          ..._kUsStates.map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _stateFilter = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Course Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: kDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FCChip(
                        label: 'All',
                        active: _courseTypeFilter == 'All',
                        onTap: () => setState(() => _courseTypeFilter = 'All'),
                      ),
                      _FCChip(
                        label: 'Pre-Licensing',
                        active: _courseTypeFilter == 'Pre-Licensing',
                        tone: 'blue',
                        onTap: () =>
                            setState(() => _courseTypeFilter = 'Pre-Licensing'),
                      ),
                      _FCChip(
                        label: 'Exam Prep',
                        active: _courseTypeFilter == 'Exam Prep',
                        tone: 'teal',
                        onTap: () =>
                            setState(() => _courseTypeFilter = 'Exam Prep'),
                      ),
                      _FCChip(
                        label: 'CE',
                        active: _courseTypeFilter == 'CE',
                        tone: 'teal',
                        onTap: () => setState(() => _courseTypeFilter = 'CE'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Format',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: kDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FCChip(
                        label: 'All',
                        active: _formatFilter == 'All',
                        onTap: () => setState(() => _formatFilter = 'All'),
                      ),
                      _FCChip(
                        label: 'Self-Paced',
                        active: _formatFilter == 'Self-Paced',
                        onTap: () =>
                            setState(() => _formatFilter = 'Self-Paced'),
                      ),
                      _FCChip(
                        label: 'Live Online',
                        active: _formatFilter == 'Live Online',
                        onTap: () =>
                            setState(() => _formatFilter = 'Live Online'),
                      ),
                      _FCChip(
                        label: 'Hybrid',
                        active: _formatFilter == 'Hybrid',
                        onTap: () => setState(() => _formatFilter = 'Hybrid'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Price Range (\$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: kDark,
                    ),
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 250,
                    activeColor: kBlue,
                    inactiveColor: kBlueFaint,
                    labels: RangeLabels(
                      '\$${_priceRange.start.toInt()}',
                      '\$${_priceRange.end.toInt()}',
                    ),
                    onChanged: (v) => setState(() => _priceRange = v),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Duration (${_durationRange.start.toInt()}h - ${_durationRange.end.toInt()}h)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: kDark,
                    ),
                  ),
                  RangeSlider(
                    values: _durationRange,
                    min: 1,
                    max: 40,
                    activeColor: kTeal,
                    inactiveColor: kTealFaint,
                    labels: RangeLabels(
                      '${_durationRange.start.toInt()}h',
                      '${_durationRange.end.toInt()}h',
                    ),
                    onChanged: (v) => setState(() => _durationRange = v),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kDark,
                      side: const BorderSide(color: kBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _filterOpen = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: kWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontWeight: FontWeight.w900),
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

  // ── Cart drawer ────────────────────────────────────────────────────
  Widget _buildCartDrawer() {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(left: BorderSide(color: kBorder)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2D020817),
            blurRadius: 40,
            offset: Offset(-10, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 18,
                  color: kDark,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Your Cart',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: kDark,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _drawerOpen = false),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kWhite,
                      border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: kDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_cart.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: kDark,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Add a course to checkout.',
                        style: TextStyle(
                          fontSize: 12,
                          color: kMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
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
                      color: kWhite,
                      border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                c['title'] as String? ?? 'Course',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: kDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _removeFromCart(id),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  border: Border.all(color: kBorder),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: kMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: kDark,
                            fontSize: 13,
                          ),
                        ),
                        if (hasTextbook) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _toggleTextbook(id),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: includeTb ? kBlue : kWhite,
                                    border: Border.all(
                                      color: includeTb ? kBlue : kBorder,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: includeTb
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 12,
                                          color: kWhite,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add textbook (+\$${tbPrice.toStringAsFixed(2)})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: kBorder)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kMuted,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '\$${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: kDark,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _ordering ? 'Placing order…' : 'Checkout',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue browsing',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Course Card ──────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool inCart;
  final bool isExpanded;
  final bool compact;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleExpand;

  const _CourseCard({
    required this.course,
    required this.inCart,
    required this.isExpanded,
    this.compact = false,
    required this.onAddToCart,
    required this.onToggleExpand,
  });

  double _num(dynamic v) => v is num ? v.toDouble() : 0.0;

  @override
  Widget build(BuildContext context) {
    final title = course['title'] as String? ?? 'Untitled';
    final desc = course['description'] as String? ?? '';
    final creditHrs = (course['credit_hours'] as num?)?.toDouble() ?? 0;
    final duration =
        (course['duration_hours'] as num?)?.toDouble() ?? creditHrs;
    final price = _num(course['price']);
    final tbPrice = _num(course['textbook_price']);
    final hasTextbook = course['has_textbook'] == true;
    final states = (course['states_approved'] as List?)?.cast<String>() ?? [];
    final modules = (course['modules'] as List?) ?? [];
    final rating = (course['rating'] as num?)?.toDouble() ?? 0;
    final reviews = (course['review_count'] as num?)?.toInt() ?? 0;
    final format = (course['format'] as String? ?? 'Self-Paced');
    final type = (course['catalog_type'] as String? ?? 'Pre-Licensing');
    final badges =
        (course['badges'] as List?)?.map((e) => e.toString()).toList() ?? [];

    Color typeColor = kBlue;
    Color typeBg = kBlueFaint;
    Color typeBorder = kBlueBorder;
    if (type == 'CE') {
      typeColor = kTeal;
      typeBg = kTealFaint;
      typeBorder = kTealBorder;
    } else if (type == 'Exam Prep') {
      typeColor = const Color(0xFFF59E0B);
      typeBg = const Color(0x1AF59E0B);
      typeBorder = const Color(0x38F59E0B);
    }

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Body ─────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(compact ? 12 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 54 : 72,
                      height: compact ? 54 : 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kBorder),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F2A3A), Color(0xFF2EABFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_lesson_outlined,
                        color: kWhite,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: compact ? 13 : 14,
                              fontWeight: FontWeight.w900,
                              color: kDark,
                              height: 1.2,
                            ),
                            maxLines: compact ? 2 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: compact ? 2 : 4),
                          Text(
                            states.isEmpty ? 'Multi-State' : states.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 10 : 11,
                              color: kMuted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (!compact && desc.isNotEmpty) ...[
                            SizedBox(height: compact ? 2 : 4),
                            Text(
                              desc,
                              style: TextStyle(
                                fontSize: compact ? 11 : 12,
                                color: kMuted,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                              maxLines: compact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 8 : 10),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: typeBg,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: typeBorder),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: compact ? 10 : 11,
                          fontWeight: FontWeight.w900,
                          color: typeColor,
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: kDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '($reviews)',
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        color: kMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 8 : 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Icons.schedule_rounded,
                      label:
                          '${duration.toStringAsFixed(duration % 1 == 0 ? 0 : 1)}h',
                    ),
                    if (!compact)
                      _MetaChip(
                        icon: Icons.timelapse_rounded,
                        label:
                            '${creditHrs.toStringAsFixed(creditHrs % 1 == 0 ? 0 : 1)} credit hrs',
                      ),
                    _MetaChip(
                      icon: Icons.desktop_windows_outlined,
                      label: format,
                    ),
                  ],
                ),

                if (badges.isNotEmpty) ...[
                  SizedBox(height: compact ? 8 : 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: badges.take(compact ? 1 : 3).map((badge) {
                      Color chipBg = const Color(0xFFF3F4F6);
                      Color chipBorder = kBorder;
                      Color chipText = kMuted;
                      if (badge == 'Bestseller') {
                        chipBg = const Color(0x1AF59E0B);
                        chipBorder = const Color(0x38F59E0B);
                        chipText = const Color(0xFFB45309);
                      } else if (badge == 'State Approved') {
                        chipBg = kBlueFaint;
                        chipBorder = kBlueBorder;
                        chipText = kBlue;
                      } else if (badge == 'New') {
                        chipBg = kTealFaint;
                        chipBorder = kTealBorder;
                        chipText = kTeal;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: chipBg,
                          border: Border.all(color: chipBorder),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: chipText,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                if (!compact && modules.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onToggleExpand,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Modules (${modules.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: kDark,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: kMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    ...modules.map((m) {
                      final mod = Map<String, dynamic>.from(m as Map);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: kBlueFaint,
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: kBlueBorder),
                              ),
                              child: Text(
                                'M${mod['order'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: kDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                mod['title'] as String? ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: kTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ],
            ),
          ),

          // ── Footer: price + Add button ────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 10 : 12,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.w900,
                        color: kDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (hasTextbook)
                      Text(
                        '+ Textbook (\$${tbPrice.toStringAsFixed(2)})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: kMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                GestureDetector(
                  onTap: inCart ? null : onAddToCart,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 16,
                      vertical: compact ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: inCart ? kTealFaint : kBlue,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: inCart ? kTealBorder : kBlueBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          inCart
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: compact ? 14 : 15,
                          color: inCart ? kTeal : kWhite,
                        ),
                        SizedBox(width: compact ? 4 : 6),
                        Text(
                          inCart ? 'Enrolled' : 'Enroll Now',
                          style: TextStyle(
                            fontSize: compact ? 12 : 13,
                            fontWeight: FontWeight.w900,
                            color: inCart ? kTeal : kWhite,
                          ),
                        ),
                      ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kTealFaint,
              border: Border.all(color: kTealBorder),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: kTeal,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order placed successfully',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: kDark,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Check your dashboard for your courses.',
                  style: TextStyle(
                    fontSize: 12,
                    color: kMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close_rounded, size: 15, color: kMuted),
            ),
          ),
        ],
      ),
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
    if (active && tone == 'blue') {
      bg = kBlueFaint;
      border = kBlueBorder;
      fg = kBlue;
    } else if (active && tone == 'teal') {
      bg = kTealFaint;
      border = kTealBorder;
      fg = kTeal;
    } else if (active) {
      bg = kDark;
      border = kDark;
      fg = kWhite;
    } else {
      bg = kWhite;
      border = kBorder;
      fg = kMuted;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: fg,
          ),
        ),
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
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: kMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kMuted,
            ),
          ),
        ],
      ),
    );
  }
}
