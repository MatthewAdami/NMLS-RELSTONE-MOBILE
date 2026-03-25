import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/widgets/app_bottom_nav.dart';
import 'exam_prep_center_screen.dart';
import 'config/api_config.dart';

// ─── Theme ────────────────────────────────────────────────────────────
const kDark        = Color(0xFF091925);
const kBlue        = Color(0xFF2EABFE);
const kBlueFaint   = Color(0x1A2EABFE);
const kBlueBorder  = Color(0x382EABFE);
const kBg          = Color(0xFFF6F7FB);
const kWhite       = Colors.white;
const kMuted       = Color(0x990B1220);
const kBorder      = Color(0x1A020817);
const kSurface     = Color(0xD0FFFFFF);

class ExamPrepScreen extends StatefulWidget {
  final String? token;
  final String userName;
  final String userEmail;
  const ExamPrepScreen({
    Key? key,
    this.token,
    this.userName = 'User',
    this.userEmail = 'user@example.com',
  }) : super(key: key);

  @override
  State<ExamPrepScreen> createState() => _ExamPrepScreenState();
}

class _ExamPrepScreenState extends State<ExamPrepScreen> {
  bool _isLoading = true;
  String _loadError = '';

  double _readiness = 0.70;
  List<_TopicScoreRow> _topicScores = const [];
  List<double> _trend = const [];
  int _attempts = 0;

  bool _flashExpanded = false;
  bool _flashLoading = false;
  String _flashError = '';
  List<_FlashcardRow> _flashcards = const [];

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (widget.token != null && widget.token!.isNotEmpty)
          'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _loadError = '';
    });

    try {
      final res = await http
          .get(Uri.parse(ApiConfig.examPrepAnalytics), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode != 200) {
        setState(() {
          _loadError = 'Failed to load analytics (${res.statusCode}).';
          _isLoading = false;
        });
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final readinessRaw = (data['readiness'] as num?)?.toDouble() ?? 0.0;
      final readiness = readinessRaw.clamp(0.0, 1.0);

      final attempts = (data['attempts'] as num?)?.toInt() ?? 0;
      final trendRaw = (data['trend'] as List?) ?? const [];
      final trend = trendRaw
          .whereType<num>()
          .map((e) => e.toDouble().clamp(0.0, 1.0))
          .toList();

      final rowsRaw = (data['topicScores'] as List?) ?? const [];
      final rows = rowsRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(_TopicScoreRow.fromApi)
          .whereType<_TopicScoreRow>()
          .toList();

      // Show weakest first and keep UI compact.
      rows.sort((a, b) => a.average.compareTo(b.average));
      final top5 = rows.length > 5 ? rows.sublist(0, 5) : rows;

      setState(() {
        _readiness = readiness;
        _topicScores = top5;
        _trend = trend.length > 10 ? trend.sublist(trend.length - 10) : trend;
        _attempts = attempts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to reach exam analytics. Please retry.';
        _isLoading = false;
      });
    }
  }

  Future<void> _ensureFlashcardsLoaded() async {
    if (_flashLoading) return;
    if (_flashcards.isNotEmpty) return;

    setState(() {
      _flashLoading = true;
      _flashError = '';
    });

    try {
      final res = await http
          .get(Uri.parse(ApiConfig.examPrepQuestions), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode != 200) {
        setState(() {
          _flashError = 'Failed to load flashcards (${res.statusCode}).';
          _flashLoading = false;
        });
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = (data['flashcards'] as List?) ?? const [];
      final cards = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(_FlashcardRow.fromApi)
          .whereType<_FlashcardRow>()
          .toList();

      setState(() {
        _flashcards = cards;
        _flashLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _flashError = 'Unable to reach flashcards. Please retry.';
        _flashLoading = false;
      });
    }
  }

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
              activeTab: AppNavTab.examPrep,
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
      padding: const EdgeInsets.only(top: 24, bottom: 24, left: 16, right: 16),
      child: Column(
        children: [
          const Text(
            'Exam Prep Center',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'California Real Estate License Exam',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: const Color(0xFF7D92A3),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF102436),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: max(0.0, min(1.0, _readiness)),
                        strokeWidth: 6,
                        color: kBlue,
                        backgroundColor: kBlue.withValues(alpha: 0.15),
                      ),
                      Center(
                        child: Text(
                          '${(_readiness * 100).round()}%',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Readiness Score',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _readiness >= 0.80
                            ? 'Exam-ready. Keep pace with your practice.'
                            : _readiness >= 0.70
                                ? 'Good progress! Focus on weak topics.'
                                : 'Foundation stage. Prioritize topic drills first.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: const Color(0xFF7D92A3),
                          height: 1.4,
                        ),
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

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // Practice Modes
          const Text(
            'PRACTICE MODES',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
              color: Color(0xFF7D92A3),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExamPrepCenterScreen(
                          token: widget.token,
                          initialMode: ExamPrepInitialMode.simulator,
                          showReadiness: false,
                          showPracticeModes: false,
                          showAnalytics: false,
                          popToDashboardOnEndSession: true,
                        ),
                      ),
                    );
                    if (mounted) _loadAnalytics();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kDark,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: kBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Full Exam',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '150 Q · 3 hrs',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: const Color(0xFF7D92A3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExamPrepCenterScreen(
                          token: widget.token,
                          initialMode: ExamPrepInitialMode.drill,
                          showReadiness: false,
                          showPracticeModes: false,
                          showAnalytics: false,
                          popToDashboardOnEndSession: true,
                        ),
                      ),
                    );
                    if (mounted) _loadAnalytics();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorder.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kBlue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kBlue.withValues(alpha: 0.1)),
                          ),
                          child: const Icon(
                            Icons.access_time,
                            color: Color(0xFF6B8397),
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Topic Drill',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: kDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'One topic',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: kMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Flashcards (dropdown)
          Container(
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    setState(() => _flashExpanded = !_flashExpanded);
                    if (_flashExpanded) {
                      await _ensureFlashcardsLoaded();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.style_outlined, color: kBlue, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Flashcards',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: kDark,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _flashExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF6B8397),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _flashLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _flashError.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _flashError,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: kMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _flashcards = const [];
                                      });
                                      _ensureFlashcardsLoaded();
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              )
                            : _flashcards.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      'No flashcards available yet.',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: kMuted,
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    height: 220,
                                    child: ListView.separated(
                                      itemCount: _flashcards.length > 12
                                          ? 12
                                          : _flashcards.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final card = _flashcards[index];
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7FAFD),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  kBorder.withValues(alpha: 0.08),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                card.term,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: kDark,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                card.definition,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 12,
                                                  color: kMuted,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                  ),
                  crossFadeState: _flashExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 180),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Performance By Topic
          const Text(
            'PERFORMANCE BY TOPIC',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
              color: Color(0xFF7D92A3),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (!_isLoading && _loadError.isEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _statTile(
                          label: 'Attempts',
                          value: '$_attempts',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statTile(
                          label: 'Last score',
                          value: _trend.isEmpty
                              ? '—'
                              : '${(_trend.last * 100).round()}%',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _weakTopicsText(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Score Improvement Over Time',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: _trend.isEmpty
                        ? const Center(
                            child: Text(
                              'No trend data yet',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: kMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : CustomPaint(
                            painter: _TrendLinePainter(values: _trend),
                            child: Container(),
                          ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (!_isLoading && _loadError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      _loadError,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kMuted,
                      ),
                    ),
                  ),
                if (!_isLoading && _loadError.isEmpty && _topicScores.isNotEmpty)
                  ..._topicScores.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    final color = row.average >= 0.85
                        ? kBlue
                        : row.average >= 0.65
                            ? kBlue
                            : const Color(0xFFF59E0B);

                    return Column(
                      children: [
                        _buildPerformanceRow(row.title, row.average, color),
                        if (index != _topicScores.length - 1)
                          const SizedBox(height: 20),
                      ],
                    );
                  }),
                if (!_isLoading && _loadError.isEmpty && _topicScores.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'No topic analytics yet. Complete a session to generate results.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: kDark,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _statTile({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kDark,
            ),
          ),
        ],
      ),
    );
  }

  String _weakTopicsText() {
    if (_topicScores.isEmpty) return 'Weak topics: none detected yet';
    final weak = _topicScores
        .where((e) => e.attempts > 0 && e.average > 0 && e.average < 0.72)
        .map((e) => e.title)
        .toList();
    if (weak.isEmpty) return 'Weak topics: none detected yet';
    return 'Weak topics: ${weak.join(', ')}';
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<double> values;
  const _TrendLinePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = const Color(0x33212E3E)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axis);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), axis);

    final grid = Paint()
      ..color = const Color(0x22212E3E)
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (values.isEmpty) return;
    if (values.length == 1) {
      final only = values.first.clamp(0.0, 1.0);
      final point = Offset(size.width / 2, size.height - (only * size.height));
      canvas.drawCircle(point, 4, Paint()..color = kBlue);
      return;
    }

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * (size.width / (values.length - 1));
      final y = size.height - (values[i].clamp(0.0, 1.0) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final line = Paint()
      ..color = kBlue
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, line);

    final dotPaint = Paint()..color = const Color(0xFF00B4B4);
    for (int i = 0; i < values.length; i++) {
      final x = i * (size.width / (values.length - 1));
      final y = size.height - (values[i].clamp(0.0, 1.0) * size.height);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _TopicScoreRow {
  final String title;
  final double average;
  final int attempts;

  const _TopicScoreRow({
    required this.title,
    required this.average,
    required this.attempts,
  });

  static _TopicScoreRow? fromApi(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    final avg = (data['average'] as num?)?.toDouble();
    final attempts = (data['attempts'] as num?)?.toInt() ?? 0;

    if (title.isEmpty || avg == null || avg.isNaN) return null;
    return _TopicScoreRow(title: title, average: avg.clamp(0.0, 1.0), attempts: attempts);
  }
}

class _FlashcardRow {
  final String term;
  final String definition;
  final String topic;
  final String difficulty;

  const _FlashcardRow({
    required this.term,
    required this.definition,
    required this.topic,
    required this.difficulty,
  });

  static _FlashcardRow? fromApi(Map<String, dynamic> data) {
    final term = (data['term'] ?? '').toString().trim();
    final definition = (data['definition'] ?? '').toString().trim();
    final topic = (data['topic'] ?? 'General').toString().trim();
    final difficulty = (data['difficulty'] ?? 'medium').toString().trim();
    if (term.isEmpty || definition.isEmpty) return null;
    return _FlashcardRow(
      term: term,
      definition: definition,
      topic: topic,
      difficulty: difficulty,
    );
  }
}
