import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/config/api_config.dart';
import 'package:nmls_mobile/state_requirement_detail_screen.dart';

class StatesScreen extends StatefulWidget {
  const StatesScreen({super.key});

  @override
  State<StatesScreen> createState() => _StatesScreenState();
}

class _StatesScreenState extends State<StatesScreen> {
  static const Color primaryNavy = Color(0xFF0D3B66);
  static const Color pageBg = Color(0xFFF5F8FC);

  final _searchController = TextEditingController();
  String _search = '';
  String? _selectedCode;
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _states = [];

  @override
  void initState() {
    super.initState();
    _fetchStates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered => _states
      .where(
        (s) =>
            (s['stateName']?.toString().toLowerCase() ?? '').contains(
              _search.toLowerCase(),
            ) ||
            (s['stateCode']?.toString().toLowerCase() ?? '').contains(
              _search.toLowerCase(),
            ),
      )
      .toList();

  Future<void> _fetchStates() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final res = await http
          .get(Uri.parse(ApiConfig.stateRequirements))
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        final mapped = data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        if (!mounted) return;
        setState(() {
          _states = mapped;
          if (_selectedCode == null && mapped.isNotEmpty) {
            _selectedCode = mapped.first['stateCode']?.toString();
          }
        });
      } else {
        if (!mounted) return;
        setState(() => _error = 'Failed to load states (${res.statusCode})');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(String stateCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StateRequirementDetailScreen(stateCode: stateCode),
      ),
    );
  }

  void _openSelected() {
    final code = _selectedCode;
    if (code == null || code.isEmpty) return;
    _openDetail(code);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'State Requirements',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFC0392B),
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchStates,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SELECT A STATE',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose a state to view licensing and CE renewal requirements',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCode,
                          decoration: const InputDecoration(
                            labelText: 'State dropdown',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                          ),
                          items: _states
                              .map(
                                (s) => DropdownMenuItem<String>(
                                  value: s['stateCode']?.toString(),
                                  child: Text(
                                    '${s['stateName']} (${s['stateCode']})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedCode = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openSelected,
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('View Requirements'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _search = v),
                          decoration: InputDecoration(
                            hintText: 'Search by state name or code...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _search = '');
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_off_rounded,
                                color: const Color(0xFF94A3B8),
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No states found for "$_search"',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
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
                              label: state['stateName']?.toString() ?? '',
                              code: state['stateCode']?.toString() ?? '',
                              onTap: () => _openDetail(
                                state['stateCode']?.toString() ?? '',
                              ),
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
  final String code;
  final VoidCallback onTap;

  const _StateCell({
    required this.label,
    required this.code,
    required this.onTap,
  });

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
          color: _pressed ? const Color(0xFFE6F2FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _pressed ? const Color(0xFF2E7EBE) : const Color(0xFFE2E8F0),
            width: _pressed ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '${widget.code}\n${widget.label}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _pressed
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF334155),
                fontSize: 11.5,
                fontWeight: _pressed ? FontWeight.w700 : FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
