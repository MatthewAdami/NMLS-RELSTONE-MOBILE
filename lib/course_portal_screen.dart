import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as httpClient;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'config/api_config.dart';

// ─── Theme ────────────────────────────────────────────────────────────
const _kDark   = Color(0xFF0A1628);
const _kBlue   = Color(0xFF2EABFE);
const _kTeal   = Color(0xFF00B4B4);
const _kAmber  = Color(0xFFF59E0B);
const _kGreen  = Color(0xFF22C55E);
const _kRed    = Color(0xFFEF4444);
const _kBg     = Color(0xFFF4F6FA);
const _kWhite  = Colors.white;

// ═══════════════════════════════════════════════════════════════════
// COURSE PORTAL SCREEN
// ═══════════════════════════════════════════════════════════════════
class CoursePortalScreen extends StatefulWidget {
  final String courseId;
  const CoursePortalScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  State<CoursePortalScreen> createState() => _CoursePortalScreenState();
}

class _CoursePortalScreenState extends State<CoursePortalScreen> {
  Map<String, dynamic>? _course;
  List<Map<String, dynamic>> _content = [];
  Map<String, dynamic> _quizAttempts  = {};

  bool   _loading     = true;
  String? _error;
  String? _token;
  bool   _sidebarOpen = false;
  bool   _finished    = false;
  bool   _reviewMode  = false;
  bool   _rocsAgreed  = false;

  int          _currentIdx = 0;
  Set<int>     _completed  = {};
  Map<String, dynamic>? _transcriptEntry;

  Timer? _seatTimer;
  int    _seatSeconds = 0;

  Map<String, dynamic>? get _current =>
      _content.isNotEmpty ? _content[_currentIdx] : null;

  int get _progress => _reviewMode
      ? 100
      : _content.isEmpty ? 0 : ((_completed.length / _content.length) * 100).round();

  bool _canNavigateTo(int idx) =>
      _reviewMode || idx == 0 || _completed.contains(idx - 1);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _seatTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    await _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _get('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/courses/${widget.courseId}'),
        _get('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/dashboard/transcript'),
        _get('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/rocs/check/${widget.courseId}'),
      ]);

      final courseData = results[0]['data']?['data'] ?? results[0]['data'];
      if (courseData == null) throw Exception('Course not found');
      _course = Map<String, dynamic>.from(courseData as Map);

      final transcript = (results[1]['data']?['transcript'] as List?) ?? [];
      final entry = transcript.firstWhere(
        (t) => (t['course_id']?['_id'] ?? t['course_id'])?.toString() == widget.courseId,
        orElse: () => null,
      );

      final isCompleted = entry != null;
      _content = isCompleted ? _buildReviewContent(_course!) : _buildContent(_course!);

      if (isCompleted) {
        _transcriptEntry = Map<String, dynamic>.from(entry as Map);
        _finished = true;
        _completed = Set.from(List.generate(_content.length, (i) => i));
        _reviewMode = true;
      }

      _rocsAgreed = results[2]['data']?['agreed'] == true;

      if (!isCompleted) {
        final progRes = await _get('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/dashboard/progress/${widget.courseId}');
        final prog = progRes['data'] ?? {};
        final idxs = (prog['completed_idxs'] as List?) ?? [];
        final idx  = (prog['current_idx'] as num?)?.toInt() ?? 0;
        _completed  = Set<int>.from(idxs.map((e) => (e as num).toInt()));
        _currentIdx = idx.clamp(0, _content.isEmpty ? 0 : _content.length - 1);
      }

      await _refreshAttempts();
      _startSeatTimer();
    } catch (e) {
      setState(() => _error = 'Could not load course content.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _buildContent(Map<String, dynamic> course) {
    final content = <Map<String, dynamic>>[];
    final modules = ((course['modules'] as List?) ?? [])
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList()
      ..sort((a, b) => ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0));

    final coursePdf = course['pdf_url'] as String?;

    for (final mod in modules) {
      final modPdf = (mod['pdf_url'] as String?) ?? coursePdf;

      content.add({
        'id': 'lesson-mod-${mod['order']}', 'type': 'lesson',
        'title': mod['title'], 'credit_hours': mod['credit_hours'],
        'moduleOrder': mod['order'], 'pdf_url': modPdf,
        'video_url': mod['video_url'], 'sections': mod['sections'] ?? [],
      });

      final quiz = mod['quiz'] as List?;
      if (quiz != null && quiz.isNotEmpty) {
        final isFundamentals = (mod['show_pdf_before_quiz'] == true) && quiz.length > 10;
        content.add({
          'id': 'checkpoint-mod-${mod['order']}',
          'type': isFundamentals ? 'quiz_fundamentals' : 'checkpoint',
          'title': isFundamentals
              ? '${mod['title']} — Fundamentals Exam'
              : 'Checkpoint: ${mod['title']}',
          'moduleOrder': mod['order'],
          'questions': quiz.asMap().entries.map((e) {
            final q = Map<String, dynamic>.from(e.value as Map);
            return {
              'id': 'mod${mod['order']}-q${e.key}',
              'text': q['question'],
              'options': q['options'],
              'correct': q['correct_index'],
            };
          }).toList(),
          'passingScore': 70,
        });
      }
    }

    final finalExam = course['final_exam'] as Map?;
    if (finalExam != null && (finalExam['questions'] as List?)?.isNotEmpty == true) {
      final questions = finalExam['questions'] as List;
      content.add({
        'id': 'final-exam', 'type': 'quiz',
        'title': finalExam['title'] ?? 'Final Exam',
        'passingScore': (finalExam['passing_score'] as num?)?.toInt() ?? 70,
        'moduleOrder': 999,
        'questions': questions.asMap().entries.map((e) {
          final q = Map<String, dynamic>.from(e.value as Map);
          return {'id': 'fq${e.key}', 'text': q['question'], 'options': q['options'], 'correct': q['correct_index']};
        }).toList(),
      });
    }

    return content;
  }

  List<Map<String, dynamic>> _buildReviewContent(Map<String, dynamic> course) {
    final base = _buildContent(course);
    base.add({'id': 'review-summary', 'type': 'review_summary', 'title': 'Course Summary', 'moduleOrder': 9999});
    return base;
  }

  void _startSeatTimer() {
    _seatTimer?.cancel();
    _seatSeconds = 0;
    if (_reviewMode || _finished) return;
    _seatTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seatSeconds++);
    });
  }

  void _navigateTo(int idx) {
    setState(() {
      _currentIdx = idx;
      _sidebarOpen = false;
    });
    _saveProgress();
  }

  void _markComplete(int idx) {
    if (_reviewMode) return;
    setState(() => _completed.add(idx));
    _saveProgress();
  }

  void _goNext() {
    _markComplete(_currentIdx);
    if (_currentIdx < _content.length - 1) {
      _navigateTo(_currentIdx + 1);
    }
  }

  void _goPrev() {
    if (_currentIdx > 0) _navigateTo(_currentIdx - 1);
  }

  Future<void> _handleFinish() async {
    _markComplete(_currentIdx);
    try {
      await Future.wait([
        _post('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/dashboard/complete', {'courseId': widget.courseId}),
        _post('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/enrollment/${widget.courseId}/complete', {}),
      ]);
    } catch (_) {}
    setState(() {
      _finished = true;
      _completed = Set.from(List.generate(_content.length, (i) => i));
    });
  }

  Future<void> _saveProgress() async {
    try {
      final body = {
        'completed_idxs': _completed.toList()..sort(),
        'current_idx': _currentIdx,
        'total_steps': _content.length,
      };
      await Future.wait([
        _put('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/dashboard/progress/${widget.courseId}', body),
        _put('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/enrollment/${widget.courseId}/progress', body),
      ]);
    } catch (_) {}
  }

  Future<void> _refreshAttempts() async {
    try {
      final res = await _get('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/quiz-attempts/${widget.courseId}');
      if (mounted) setState(() => _quizAttempts = Map<String, dynamic>.from(res['data']?['attempts'] ?? {}));
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _get(String url) async {
    try {
      final res = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 10));
      return {'statusCode': res.statusCode, 'data': _decode(res.body)};
    } catch (e) { return {'statusCode': 0, 'data': {}}; }
  }

  Future<void> _post(String url, Map body) async {
    await http.post(Uri.parse(url), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
  }

  Future<void> _put(String url, Map body) async {
    await http.put(Uri.parse(url), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
  }

  Map<String, dynamic> _decode(String body) {
    try { return jsonDecode(body) as Map<String, dynamic>; } catch (_) { return {}; }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_finished && !_reviewMode) return _CompletionScreen(
      course: _course,
      transcriptEntry: _transcriptEntry,
      onReview: () {
        final rc = _buildReviewContent(_course!);
        setState(() {
          _content    = rc;
          _completed  = Set.from(List.generate(rc.length, (i) => i));
          _currentIdx = 0;
          _reviewMode = true;
          _finished   = false;
        });
        _refreshAttempts();
      },
      onDashboard: () => Navigator.of(context).pop(),
    );

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            if (_reviewMode) _buildReviewBanner(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildMainContent()),
                  if (_sidebarOpen) ...[
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => setState(() => _sidebarOpen = false),
                        child: Container(color: Colors.black54),
                      ),
                    ),
                    Positioned(
                      top: 0, left: 0, bottom: 0,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: _buildSidebar(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() => Container(
    height: 58,
    color: _kDark,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: _kWhite, size: 14),
                SizedBox(width: 4),
                Text('Exit', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12, color: _kWhite)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _course?['title'] ?? 'Course',
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 12, color: _kWhite),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${_course?['type'] ?? ''} · ${_course?['credit_hours'] ?? 0} credit hrs',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 5,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _reviewMode ? _kAmber : _kBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _reviewMode ? '✓' : '$_progress%',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.65)),
            ),
          ],
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _sidebarOpen = !_sidebarOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: const Icon(Icons.menu_rounded, color: _kWhite, size: 16),
          ),
        ),
      ],
    ),
  );

  Widget _buildReviewBanner() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    color: _kAmber.withOpacity(0.08),
    child: Row(
      children: [
        const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF925400)),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'You are in Review Mode — this course is already completed.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF925400)),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kAmber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _kAmber.withOpacity(0.35)),
            ),
            child: const Text('Exit', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF925400))),
          ),
        ),
      ],
    ),
  );

  Widget _buildSidebar() => Container(
    color: _kWhite,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x12020817))),
          ),
          child: Row(
            children: [
              Text(
                _reviewMode ? '📋 Course Review' : 'Course Contents',
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900, fontSize: 13, color: _kDark),
              ),
              const SizedBox(width: 8),
              Text(
                _reviewMode ? '${_content.length} steps' : '${_completed.length}/${_content.length}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0x66091925), fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _sidebarOpen = false),
                child: const Icon(Icons.close_rounded, size: 20, color: Color(0x99091925)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _content.length,
            itemBuilder: (ctx, idx) {
              final item    = _content[idx];
              final isDone  = _reviewMode || _completed.contains(idx);
              final isCurr  = idx == _currentIdx;
              final isLocked = !_canNavigateTo(idx);
              final type    = item['type'] as String? ?? '';

              IconData icon;
              Color iconColor;
              String typeLabel;

              switch (type) {
                case 'checkpoint':
                case 'quiz_fundamentals':
                  icon = Icons.assignment_outlined;
                  iconColor = _kAmber;
                  typeLabel = type == 'quiz_fundamentals' ? 'Fundamentals Exam' : 'Checkpoint';
                  break;
                case 'quiz':
                  icon = Icons.emoji_events_outlined;
                  iconColor = _kGreen;
                  typeLabel = 'Final Exam';
                  break;
                case 'review_summary':
                  icon = Icons.summarize_outlined;
                  iconColor = _kAmber;
                  typeLabel = 'Summary';
                  break;
                default:
                  icon = Icons.play_circle_outline;
                  iconColor = _kBlue;
                  typeLabel = 'Lesson';
              }

              return GestureDetector(
                onTap: () { if (!isLocked) _navigateTo(idx); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCurr ? _kBlue.withOpacity(0.08) : Colors.transparent,
                    border: Border(
                      right: BorderSide(color: isCurr ? _kBlue : Colors.transparent, width: 3),
                    ),
                  ),
                  child: Opacity(
                    opacity: isLocked ? 0.45 : 1.0,
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: iconColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(typeLabel, style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w900, color: Color(0x66091925), letterSpacing: 0.4)),
                              Text(item['title'] as String? ?? '', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _kDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isDone)
                          const Icon(Icons.check_circle_rounded, size: 16, color: _kGreen)
                        else if (isLocked && !_reviewMode)
                          const Icon(Icons.lock_outline, size: 13, color: Color(0x4D091925))
                        else if (isCurr)
                          const Icon(Icons.chevron_right_rounded, size: 16, color: _kBlue),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _buildMainContent() {
    final item = _current;
    if (item == null) return const Center(child: Text('No content'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: () {
        switch (item['type']) {
          case 'lesson':
            return _LessonView(
              item: item,
              reviewMode: _reviewMode,
              seatSeconds: _seatSeconds,
              onNext: _goNext,
              onPrev: _goPrev,
              showPrev: _currentIdx > 0,
            );
          case 'checkpoint':
          case 'quiz_fundamentals':
            return _QuizView(
              item: item,
              courseId: widget.courseId,
              attemptInfo: _quizAttempts[item['id']],
              isCheckpoint: item['type'] == 'checkpoint',
              reviewMode: _reviewMode,
              onComplete: _goNext,
              onPrev: _goPrev,
              onAttemptLogged: _refreshAttempts,
              headers: _headers,
            );
          case 'quiz':
            return _QuizView(
              item: item,
              courseId: widget.courseId,
              attemptInfo: _quizAttempts[item['id']],
              isCheckpoint: false,
              reviewMode: _reviewMode,
              onComplete: _reviewMode ? _goNext : _handleFinish,
              onPrev: _goPrev,
              onAttemptLogged: _refreshAttempts,
              headers: _headers,
            );
          case 'review_summary':
            return _ReviewSummaryView(
              course: _course!,
              courseId: widget.courseId,
              content: _content,
              quizAttempts: _quizAttempts,
              transcriptEntry: _transcriptEntry,
              onPrev: _goPrev,
              onDone: () => Navigator.of(context).pop(),
              headers: _headers,
            );
          default:
            return const Center(child: Text('Unknown content type'));
        }
      }(),
    );
  }

  Widget _buildLoading() => const Scaffold(
    backgroundColor: _kDark,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _kBlue, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text('Loading course...', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white54)),
        ],
      ),
    ),
  );

  Widget _buildError() => Scaffold(
    backgroundColor: _kBg,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _kRed),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: _kDark)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: _kBlue, foregroundColor: _kWhite),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// LESSON VIEW
// ═══════════════════════════════════════════════════════════════════
class _LessonView extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool reviewMode;
  final int seatSeconds;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final bool showPrev;

  const _LessonView({
    required this.item,
    required this.reviewMode,
    required this.seatSeconds,
    required this.onNext,
    required this.onPrev,
    required this.showPrev,
  });

  @override
  State<_LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends State<_LessonView> {
  static const int _minSeconds = 5;
  bool get _seatMet => widget.reviewMode || widget.seatSeconds >= _minSeconds;

  // PDF state
  String? _localPdfPath;
  bool    _pdfLoading = false;
  bool    _pdfError   = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void didUpdateWidget(_LessonView old) {
    super.didUpdateWidget(old);
    if (old.item['id'] != widget.item['id']) {
      _disposePdf();
      _loadPdf();
    }
  }

  void _disposePdf() {
    setState(() {
      _localPdfPath = null;
      _pdfLoading = false;
      _pdfError = false;
    });
  }

  Future<void> _loadPdf() async {
    final url = widget.item['pdf_url'] as String?;
    if (url == null || url.isEmpty) return;
    setState(() { _pdfLoading = true; _pdfError = false; });
    try {
      final response = await httpClient.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final dir  = await getTemporaryDirectory();
        final file = File('${dir.path}/lesson_${widget.item['id']}.pdf');
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) setState(() { _localPdfPath = file.path; _pdfLoading = false; });
      } else {
        if (mounted) setState(() { _pdfError = true; _pdfLoading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _pdfError = true; _pdfLoading = false; });
    }
  }

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

// ── Build HTML for video embedding to control preloading ────────
  String _buildVideoHtml(String videoUrl) {
    final driveMatch = RegExp(r'/file/d/([a-zA-Z0-9\-_]+)').firstMatch(videoUrl);
    if (driveMatch != null) {
      final fileId = driveMatch.group(1);
      final previewUrl = 'https://drive.google.com/file/d/$fileId/preview';
      return '''
<!DOCTYPE html>
<html style="height:100%;margin:0;">
  <head>
    <style>body{margin:0;height:100%;background:#0D1E33;overflow:hidden;}</style>
  </head>
  <body>
    <iframe 
      src="$previewUrl" 
      style="border:0;width:100%;height:100%;"
      loading="lazy" 
      fetchpriority="low"
      allowfullscreen
      allow="autoplay; fullscreen; picture-in-picture">
    </iframe>
  </body>
</html>
      ''';
    }
    // Direct MP4
    if (videoUrl.endsWith('.mp4') || videoUrl.contains('.mp4')) {
      return '''
<!DOCTYPE html>
<html style="height:100%;margin:0;">
  <body style="margin:0;background:#0D1E33;height:100%;">
    <video width="100%" height="100%" controls style="display:block;background:#0D1E33;">
      <source src="$videoUrl" type="video/mp4">
      Your browser does not support video playback.
    </video>
  </body>
</html>
      ''';
    }
    // Fallback iframe for other URLs
    return '''
<!DOCTYPE html>
<html style="height:100%;margin:0;">
  <body style="margin:0;background:#0D1E33;height:100%;">
    <iframe src="$videoUrl" style="border:0;width:100%;height:100%;" loading="lazy"></iframe>
  </body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    final item     = widget.item;
    final sections = (item['sections'] as List?) ?? [];
    final pdfUrl   = item['pdf_url']   as String?;
    final videoUrl = item['video_url'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _typePill('Lesson', Icons.play_circle_outline, _kBlue),
        const SizedBox(height: 8),
        Text(
          item['title'] as String? ?? '',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: _kDark,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 16),

        // ── Video player (WebView-based) ───────────────────────────
        if (videoUrl != null && videoUrl.isNotEmpty) ...[
          _buildVideoPlayer(videoUrl),
          const SizedBox(height: 16),
        ],

        // ── PDF viewer ────────────────────────────────────────────
        if (pdfUrl != null && pdfUrl.isNotEmpty) ...[
          _buildPdfViewer(pdfUrl),
          const SizedBox(height: 16),
        ],

        // ── Sections / Topics ─────────────────────────────────────
        if (sections.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _kWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x12020817)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Topics Covered',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 10),
                ...sections.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 5, color: _kBlue),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.toString(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: _kDark,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Seat timer warning ────────────────────────────────────
        if (!_seatMet) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _kBlue.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBlue.withOpacity(0.22)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 16, color: _kBlue),
                const SizedBox(width: 8),
                Text(
                  'Please spend ${_minSeconds - widget.seatSeconds}s more on this lesson.',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        _navRow(
          showPrev: widget.showPrev,
          onPrev: widget.onPrev,
          onNext: _seatMet ? widget.onNext : null,
          nextLabel: 'Continue',
        ),
      ],
    );
  }

  // ── WebView-based Video Player ────────────────────────────────────
  Widget _buildVideoPlayer(String url) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0D1E33))
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => debugPrint('WebView started loading: $url'),
          onPageFinished: (url) => debugPrint('WebView finished loading: $url'),
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description} (code: ${error.errorCode}, url: ${error.url})');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://drive.google.com/file/d/1ggzsoGR8zrXbIBNps5JK-2DE5HwNQMX1/preview'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: const Color(0x12020817)),
          ),
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline, size: 15, color: _kBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Video Lesson',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _kDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _openInBrowser(url),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBlue.withOpacity(0.22)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new, size: 12, color: _kBlue),
                      SizedBox(width: 4),
                      Text(
                        'Open',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // WebView
        Container(
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x12020817)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
          ),
          clipBehavior: Clip.antiAlias,
          child: WebViewWidget(controller: controller),
        ),
      ],
    );
  }

  // ── PDF Viewer ────────────────────────────────────────────────────
  Widget _buildPdfViewer(String url) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: const Color(0x12020817)),
          ),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 15, color: _kBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Course Material',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _kDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _openInBrowser(url),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBlue.withOpacity(0.22)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new, size: 12, color: _kBlue),
                      SizedBox(width: 4),
                      Text(
                        'Open PDF',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 480,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x12020817)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _pdfLoading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
                      SizedBox(height: 12),
                      Text(
                        'Loading PDF...',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0x88091925),
                        ),
                      ),
                    ],
                  ),
                )
              : _pdfError || _localPdfPath == null
                  ? _pdfFallback(url)
                  : PDFView(
                      filePath: _localPdfPath!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                      fitPolicy: FitPolicy.BOTH,
                      onError: (_) => setState(() => _pdfError = true),
                    ),
        ),
      ],
    );
  }

  Widget _pdfFallback(String url) => Container(
    color: const Color(0xFFF8F9FA),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf_outlined, size: 44, color: Color(0x66091925)),
          const SizedBox(height: 10),
          const Text(
            'Cannot display PDF inline',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0x88091925),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _openInBrowser(url),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new, size: 14, color: _kWhite),
                  SizedBox(width: 8),
                  Text(
                    'Open PDF in Browser',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _kWhite,
                    ),
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

// ═══════════════════════════════════════════════════════════════════
// QUIZ VIEW
// ═══════════════════════════════════════════════════════════════════
class _QuizView extends StatefulWidget {
  final Map<String, dynamic> item;
  final String courseId;
  final Map<String, dynamic>? attemptInfo;
  final bool isCheckpoint;
  final bool reviewMode;
  final VoidCallback onComplete;
  final VoidCallback onPrev;
  final Future<void> Function() onAttemptLogged;
  final Map<String, String> headers;

  const _QuizView({
    required this.item,
    required this.courseId,
    this.attemptInfo,
    required this.isCheckpoint,
    required this.reviewMode,
    required this.onComplete,
    required this.onPrev,
    required this.onAttemptLogged,
    required this.headers,
  });

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  Map<String, int> _answers = {};
  bool _submitted = false;
  int  _score     = 0;
  bool _passed    = false;

  List<Map<String, dynamic>> get _questions =>
      ((widget.item['questions'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  int  get _attemptCount => (widget.attemptInfo?['count'] as num?)?.toInt() ?? 0;
  bool get _isLocked     => !widget.reviewMode &&
      (widget.attemptInfo?['locked'] == true) &&
      (widget.attemptInfo?['unlocked_by_instructor'] != true);
  int  get _passing      => (widget.item['passingScore'] as num?)?.toInt() ?? 70;
  bool get _allAnswered  => _questions.every((q) => _answers[q['id']] != null);

  @override
  void didUpdateWidget(_QuizView old) {
    super.didUpdateWidget(old);
    if (old.item['id'] != widget.item['id']) _reset();
  }

  void _reset() => setState(() {
    _answers   = {};
    _submitted = false;
    _score     = 0;
    _passed    = false;
  });

  Future<void> _submit() async {
    final correct = _questions
        .where((q) => _answers[q['id']] == (q['correct'] as num?)?.toInt())
        .length;
    final pct = (_questions.isEmpty ? 0 : (correct / _questions.length * 100)).round();
    final ok  = pct >= _passing;
    setState(() { _score = pct; _passed = ok; _submitted = true; });
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/quiz-attempts'),
        headers: widget.headers,
        body: jsonEncode({
          'courseId':    widget.courseId,
          'quizId':      widget.item['id'],
          'quizTitle':   widget.item['title'],
          'quizType':    widget.isCheckpoint ? 'checkpoint' : widget.item['id'] == 'final-exam' ? 'final_exam' : 'quiz_fundamentals',
          'moduleOrder': widget.item['moduleOrder'],
          'scorePct':    pct,
          'correct':     correct,
          'total':       _questions.length,
          'passed':      ok,
          'passingScore': _passing,
          'answers':     _answers,
        }),
      ).timeout(const Duration(seconds: 10));
      await widget.onAttemptLogged();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) return _buildLocked();
    if (widget.reviewMode) return _buildReviewMode();

    final type    = widget.item['type'] as String? ?? '';
    final isFinal = type == 'quiz';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _typePill(
          isFinal ? 'Final Exam' : widget.isCheckpoint ? 'Checkpoint' : 'Fundamentals Exam',
          isFinal ? Icons.emoji_events_outlined : Icons.assignment_outlined,
          isFinal ? _kGreen : _kAmber,
        ),
        const SizedBox(height: 8),
        Text(
          widget.item['title'] as String? ?? '',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: _kDark,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Score $_passing%+ to pass · ${_questions.length} questions',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0x88091925),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (!_submitted) _buildAttemptWarning(),
        if (_submitted) _buildScoreResult(),
        const SizedBox(height: 16),
        ..._questions.asMap().entries.map((e) => _buildQuestion(e.key, e.value)),
        const SizedBox(height: 24),
        _navRow(
          showPrev: !_submitted,
          onPrev: widget.onPrev,
          onNext: _submitted
              ? (_passed ? widget.onComplete : null)
              : (_allAnswered ? _submit : null),
          nextLabel: _submitted
              ? (_passed ? (isFinal ? 'Complete Course 🎉' : 'Continue') : null)
              : 'Submit',
          retryLabel: _submitted && !_passed ? 'Try Again' : null,
          onRetry: _submitted && !_passed ? _reset : null,
        ),
      ],
    );
  }

  Widget _buildAttemptWarning() {
    if (_attemptCount == 0) {
      return _warningBanner('Attempt 1 of 3', 'Read each question carefully.', _kBlue);
    }
    if (_attemptCount == 1) {
      return _warningBanner('⚠️ Attempt 2 of 3 — One Retake Left', '1 retake remaining. Fail again = locked.', _kAmber);
    }
    return _warningBanner('🔴 Final Attempt — Attempt 3 of 3', 'This is your last attempt. Fail = permanently locked.', _kRed);
  }

  Widget _warningBanner(String title, String sub, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.30)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 13, color: color)),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
      ],
    ),
  );

  Widget _buildScoreResult() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _passed ? _kGreen.withOpacity(0.08) : _kRed.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _passed ? _kGreen.withOpacity(0.25) : _kRed.withOpacity(0.20)),
    ),
    child: Column(
      children: [
        Text(
          '$_score%',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            fontSize: 42,
            color: _passed ? const Color(0xFF15803D) : _kRed,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _passed ? '✓ Passed!' : 'Need $_passing% — got $_score%',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: _passed ? const Color(0xFF15803D) : _kRed,
          ),
        ),
      ],
    ),
  );

  Widget _buildQuestion(int qi, Map<String, dynamic> q) {
    final qid     = q['id'] as String;
    final options = (q['options'] as List?) ?? [];
    final correct = (q['correct'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x12020817)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${qi + 1} of ${_questions.length}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0x66091925),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            q['text'] as String? ?? '',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _kDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...options.asMap().entries.map((e) {
            final oi         = e.key;
            final opt        = e.value.toString();
            final isSelected = _answers[qid] == oi;
            final isCorrect  = _submitted && oi == correct;
            final isWrong    = _submitted && isSelected && oi != correct;

            Color borderColor = const Color(0x1A020817);
            Color bgColor     = const Color(0x03020817);
            if (isSelected && !_submitted) {
              borderColor = _kBlue.withOpacity(0.5);
              bgColor     = _kBlue.withOpacity(0.06);
            }
            if (isCorrect) {
              borderColor = _kGreen.withOpacity(0.5);
              bgColor     = _kGreen.withOpacity(0.06);
            }
            if (isWrong) {
              borderColor = _kRed.withOpacity(0.5);
              bgColor     = _kRed.withOpacity(0.06);
            }

            return GestureDetector(
              onTap: () { if (!_submitted) setState(() => _answers[qid] = oi); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0x0A020817),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        String.fromCharCode(65 + oi),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xB3091925),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        opt,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kDark,
                        ),
                      ),
                    ),
                    if (isCorrect) const Icon(Icons.check_circle_rounded, size: 16, color: _kGreen),
                    if (isWrong)   const Icon(Icons.cancel_rounded, size: 16, color: _kRed),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLocked() => Column(
    children: [
      _typePill('Exam Locked', Icons.lock_outline, _kRed),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _kRed.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kRed.withOpacity(0.25)),
        ),
        child: const Column(
          children: [
            Icon(Icons.lock_rounded, size: 40, color: Color(0xB3B91C1C)),
            SizedBox(height: 14),
            Text(
              'Instructor Approval Required',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFFB91C1C),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You have failed this exam 3 times.\nPlease contact your instructor to unlock.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _kDark,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _navRow(showPrev: true, onPrev: widget.onPrev, onNext: null, nextLabel: null),
    ],
  );

  Widget _buildReviewMode() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        _typePill(widget.isCheckpoint ? 'Checkpoint' : 'Exam', Icons.assignment_outlined, _kAmber),
        const SizedBox(width: 8),
        _typePill('Review', Icons.visibility_outlined, _kAmber),
      ]),
      const SizedBox(height: 8),
      Text(
        widget.item['title'] as String? ?? '',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w900,
          fontSize: 20,
          color: _kDark,
          height: 1.25,
        ),
      ),
      const SizedBox(height: 16),
      if (widget.attemptInfo != null) _buildBestAttempt(),
      const SizedBox(height: 16),
      ..._questions.asMap().entries.map((e) => _buildQuestion(e.key, e.value)),
      const SizedBox(height: 24),
      _navRow(
        showPrev: true,
        onPrev: widget.onPrev,
        onNext: widget.onComplete,
        nextLabel: 'Next',
      ),
    ],
  );

  Widget _buildBestAttempt() {
    final attempts = (widget.attemptInfo?['attempts'] as List?) ?? [];
    if (attempts.isEmpty) return const SizedBox.shrink();
    final best = attempts.reduce((a, b) =>
        ((a['score_pct'] as num?) ?? 0) > ((b['score_pct'] as num?) ?? 0) ? a : b);
    final pct    = (best['score_pct'] as num?)?.toInt() ?? 0;
    final passed = best['passed'] == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: passed ? _kGreen.withOpacity(0.08) : _kRed.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: passed ? _kGreen.withOpacity(0.25) : _kRed.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$pct%',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: passed ? const Color(0xFF15803D) : _kRed,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            passed ? '✓ Passed' : '✗ Failed',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: passed ? const Color(0xFF15803D) : _kRed,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// REVIEW SUMMARY VIEW
// ═══════════════════════════════════════════════════════════════════
class _ReviewSummaryView extends StatelessWidget {
  final Map<String, dynamic> course;
  final String courseId;
  final List<Map<String, dynamic>> content;
  final Map<String, dynamic> quizAttempts;
  final Map<String, dynamic>? transcriptEntry;
  final VoidCallback onPrev;
  final VoidCallback onDone;
  final Map<String, String> headers;

  const _ReviewSummaryView({
    required this.course,
    required this.courseId,
    required this.content,
    required this.quizAttempts,
    this.transcriptEntry,
    required this.onPrev,
    required this.onDone,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    final modules = ((course['modules'] as List?) ?? [])
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList()
      ..sort((a, b) => ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0));

    final quizItems = content
        .where((c) => ['checkpoint', 'quiz_fundamentals', 'quiz'].contains(c['type']))
        .toList();

    final scores = quizItems.map((q) {
      final attempts = (quizAttempts[q['id']]?['attempts'] as List?) ?? [];
      if (attempts.isEmpty) return null;
      final best = attempts.reduce((a, b) =>
          ((a['score_pct'] as num?) ?? 0) > ((b['score_pct'] as num?) ?? 0) ? a : b);
      return (best['score_pct'] as num?)?.toInt() ?? 0;
    }).whereType<int>().toList();

    final overallGrade = scores.isEmpty
        ? null
        : (scores.reduce((a, b) => a + b) / scores.length).round();
    final completedAt = transcriptEntry?['completed_at'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _typePill('Course Summary', Icons.emoji_events_outlined, _kAmber),
          const SizedBox(width: 8),
          _typePill('Review', Icons.visibility_outlined, _kAmber),
        ]),
        const SizedBox(height: 12),
        Text(
          course['title'] as String? ?? '',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: _kDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        // Grade card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: overallGrade != null && overallGrade >= 70
                ? _kGreen.withOpacity(0.08)
                : const Color(0x05020817),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: overallGrade != null && overallGrade >= 70
                  ? _kGreen.withOpacity(0.25)
                  : const Color(0x14020817),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'OVERALL GRADE',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0x72091925),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                overallGrade != null ? '$overallGrade%' : '—',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w900,
                  fontSize: 52,
                  letterSpacing: -2,
                  color: overallGrade == null
                      ? const Color(0x72091925)
                      : overallGrade >= 70
                          ? const Color(0xFF15803D)
                          : _kRed,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                overallGrade == null
                    ? 'No quiz data'
                    : overallGrade >= 70
                        ? '✓ Passing — All requirements met'
                        : 'Below passing threshold',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0x88091925),
                ),
              ),
              if (completedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Completed on ${_fmtDate(completedAt)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0x66091925),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Credit hours by module
        Container(
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x12020817)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Icon(Icons.schedule_outlined, size: 14, color: Color(0x88091925)),
                    SizedBox(width: 8),
                    Text(
                      'Credit Hours by Module',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Color(0x88091925),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x12020817)),
              ...modules.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: _kBlue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kBlue.withOpacity(0.20)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _kBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value['title'] as String? ?? '',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                        ),
                      ),
                    ),
                    Text(
                      '${e.value['credit_hours'] ?? 0} hrs',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xB3091925),
                      ),
                    ),
                  ],
                ),
              )),
              const Divider(height: 1, color: Color(0x12020817)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Credit Hours',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: _kDark,
                      ),
                    ),
                    Text(
                      '${course['credit_hours'] ?? 0} hrs',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: _kBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _prevBtn(onPrev),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onDone,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: _kAmber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kAmber.withOpacity(0.35)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium, size: 16, color: Color(0xFF925400)),
                      SizedBox(width: 8),
                      Text(
                        'Done',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Color(0xFF925400),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) { return iso; }
  }
}

// ═══════════════════════════════════════════════════════════════════
// COMPLETION SCREEN
// ═══════════════════════════════════════════════════════════════════
class _CompletionScreen extends StatelessWidget {
  final Map<String, dynamic>? course;
  final Map<String, dynamic>? transcriptEntry;
  final VoidCallback onReview;
  final VoidCallback onDashboard;

  const _CompletionScreen({
    this.course,
    this.transcriptEntry,
    required this.onReview,
    required this.onDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final completedAt = transcriptEntry?['completed_at'] as String?;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF0D2A4A)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded, color: _kAmber, size: 24),
                      Icon(Icons.star_rounded, color: _kAmber, size: 24),
                      Icon(Icons.star_rounded, color: _kAmber, size: 24),
                      Icon(Icons.star_rounded, color: _kAmber, size: 24),
                      Icon(Icons.star_rounded, color: _kAmber, size: 24),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      color: _kAmber.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: _kAmber.withOpacity(0.30), width: 2),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: _kAmber, size: 36),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Course Complete! 🎉',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      color: _kDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Congratulations! You've successfully completed",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Color(0x8C0A1628),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kBlue.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBlue.withOpacity(0.18)),
                    ),
                    child: Text(
                      course?['title'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _kDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Column(
                    children: [
                      _metaItem('✓ ${course?['credit_hours'] ?? 0} Credit Hours Earned'),
                      if (completedAt != null) _metaItem('✓ Completed on ${_fmtDate(completedAt)}'),
                      _metaItem('✓ Certificate Unlocked'),
                      _metaItem('✓ NMLS Requirements Met'),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _actionBtn('Review Course', Icons.visibility_outlined, _kBlue, onReview),
                  const SizedBox(height: 10),
                  _actionBtn('Go to Dashboard', Icons.dashboard_outlined, _kDark, onDashboard),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaItem(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF15803D),
      ),
    ),
  );

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: _kWhite),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: _kWhite,
                ),
              ),
            ],
          ),
        ),
      );

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) { return iso; }
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════════════
Widget _typePill(String label, IconData icon, Color color) => Container(
  margin: const EdgeInsets.only(bottom: 4),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
  decoration: BoxDecoration(
    color: color.withOpacity(0.10),
    borderRadius: BorderRadius.circular(99),
    border: Border.all(color: color.withOpacity(0.28)),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    ],
  ),
);

Widget _navRow({
  required bool showPrev,
  required VoidCallback? onPrev,
  required VoidCallback? onNext,
  required String? nextLabel,
  String? retryLabel,
  VoidCallback? onRetry,
}) =>
    Row(
      children: [
        if (showPrev) _prevBtn(onPrev!),
        if (showPrev) const SizedBox(width: 10),
        if (retryLabel != null && onRetry != null) ...[
          Expanded(
            child: GestureDetector(
              onTap: onRetry,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: _kRed.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 16, color: _kWhite),
                    const SizedBox(width: 6),
                    Text(
                      retryLabel,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: _kWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else if (nextLabel != null) ...[
          Expanded(
            child: GestureDetector(
              onTap: onNext,
              child: Opacity(
                opacity: onNext == null ? 0.45 : 1.0,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: _kBlue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _kBlue.withOpacity(0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nextLabel,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: _kWhite,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: _kWhite),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );

Widget _prevBtn(VoidCallback onTap) => GestureDetector(
  onTap: onTap,
  child: Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: _kWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x1A020817)),
    ),
    child: const Row(
      children: [
        Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xB3091925)),
        SizedBox(width: 6),
        Text(
          'Previous',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Color(0xB3091925),
          ),
        ),
      ],
    ),
  ),
);