import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/config/api_config.dart';

class StateRequirementDetailScreen extends StatefulWidget {
  final String stateCode;

  const StateRequirementDetailScreen({super.key, required this.stateCode});

  @override
  State<StateRequirementDetailScreen> createState() =>
      _StateRequirementDetailScreenState();
}

class _StateRequirementDetailScreenState
    extends State<StateRequirementDetailScreen> {
  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final res = await http
          .get(
            Uri.parse(ApiConfig.stateRequirementDetail(widget.stateCode)),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() => _detail = data);
      } else {
        if (!mounted) return;
        setState(
          () =>
              _error = 'Unable to load state requirements (${res.statusCode})',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _enroll() {
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3B66),
        foregroundColor: Colors.white,
        title: Text(
          detail == null
              ? 'State Requirements'
              : '${detail['stateName']} Requirements',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? _ErrorPanel(message: _error, onRetry: _loadDetail)
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _hero(detail!),
                  const SizedBox(height: 14),
                  _preLicensingCard(detail),
                  const SizedBox(height: 12),
                  _examCard(detail),
                  const SizedBox(height: 12),
                  _postExamCard(detail),
                  const SizedBox(height: 12),
                  _ceCard(detail),
                  const SizedBox(height: 12),
                  _coursesCard(detail),
                ],
              ),
            ),
    );
  }

  Widget _hero(Map<String, dynamic> detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF082032), Color(0xFF0D3B66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail['stateCode']?.toString() ?? '',
            style: const TextStyle(
              color: Color(0xFFAED8FF),
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail['stateName']?.toString() ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Licensing steps, exam info, and CE renewal requirements in one view.',
            style: TextStyle(
              color: Color(0xFFE2EEF9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _preLicensingCard(Map<String, dynamic> detail) {
    final pre = Map<String, dynamic>.from(detail['preLicensing'] as Map? ?? {});
    final breakdown = (pre['subjectBreakdown'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return _sectionCard(
      title: 'Pre-Licensing Hours',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pre['totalHours'] ?? 0} total hours',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...breakdown.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry['subject']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${entry['hours']} hrs',
                    style: const TextStyle(
                      color: Color(0xFF0D3B66),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _examCard(Map<String, dynamic> detail) {
    final exam = Map<String, dynamic>.from(detail['exam'] as Map? ?? {});

    return _sectionCard(
      title: 'State Exam Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line('Format', exam['format']?.toString() ?? 'N/A'),
          const SizedBox(height: 8),
          _line('Pass Score', exam['passScore']?.toString() ?? 'N/A'),
          const SizedBox(height: 8),
          _line('Scheduling', exam['scheduling']?.toString() ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _postExamCard(Map<String, dynamic> detail) {
    final steps = (detail['postExamSteps'] as List? ?? [])
        .map((e) => e.toString())
        .toList();

    return _sectionCard(
      title: 'Application Steps Post-Exam',
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F2FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Color(0xFF0D3B66),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
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

  Widget _ceCard(Map<String, dynamic> detail) {
    final ce = Map<String, dynamic>.from(detail['ceRenewal'] as Map? ?? {});

    return _sectionCard(
      title: 'CE Renewal Requirements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line('Hours', '${ce['hours'] ?? 0} hours'),
          const SizedBox(height: 8),
          _line('Frequency', ce['frequency']?.toString() ?? 'N/A'),
          const SizedBox(height: 8),
          _line('Details', ce['details']?.toString() ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _coursesCard(Map<String, dynamic> detail) {
    final courses = (detail['relstoneCourses'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return _sectionCard(
      title: 'Relstone Courses That Satisfy Requirements',
      child: courses.isEmpty
          ? const Text(
              'No mapped courses yet for this state. Contact support for guidance.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            )
          : Column(
              children: courses
                  .map(
                    (course) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['title']?.toString() ?? '',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${course['type']} • ${course['creditHours']} hrs • \$${course['price']}',
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _enroll,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D3B66),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Enroll',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _line(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Color(0xFF334155), height: 1.35),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFC0392B),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
