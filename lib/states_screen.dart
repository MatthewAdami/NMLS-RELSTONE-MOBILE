import 'package:flutter/material.dart';

class StatesScreen extends StatefulWidget {
  const StatesScreen({super.key});

  @override
  State<StatesScreen> createState() => _StatesScreenState();
}

class _StatesScreenState extends State<StatesScreen> {
  // ── Brand colors ──────────────────────────────────────────
  static const Color primaryNavy = Color(0xFF1A3A5C);
  static const Color accentBlue = Color(0xFF2E7EBE);
  static const Color navBg = Color(0xFF0B1A2A);
  static const Color cardBg = Color(0xFF132030);
  static const Color cardBorder = Color(0xFF1E3448);
  static const Color textLight = Colors.white;
  static const Color textMuted = Color(0xFF6B7E92);

  // ── All US states ─────────────────────────────────────────
  static const List<String> _states = [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California',
    'Colorado', 'Connecticut', 'Delaware', 'District of Columbia', 'Florida',
    'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana',
    'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine',
    'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi',
    'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire',
    'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota',
    'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
    'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah',
    'Vermont', 'Virginia', 'Washington', 'West Virginia', 'Wisconsin',
    'Wyoming',
  ];

  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filtered => _states
      .where((s) => s.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  void _onStateTap(String state) {
    // TODO: Navigate to the state's courses/products page
    // Example: Navigator.pushNamed(context, '/state-courses', arguments: state);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: $state'),
        backgroundColor: primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: navBg,
      appBar: AppBar(
        backgroundColor: navBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/relstone_logo.png',
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text(
                'RELSTONE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.white.withOpacity(0.08), height: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECT A STATE',
                  style: TextStyle(
                    color: Color(0xFF6B8FAF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose your state to view\navailable courses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Search bar ──
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search states...',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withOpacity(0.4), size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: Colors.white.withOpacity(0.4),
                                  size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Grid ────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_off_rounded,
                            color: Colors.white24, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'No states found for "$_search"',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.4,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final state = filtered[index];
                      return _StateCell(
                        label: state,
                        onTap: () => _onStateTap(state),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StateCell extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _StateCell({required this.label, required this.onTap});

  @override
  State<_StateCell> createState() => _StateCellState();
}

class _StateCellState extends State<_StateCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFF1E3A5C)
              : const Color(0xFF132030),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _pressed
                ? const Color(0xFF2E7EBE)
                : const Color(0xFF1E3448),
            width: _pressed ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _pressed ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight:
                    _pressed ? FontWeight.w700 : FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}