import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nmls_mobile/config/api_config.dart';
import 'package:nmls_mobile/catalog/token_provider.dart';
import 'package:nmls_mobile/services/auth_service.dart';

const kPrepDark = Color(0xFF091925);
const kPrepBlue = Color(0xFF2EABFE);
const kPrepTeal = Color(0xFF00B4B4);
const kPrepAmber = Color(0xFFF59E0B);
const kPrepBg = Color(0xFFF6F7FB);
const kPrepWhite = Colors.white;
const kPrepMuted = Color(0x990B1220);
const kPrepBorder = Color(0x1A020817);

class ExamPrepCenterScreen extends StatefulWidget {
  final String? token;
  final ExamPrepInitialMode? initialMode;
  final String? initialDrillTopic;
  final int? initialDrillCount;

  // When launched from the outer "Exam Prep" landing page, we hide extra sections
  // so analytics/readiness stay outside the full exam experience.
  final bool showReadiness;
  final bool showPracticeModes;
  final bool showAnalytics;
  final bool popToDashboardOnEndSession;

  const ExamPrepCenterScreen({
    super.key,
    this.token,
    this.initialMode,
    this.initialDrillTopic,
    this.initialDrillCount,
    this.showReadiness = true,
    this.showPracticeModes = true,
    this.showAnalytics = true,
    this.popToDashboardOnEndSession = false,
  });

  @override
  State<ExamPrepCenterScreen> createState() => _ExamPrepCenterScreenState();
}

enum ExamPrepInitialMode { simulator, drill }

class _ExamPrepCenterScreenState extends State<ExamPrepCenterScreen> {
  static const List<String> _defaultTopics = <String>[
    'Federal Law',
    'Ethics',
    'Nontraditional Products',
    'Math and Finance',
    'State Compliance',
  ];

  List<_PrepQuestion> _questionBank = <_PrepQuestion>[];
  List<_FlashcardItem> _flashcards = _buildFlashcards();

  final List<_SessionResult> _history = <_SessionResult>[];

  Timer? _timer;
  DateTime? _sessionStartedAt;
  List<_PrepQuestion> _activeQuestions = <_PrepQuestion>[];
  Map<int, int> _answers = <int, int>{};
  int _questionIndex = 0;
  int _secondsRemaining = 0;
  bool _isSessionSubmitted = false;
  String _activeMode = '';
  bool _isLoadingQuestions = true;
  bool _isLoadingAnalytics = true;
  String _loadError = '';

  bool _didAutoStart = false;

  String _drillTopic = _defaultTopics.first;
  int _drillCount = 12;
  // Tracks flipped state by stable card identity so filtering doesn't break flips.
  final Set<String> _flippedCardKeys = <String>{};
  // Used to reduce repeats across the last few sessions.
  final List<Set<String>> _recentSessionQuestionKeys = <Set<String>>[];
  String _flashTopicFilter = 'All';
  String _flashDifficultyFilter = 'All';

  Future<Map<String, String>> _buildHeaders() async {
    final token = (widget.token != null && widget.token!.trim().isNotEmpty)
        ? widget.token!.trim()
        : await SharedPreferencesTokenProvider().getToken();

    return <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  List<String> get _topics {
    final discovered = _questionBank.map((q) => q.topic).toSet().toList()
      ..sort();
    return discovered.isEmpty ? List<String>.from(_defaultTopics) : discovered;
  }

  bool get _hasQuestionBank => _questionBank.isNotEmpty;

  List<String> get _flashcardTopics {
    final set =
        _flashcards
            .map((c) => c.topic)
            .where((e) => e.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...set];
  }

  List<_FlashcardItem> get _filteredFlashcards {
    final filtered = _flashcards.where((card) {
      final topicMatch =
          _flashTopicFilter == 'All' || card.topic == _flashTopicFilter;
      final difficultyMatch =
          _flashDifficultyFilter == 'All' ||
          card.difficulty.toLowerCase() == _flashDifficultyFilter.toLowerCase();
      return topicMatch && difficultyMatch;
    }).toList();

    // Sort so weak topics appear first; then hardest cards.
    final weakTopics = _weakAreas.toSet();

    int difficultyRank(String difficulty) {
      switch (difficulty.toLowerCase()) {
        case 'hard':
          return 0;
        case 'medium':
          return 1;
        case 'easy':
          return 2;
        default:
          return 3;
      }
    }

    filtered.sort((a, b) {
      final aWeak = weakTopics.contains(a.topic) ? 0 : 1;
      final bWeak = weakTopics.contains(b.topic) ? 0 : 1;
      if (aWeak != bWeak) return aWeak - bWeak;

      final aDiff = difficultyRank(a.difficulty);
      final bDiff = difficultyRank(b.difficulty);
      if (aDiff != bDiff) return aDiff - bDiff;

      final topicCmp = a.topic.compareTo(b.topic);
      if (topicCmp != 0) return topicCmp;
      return a.term.compareTo(b.term);
    });

    // Avoid huge horizontal lists.
    return filtered.length > 30 ? filtered.take(30).toList() : filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    if (widget.showAnalytics) {
      _loadAnalytics();
    } else {
      // Keep analytics spinner logic consistent with UI.
      _isLoadingAnalytics = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _hasActiveSession => _activeQuestions.isNotEmpty;

  double get _readinessScore {
    if (_history.isEmpty) return 0.0;
    // Exponential weighting: most recent sessions matter more.
    final recent = _history.length > 8
        ? _history.sublist(_history.length - 8)
        : _history;
    final scores = recent.map((e) => e.scorePercent).toList();

    double weightedSum = 0.0;
    double weightSum = 0.0;
    for (int i = 0; i < scores.length; i++) {
      // age=0 for newest score, increasing for older scores.
      final age = scores.length - 1 - i;
      final w = pow(0.85, age).toDouble();
      weightedSum += scores[i] * w;
      weightSum += w;
    }

    return weightSum == 0 ? 0.0 : (weightedSum / weightSum).clamp(0.0, 1.0);
  }

  Map<String, double> get _topicAverages {
    final totals = <String, int>{};
    final attempts = <String, int>{};

    for (final result in _history) {
      result.topicStats.forEach((topic, stat) {
        totals[topic] = (totals[topic] ?? 0) + stat.correct;
        attempts[topic] = (attempts[topic] ?? 0) + stat.total;
      });
    }

    final output = <String, double>{};
    for (final topic in _topics) {
      final total = attempts[topic] ?? 0;
      if (total == 0) {
        output[topic] = 0;
      } else {
        output[topic] = (totals[topic] ?? 0) / total;
      }
    }
    return output;
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoadingQuestions = true;
      _loadError = '';
    });

    try {
      final headers = await _buildHeaders();
      final res = await http
          .get(Uri.parse(ApiConfig.examPrepQuestions), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        if (res.statusCode == 401 || res.statusCode == 403) {
          await AuthService.logout();
          setState(() {
            _loadError = 'Session expired. Please sign in again.';
            _questionBank = <_PrepQuestion>[];
          });
          return;
        }
        setState(() {
          _loadError = 'Failed to load exam bank (${res.statusCode})';
          _questionBank = <_PrepQuestion>[];
        });
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final rawQuestions = (data['questions'] as List?) ?? const [];
      final rawFlashcards = (data['flashcards'] as List?) ?? const [];
      final questions = rawQuestions
          .whereType<Map>()
          .map((e) => _PrepQuestion.fromApi(Map<String, dynamic>.from(e)))
          .where((q) => q != null)
          .cast<_PrepQuestion>()
          .toList();

      final flashcards = rawFlashcards
          .whereType<Map>()
          .map((e) => _FlashcardItem.fromApi(Map<String, dynamic>.from(e)))
          .where((c) => c != null)
          .cast<_FlashcardItem>()
          .toList();

      setState(() {
        _questionBank = questions;
        _flashcards = flashcards.isEmpty ? _buildFlashcards() : flashcards;
        _flashTopicFilter = 'All';
        _flashDifficultyFilter = 'All';
        if (_topics.isNotEmpty) {
          _drillTopic = _topics.first;
        }
      });

      // Auto-start requested mode (when launched from outer landing page).
      if (!_didAutoStart && widget.initialMode != null) {
        _tryAutoStart();
      }
    } catch (_) {
      setState(() {
        _loadError = 'Unable to reach exam API. Please retry.';
        _questionBank = <_PrepQuestion>[];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingQuestions = false);
      }
    }
  }

  void _tryAutoStart() {
    if (_didAutoStart) return;
    if (_questionBank.isEmpty) return;

    // Auto-start only once questions are available.
    _didAutoStart = true;

    if (widget.initialMode == ExamPrepInitialMode.simulator) {
      _startSimulator();
      return;
    }

    if (widget.initialMode == ExamPrepInitialMode.drill) {
      if (widget.initialDrillTopic != null && widget.initialDrillTopic!.isNotEmpty) {
        // Use provided topic only if it exists in the loaded topic list.
        final candidate = widget.initialDrillTopic!.trim();
        if (_topics.contains(candidate)) {
          _drillTopic = candidate;
        }
      }
      if (widget.initialDrillCount != null && widget.initialDrillCount! >= 8) {
        _drillCount = widget.initialDrillCount!;
      }
      _startDrill();
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoadingAnalytics = true);

    try {
      final headers = await _buildHeaders();
      final res = await http
          .get(Uri.parse(ApiConfig.examPrepAnalytics), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        if (res.statusCode == 401 || res.statusCode == 403) {
          await AuthService.logout();
        }
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final trend = (data['trend'] as List?) ?? const [];
      final topicScores = (data['topicScores'] as List?) ?? const [];

      if (trend.isEmpty && topicScores.isEmpty) return;

      final topicStats = <String, _TopicStat>{};
      for (final row in topicScores.whereType<Map>()) {
        final item = Map<String, dynamic>.from(row);
        final title = (item['title'] ?? '').toString().trim();
        final avg = (item['average'] as num?)?.toDouble() ?? 0.0;
        final attempts = (item['attempts'] as num?)?.toInt() ?? 0;
        if (title.isEmpty || attempts <= 0) continue;

        final total = attempts * 10;
        final correct = (avg * total).round();
        topicStats[title] = _TopicStat(correct: correct, total: total);
      }

      final trendNums = trend.whereType<num>().toList();
      final seededScore = (trendNums.isEmpty ? 0.0 : trendNums.last.toDouble())
          .clamp(0.0, 1.0);

      if (topicStats.isNotEmpty || seededScore > 0) {
        final total = topicStats.values.fold<int>(0, (sum, e) => sum + e.total);
        final correct = topicStats.values.fold<int>(
          0,
          (sum, e) => sum + e.correct,
        );

        _history.add(
          _SessionResult(
            mode: 'Historical Performance',
            total: total == 0 ? 10 : total,
            correct: total == 0 ? (seededScore * 10).round() : correct,
            completedAt: DateTime.now().subtract(const Duration(minutes: 1)),
            topicStats: topicStats,
          ),
        );
      }
    } catch (_) {
      // Analytics is supplemental; ignore fetch errors silently.
    } finally {
      if (mounted) setState(() => _isLoadingAnalytics = false);
    }
  }

  List<String> get _weakAreas {
    final avg = _topicAverages;
    final weak = avg.entries
        .where((e) => e.value > 0 && e.value < 0.72)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return weak.map((e) => e.key).take(5).toList();
  }

  String _questionKey(_PrepQuestion q) => '${q.topic}::${q.prompt}';

  String _flashcardKey(_FlashcardItem card) => '${card.topic}::${card.term}';

  List<double> get _progressSeries {
    if (_history.isEmpty) return <double>[];
    final recent = _history.length > 10
        ? _history.sublist(_history.length - 10)
        : _history;
    return recent.map((e) => e.scorePercent).toList();
  }

  void _startSimulator() {
    if (!_hasQuestionBank) {
      _showMessage('Exam questions are not loaded yet.');
      return;
    }
    const requested = 40;
    final questions = _randomQuestions(count: requested);
    if (questions.length < requested) {
      _showMessage('Only ${questions.length} unique questions available right now.');
    }
    _startSession(
      mode: 'Full Exam Simulator',
      questions: questions,
      durationSeconds: 60 * 60,
    );
  }

  void _startDrill() {
    if (!_hasQuestionBank) {
      _showMessage('Exam questions are not loaded yet.');
      return;
    }
    final requested = _drillCount;
    final questions = _randomQuestions(count: requested, topic: _drillTopic);
    if (questions.length < requested) {
      _showMessage('Only ${questions.length} unique questions available for "$_drillTopic".');
    }
    _startSession(
      mode: 'Topic Drill: $_drillTopic',
      questions: questions,
      durationSeconds: 18 * 60,
    );
  }

  void _startSession({
    required String mode,
    required List<_PrepQuestion> questions,
    required int durationSeconds,
  }) {
    _timer?.cancel();
    setState(() {
      _activeMode = mode;
      _activeQuestions = questions;
      _answers = <int, int>{};
      _questionIndex = 0;
      _secondsRemaining = durationSeconds;
      _isSessionSubmitted = false;
      _sessionStartedAt = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _submitSession(autoSubmitted: true);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  void _stopSession() {
    _timer?.cancel();
    setState(() {
      _activeQuestions = <_PrepQuestion>[];
      _answers = <int, int>{};
      _questionIndex = 0;
      _secondsRemaining = 0;
      _isSessionSubmitted = false;
      _activeMode = '';
      _sessionStartedAt = null;
    });

    if (widget.popToDashboardOnEndSession) {
      Navigator.of(context).maybePop();
    }
  }

  void _submitSession({bool autoSubmitted = false}) {
    if (_activeQuestions.isEmpty || _isSessionSubmitted) return;
    _timer?.cancel();

    int correct = 0;
    final topicTotals = <String, _TopicStat>{};

    for (int i = 0; i < _activeQuestions.length; i++) {
      final q = _activeQuestions[i];
      final selected = _answers[i];
      final wasCorrect = selected == q.correctIndex;
      if (wasCorrect) correct++;

      final current =
          topicTotals[q.topic] ?? const _TopicStat(correct: 0, total: 0);
      topicTotals[q.topic] = _TopicStat(
        correct: current.correct + (wasCorrect ? 1 : 0),
        total: current.total + 1,
      );
    }

    final result = _SessionResult(
      mode: _activeMode,
      total: _activeQuestions.length,
      correct: correct,
      topicStats: topicTotals,
      completedAt: DateTime.now(),
    );

    setState(() {
      _isSessionSubmitted = true;
      _history.add(result);
    });

    // Reduce repeats across the next sessions (simulator/drills).
    final sessionKeys = _activeQuestions.map(_questionKey).toSet();
    _recentSessionQuestionKeys.add(sessionKeys);
    if (_recentSessionQuestionKeys.length > 3) {
      _recentSessionQuestionKeys.removeAt(0);
    }

    final elapsed = _sessionStartedAt == null
        ? 0
        : DateTime.now().difference(_sessionStartedAt!).inSeconds;
    _saveAttempt(result, elapsed);

    final percent = (result.scorePercent * 100).toStringAsFixed(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          autoSubmitted
              ? 'Time up. Session submitted at $percent%.'
              : 'Session submitted at $percent%.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<_PrepQuestion> _randomQuestions({required int count, String? topic}) {
    if (_questionBank.isEmpty || count <= 0) return <_PrepQuestion>[];

    final rng = Random();

    final excluded = <String>{};
    for (final set in _recentSessionQuestionKeys) {
      excluded.addAll(set);
    }

    final base = topic == null
        ? List<_PrepQuestion>.from(_questionBank)
        : _questionBank.where((q) => q.topic == topic).toList();

    if (base.isEmpty) return <_PrepQuestion>[];

    // Drill mode: topic is fixed, keep selection unbiased but avoid repeats.
    if (topic != null) {
      final pool = base.where((q) => !excluded.contains(_questionKey(q))).toList();
      pool.shuffle(rng);

      final out = <_PrepQuestion>[];
      out.addAll(pool.take(count));
      if (out.length >= count) return out;

      // Not enough new questions; fill with the remaining unique questions.
      final already = out.map(_questionKey).toSet();
      final remaining = base.where((q) => !already.contains(_questionKey(q))).toList();
      remaining.shuffle(rng);
      out.addAll(remaining.take(count - out.length));
      return out;
    }

    // Simulator mode: choose questions from weak topics more often.
    double weightForTopic(String t) {
      final avg = _topicAverages[t] ?? 0.0; // avg==0 -> no attempts yet
      if (avg <= 0) return 1.0;
      final weakBoost = 0.72 - avg;
      final w = 1.0 + (weakBoost > 0 ? weakBoost * 2.5 : 0.0);
      return w.clamp(1.0, 3.5);
    }

    final pool = base.where((q) => !excluded.contains(_questionKey(q))).toList();
    if (pool.isEmpty) {
      // Fallback: all questions are in recent sessions. Allow selection anyway.
      final fallback = List<_PrepQuestion>.from(base)..shuffle(rng);
      return fallback.take(count).toList();
    }

    final byTopic = <String, List<_PrepQuestion>>{};
    for (final q in pool) {
      byTopic.putIfAbsent(q.topic, () => <_PrepQuestion>[]).add(q);
    }

    final out = <_PrepQuestion>[];
    while (out.length < count) {
      final availableTopics =
          byTopic.entries.where((e) => e.value.isNotEmpty).map((e) => e.key).toList();
      if (availableTopics.isEmpty) break;

      final totalW = availableTopics.fold<double>(
        0.0,
        (sum, t) => sum + weightForTopic(t),
      );

      // Weighted random pick of a topic.
      final pick = totalW <= 0
          ? availableTopics[rng.nextInt(availableTopics.length)]
          : (() {
              var r = rng.nextDouble() * totalW;
              for (final t in availableTopics) {
                r -= weightForTopic(t);
                if (r <= 0) return t;
              }
              return availableTopics.last;
            })();

      final bucket = byTopic[pick];
      if (bucket == null || bucket.isEmpty) continue;

      final idx = rng.nextInt(bucket.length);
      out.add(bucket.removeAt(idx));
    }

    // Fill any shortfall from remaining unique questions.
    if (out.length < count) {
      final already = out.map(_questionKey).toSet();
      final remaining = base.where((q) => !already.contains(_questionKey(q))).toList();
      remaining.shuffle(rng);
      out.addAll(remaining.take(count - out.length));
    }

    return out;
  }

  Future<void> _saveAttempt(_SessionResult result, int timeSpentSeconds) async {
    try {
      final headers = await _buildHeaders();
      await http.post(
        Uri.parse(ApiConfig.examPrepAttempt),
        headers: headers,
        body: jsonEncode({
          'mode': result.mode,
          'total': result.total,
          'correct': result.correct,
          'timeSpentSeconds': timeSpentSeconds,
          'topicStats': result.topicStats.map(
            (key, value) =>
                MapEntry(key, {'correct': value.correct, 'total': value.total}),
          ),
        }),
      );
    } catch (_) {
      // Keep local progress even if persistence fails.
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatClock(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrepBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: _isLoadingQuestions
                  ? const Center(child: CircularProgressIndicator())
                  : !_hasQuestionBank
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.quiz_outlined,
                                  size: 34,
                                  color: kPrepDark,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _loadError.isNotEmpty
                                      ? _loadError
                                      : 'No exam questions found in database.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: kPrepDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadQuestions,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.showReadiness) ...[
                                _buildReadinessCard(),
                                const SizedBox(height: 12),
                              ],
                              if (widget.showPracticeModes) ...[
                                _buildPracticeModes(),
                                const SizedBox(height: 12),
                              ],
                              if (_hasActiveSession) ...[
                                _buildSessionPanel(),
                                const SizedBox(height: 12),
                              ],
                              _buildFlashcardSection(),
                              if (widget.showAnalytics) ...[
                                const SizedBox(height: 12),
                                _buildAnalyticsSection(),
                                if (_isLoadingAnalytics) ...[
                                  const SizedBox(height: 6),
                                  const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: const BoxDecoration(
        color: kPrepDark,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: kPrepWhite),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Exam Prep Center',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: kPrepWhite,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessCard() {
    final readiness = _readinessScore;
    final pct = (readiness * 100).round();
    final weak = _weakAreas;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF091925), Color(0xFF0B2A3A), Color(0xFF2EABFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: readiness,
                  strokeWidth: 7,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(kPrepTeal),
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: kPrepWhite,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Readiness Indicator',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  readiness >= 0.8
                      ? 'Exam-ready. Keep pace with mixed practice.'
                      : readiness >= 0.65
                      ? 'Close to ready. Focus on weak topics.'
                      : 'Foundation stage. Prioritize drills first.',
                  style: const TextStyle(
                    color: Color(0xDDEAF3FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  weak.isEmpty
                      ? 'No weak areas detected yet.'
                      : 'Weak areas: ${weak.join(', ')}',
                  style: const TextStyle(
                    color: Color(0xFFD8E8FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeModes() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrepWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrepBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRACTICE MODES',
            style: TextStyle(
              color: kPrepDark,
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool stackCards = constraints.maxWidth < 760;

              final simulatorCard = _modeCard(
                title: 'Full Exam',
                subtitle: '40 randomized questions · 60 minutes',
                icon: Icons.description_outlined,
                color: kPrepBlue,
                onTap: _startSimulator,
              );

              final drillCard = _modeCard(
                title: 'Topic Drill',
                subtitle: 'One topic · timed drill',
                icon: Icons.access_time,
                color: kPrepTeal,
                onTap: _startDrill,
                controls: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _drillTopic,
                      isDense: true,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Topic',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      items: _topics
                          .map(
                            (topic) => DropdownMenuItem<String>(
                              value: topic,
                              child: Text(
                                topic,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _drillTopic = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Questions',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: kPrepMuted,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _drillCount.toDouble(),
                            min: 8,
                            max: 25,
                            divisions: 17,
                            label: '$_drillCount',
                            onChanged: (v) {
                              setState(() => _drillCount = v.round());
                            },
                          ),
                        ),
                        Text(
                          '$_drillCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: kPrepDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (stackCards) {
                return Column(
                  children: [
                    simulatorCard,
                    const SizedBox(height: 10),
                    drillCard,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: simulatorCard),
                  const SizedBox(width: 10),
                  Expanded(child: drillCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _modeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Widget? controls,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color == kPrepBlue ? kPrepDark : kPrepWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color == kPrepBlue
                ? Colors.transparent
                : kPrepBorder.withOpacity(0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                color: (color == kPrepBlue ? kPrepBlue : kPrepBlue)
                    .withOpacity(color == kPrepBlue ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (color == kPrepBlue ? kPrepBlue : kPrepBlue)
                      .withOpacity(0.18),
                ),
              ),
              child: Icon(
                icon,
                color: color == kPrepBlue ? kPrepBlue : const Color(0xFF6B8397),
                size: 20,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: color == kPrepBlue ? kPrepWhite : kPrepDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: color == kPrepBlue
                    ? const Color(0xFF7D92A3)
                    : kPrepMuted,
              ),
            ),
            if (controls != null) ...[
              const SizedBox(height: 12),
              controls,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionPanel() {
    final question = _activeQuestions[_questionIndex];
    final answered = _answers.length;
    final progress = (_questionIndex + 1) / _activeQuestions.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrepWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrepBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _activeMode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: kPrepDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kPrepAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: kPrepAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatClock(_secondsRemaining),
                      style: const TextStyle(
                        color: kPrepDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: const Color(0xFFEAF1FA),
            valueColor: const AlwaysStoppedAnimation<Color>(kPrepBlue),
          ),
          const SizedBox(height: 8),
          Text(
            'Question ${_questionIndex + 1}/${_activeQuestions.length} • Answered $answered',
            style: const TextStyle(
              color: kPrepMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question.topic,
            style: const TextStyle(
              color: kPrepBlue,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            question.prompt,
            style: const TextStyle(
              color: kPrepDark,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(question.options.length, (i) {
            final selected = _answers[_questionIndex] == i;
            final showCorrect =
                _isSessionSubmitted && i == question.correctIndex;
            final showWrong =
                _isSessionSubmitted && selected && i != question.correctIndex;

            final tileColor = showCorrect
                ? const Color(0x1522C55E)
                : showWrong
                ? const Color(0x15C0392B)
                : selected
                ? const Color(0x1A2EABFE)
                : Colors.white;
            final borderColor = showCorrect
                ? const Color(0x6622C55E)
                : showWrong
                ? const Color(0x66C0392B)
                : selected
                ? const Color(0x662EABFE)
                : const Color(0x1A020817);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: _isSessionSubmitted
                    ? null
                    : () => setState(() => _answers[_questionIndex] = i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        String.fromCharCode(65 + i),
                        style: const TextStyle(
                          color: kPrepDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          question.options[i],
                          style: const TextStyle(
                            color: kPrepDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_isSessionSubmitted) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kPrepBorder),
              ),
              child: Text(
                'Explanation: ${question.explanation}',
                style: const TextStyle(
                  fontSize: 11,
                  color: kPrepMuted,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: _questionIndex == 0
                    ? null
                    : () => setState(() => _questionIndex -= 1),
                child: const Text('Prev'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _questionIndex == _activeQuestions.length - 1
                    ? null
                    : () => setState(() => _questionIndex += 1),
                child: const Text('Next'),
              ),
              const Spacer(),
              TextButton(
                onPressed: _stopSession,
                child: const Text('End Session'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSessionSubmitted ? _stopSession : _submitSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSessionSubmitted ? kPrepTeal : kPrepBlue,
                  foregroundColor: kPrepWhite,
                ),
                child: Text(_isSessionSubmitted ? 'Close' : 'Submit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardSection() {
    final filteredCards = _filteredFlashcards;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrepWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrepBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flashcards',
            style: TextStyle(
              color: kPrepDark,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Tap a card to flip and review key terms + definitions.',
            style: TextStyle(
              color: kPrepMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _flashcardTopics.map((topic) {
                final selected = _flashTopicFilter == topic;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(topic),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _flashTopicFilter = topic),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'easy', 'medium', 'hard'].map((difficulty) {
                final selected = _flashDifficultyFilter == difficulty;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      difficulty[0].toUpperCase() + difficulty.substring(1),
                    ),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _flashDifficultyFilter = difficulty),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          if (filteredCards.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No flashcards for this filter yet.',
                style: TextStyle(
                  color: kPrepMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            )
          else
            SizedBox(
              height: 186,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filteredCards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final card = filteredCards[index];
                  final cardKey = _flashcardKey(card);
                  final flipped = _flippedCardKeys.contains(cardKey);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (flipped) {
                          _flippedCardKeys.remove(cardKey);
                        } else {
                          _flippedCardKeys.add(cardKey);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 250,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: flipped
                            ? const Color(0xFF0B2A3A)
                            : const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: flipped
                              ? const Color(0x6636B5FF)
                              : const Color(0x332EABFE),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  card.topic,
                                  style: TextStyle(
                                    color: flipped
                                        ? const Color(0xFFAED8FF)
                                        : kPrepBlue,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: flipped
                                      ? const Color(0x2641C0FF)
                                      : const Color(0x162EABFE),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  card.difficulty.toUpperCase(),
                                  style: TextStyle(
                                    color: flipped
                                        ? const Color(0xFFCFE6FF)
                                        : kPrepBlue,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: Text(
                                  flipped ? card.definition : card.term,
                                  key: ValueKey<bool>(flipped),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: flipped ? kPrepWhite : kPrepDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: flipped ? 14 : 16,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            flipped
                                ? 'Tap to show term'
                                : 'Tap to reveal definition',
                            style: TextStyle(
                              color: flipped
                                  ? const Color(0xA9D1E7FF)
                                  : kPrepMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    final topicScores = _topicAverages;
    final trend = _progressSeries;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrepWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrepBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Analytics',
            style: TextStyle(
              color: kPrepDark,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _history.isEmpty
                ? 'Complete at least one session to populate charts.'
                : 'Score by topic, weak area highlights, and trend line over time.',
            style: const TextStyle(
              color: kPrepMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          ...topicScores.entries.map((entry) {
            final value = entry.value;
            final isWeak = value > 0 && value < 0.72;
            final color = isWeak ? const Color(0xFFC0392B) : kPrepTeal;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: kPrepDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${(value * 100).round()}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE9EEF4),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          const Text(
            'Score Improvement Over Time',
            style: TextStyle(
              color: kPrepDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: trend.isEmpty
                ? const Center(
                    child: Text(
                      'No trend data yet',
                      style: TextStyle(
                        color: kPrepMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _TrendLinePainter(values: trend),
                    child: Container(),
                  ),
          ),
        ],
      ),
    );
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

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axis,
    );
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), axis);

    final grid = Paint()
      ..color = const Color(0x22212E3E)
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (values.length < 2) {
      final only = values.first;
      final point = Offset(size.width / 2, size.height - (only * size.height));
      final dot = Paint()..color = kPrepBlue;
      canvas.drawCircle(point, 4, dot);
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
      ..color = kPrepBlue
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, line);

    final dotPaint = Paint()..color = kPrepTeal;
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

class _PrepQuestion {
  final String topic;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const _PrepQuestion({
    required this.topic,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  static _PrepQuestion? fromApi(Map<String, dynamic> data) {
    final topic = (data['topic'] ?? 'General').toString().trim();
    final prompt = (data['prompt'] ?? '').toString().trim();
    final options = ((data['options'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final idx = (data['correctIndex'] as num?)?.toInt() ?? 0;

    if (prompt.isEmpty || options.length < 2) return null;

    return _PrepQuestion(
      topic: topic,
      prompt: prompt,
      options: options,
      correctIndex: idx.clamp(0, options.length - 1),
      explanation:
          (data['explanation'] ?? 'Review this module topic for more context.')
              .toString(),
    );
  }
}

class _FlashcardItem {
  final String topic;
  final String term;
  final String definition;
  final String difficulty;

  const _FlashcardItem({
    required this.topic,
    required this.term,
    required this.definition,
    required this.difficulty,
  });

  static _FlashcardItem? fromApi(Map<String, dynamic> data) {
    final topic = (data['topic'] ?? 'General').toString().trim();
    final term = (data['term'] ?? '').toString().trim();
    final definition = (data['definition'] ?? '').toString().trim();
    final difficulty = (data['difficulty'] ?? 'medium')
        .toString()
        .trim()
        .toLowerCase();

    if (term.isEmpty || definition.isEmpty) return null;
    return _FlashcardItem(
      topic: topic,
      term: term,
      definition: definition,
      difficulty: ['easy', 'medium', 'hard'].contains(difficulty)
          ? difficulty
          : 'medium',
    );
  }
}

class _TopicStat {
  final int correct;
  final int total;

  const _TopicStat({required this.correct, required this.total});
}

class _SessionResult {
  final String mode;
  final int total;
  final int correct;
  final DateTime completedAt;
  final Map<String, _TopicStat> topicStats;

  const _SessionResult({
    required this.mode,
    required this.total,
    required this.correct,
    required this.completedAt,
    required this.topicStats,
  });

  double get scorePercent => total == 0 ? 0 : correct / total;
}

List<_PrepQuestion> _buildQuestionBank() {
  return const <_PrepQuestion>[
    _PrepQuestion(
      topic: 'Federal Law',
      prompt: 'What does SAFE Act pre-licensing primarily standardize?',
      options: [
        'State tax rates',
        'Minimum standards for MLO licensing',
        'Loan servicing fees',
        'Broker commission rules only',
      ],
      correctIndex: 1,
      explanation:
          'The SAFE Act sets minimum nationwide standards for MLO licensing and registration.',
    ),
    _PrepQuestion(
      topic: 'Federal Law',
      prompt:
          'Which federal law primarily governs disclosures for residential mortgage lending?',
      options: ['FCRA', 'TILA', 'RESPA Section 8 only', 'HMDA only'],
      correctIndex: 1,
      explanation:
          'Truth in Lending Act (TILA) governs cost-of-credit disclosures.',
    ),
    _PrepQuestion(
      topic: 'Federal Law',
      prompt: 'What is a core purpose of RESPA?',
      options: [
        'Set state CE hours',
        'Regulate appraisal licensing only',
        'Require disclosures around settlement costs',
        'Set interest rates nationally',
      ],
      correctIndex: 2,
      explanation:
          'RESPA focuses on transparency in settlement processes and costs.',
    ),
    _PrepQuestion(
      topic: 'Federal Law',
      prompt: 'HMDA data collection is mainly used to:',
      options: [
        'Set lender compensation plans',
        'Monitor fair lending patterns',
        'Approve loan modifications',
        'Create personal credit scores',
      ],
      correctIndex: 1,
      explanation:
          'HMDA supports public monitoring of lending patterns and potential discrimination.',
    ),
    _PrepQuestion(
      topic: 'Federal Law',
      prompt: 'Under ECOA, prohibited discrimination includes:',
      options: [
        'Loan amount requested',
        'Property type',
        'Race or national origin',
        'Debt-to-income level',
      ],
      correctIndex: 2,
      explanation:
          'ECOA forbids discrimination based on protected characteristics such as race and national origin.',
    ),
    _PrepQuestion(
      topic: 'Ethics',
      prompt: 'Steering a borrower to a costlier product without benefit is:',
      options: [
        'Acceptable if disclosed',
        'Ethical if lender prefers it',
        'Unethical and potentially abusive',
        'Required for margin',
      ],
      correctIndex: 2,
      explanation:
          'Steering harms consumers and can violate ethical and regulatory standards.',
    ),
    _PrepQuestion(
      topic: 'Ethics',
      prompt: 'Best ethical response to a discovered document error is to:',
      options: [
        'Ignore if minor',
        'Correct it immediately and document actions',
        'Wait for underwriting to catch it',
        'Hide it to avoid delay',
      ],
      correctIndex: 1,
      explanation:
          'Prompt correction and documentation are essential to integrity and compliance.',
    ),
    _PrepQuestion(
      topic: 'Ethics',
      prompt: 'A conflict of interest should be handled by:',
      options: [
        'Concealing relationship',
        'Disclosure and mitigation',
        'Verbal note only',
        'No action needed',
      ],
      correctIndex: 1,
      explanation:
          'Conflicts must be disclosed and managed to protect the borrower.',
    ),
    _PrepQuestion(
      topic: 'Ethics',
      prompt: 'Consumer trust is strongest when an MLO:',
      options: [
        'Guarantees approval',
        'Uses pressure tactics',
        'Communicates clearly and honestly',
        'Avoids discussing fees',
      ],
      correctIndex: 2,
      explanation:
          'Transparent and accurate communication builds trust and reduces risk.',
    ),
    _PrepQuestion(
      topic: 'Ethics',
      prompt: 'Misrepresenting income to speed loan approval is:',
      options: [
        'Allowed with manager approval',
        'A harmless shortcut',
        'Fraudulent conduct',
        'Only a policy issue',
      ],
      correctIndex: 2,
      explanation:
          'Misrepresentation can constitute mortgage fraud and major compliance violations.',
    ),
    _PrepQuestion(
      topic: 'Nontraditional Products',
      prompt: 'An ARM differs from fixed-rate primarily because:',
      options: [
        'It has no closing costs',
        'Rate can adjust after initial period',
        'It always has lower lifetime cost',
        'It eliminates escrow',
      ],
      correctIndex: 1,
      explanation:
          'Adjustable-rate mortgages can change rates based on index and margin terms.',
    ),
    _PrepQuestion(
      topic: 'Nontraditional Products',
      prompt: 'Negative amortization means:',
      options: [
        'Principal decreases quickly',
        'Payment is always fixed',
        'Loan balance can grow over time',
        'Interest is waived',
      ],
      correctIndex: 2,
      explanation:
          'When payments do not cover interest, unpaid interest increases principal balance.',
    ),
    _PrepQuestion(
      topic: 'Nontraditional Products',
      prompt: 'A balloon mortgage typically requires:',
      options: [
        'No down payment',
        'Large final payment at maturity',
        'Interest-only forever',
        'No underwriting',
      ],
      correctIndex: 1,
      explanation:
          'Balloon structures include a substantial lump-sum payment at the end.',
    ),
    _PrepQuestion(
      topic: 'Nontraditional Products',
      prompt:
          'When discussing interest-only features, an MLO should emphasize:',
      options: [
        'Only initial savings',
        'Future payment shock risk',
        'No need for qualification',
        'Guaranteed refinance',
      ],
      correctIndex: 1,
      explanation:
          'Borrowers should understand increased future payment obligations.',
    ),
    _PrepQuestion(
      topic: 'Nontraditional Products',
      prompt: 'A key suitability check for nontraditional loans is:',
      options: [
        'Borrower logo preference',
        'Ability to repay under realistic scenarios',
        'Number of prior loan officers',
        'Branch production volume',
      ],
      correctIndex: 1,
      explanation:
          'Suitability includes ability-to-repay and borrower risk tolerance.',
    ),
    _PrepQuestion(
      topic: 'Math and Finance',
      prompt:
          'If monthly principal+interest is 1200 and taxes/insurance are 300, PITI is:',
      options: ['900', '1200', '1500', '1800'],
      correctIndex: 2,
      explanation: 'PITI combines principal, interest, taxes, and insurance.',
    ),
    _PrepQuestion(
      topic: 'Math and Finance',
      prompt: 'Loan-to-value (LTV) is calculated as:',
      options: [
        'Appraised value divided by loan amount',
        'Loan amount divided by appraised value',
        'Income divided by debt',
        'Down payment divided by purchase price only',
      ],
      correctIndex: 1,
      explanation: 'LTV is loan amount / property value.',
    ),
    _PrepQuestion(
      topic: 'Math and Finance',
      prompt: 'Debt-to-income ratio compares:',
      options: [
        'Assets to liabilities',
        'Monthly debt payments to gross monthly income',
        'Credit score to loan amount',
        'Loan term to APR',
      ],
      correctIndex: 1,
      explanation: 'DTI measures debt burden using gross monthly income.',
    ),
    _PrepQuestion(
      topic: 'Math and Finance',
      prompt:
          'A borrower earns 6000/month gross, with 2400 debt obligations. DTI is:',
      options: ['20%', '30%', '40%', '50%'],
      correctIndex: 2,
      explanation: 'DTI = 2400 / 6000 = 0.40 = 40%.',
    ),
    _PrepQuestion(
      topic: 'Math and Finance',
      prompt: 'APR is best described as:',
      options: [
        'Interest rate only',
        'Total annualized borrowing cost including certain fees',
        'Closing cost refund',
        'Loan balance after one year',
      ],
      correctIndex: 1,
      explanation:
          'APR reflects annualized cost of credit beyond nominal interest rate.',
    ),
    _PrepQuestion(
      topic: 'State Compliance',
      prompt:
          'Why should MLOs review state-specific add-ons to federal requirements?',
      options: [
        'They are optional suggestions',
        'States may impose extra education or disclosure rules',
        'Only needed after closing',
        'Only relevant for commercial loans',
      ],
      correctIndex: 1,
      explanation:
          'States can require additional licensing and compliance obligations.',
    ),
    _PrepQuestion(
      topic: 'State Compliance',
      prompt: 'NMLS renewal windows are generally important because:',
      options: [
        'They replace SAFE Act',
        'Missing deadlines can affect active status',
        'They remove CE requirements',
        'They lower all fees automatically',
      ],
      correctIndex: 1,
      explanation:
          'Timely renewal and CE completion are required to maintain active licenses.',
    ),
    _PrepQuestion(
      topic: 'State Compliance',
      prompt: 'A practical step before originating in a new state is to:',
      options: [
        'Assume reciprocity',
        'Confirm sponsorship and state licensing rules',
        'Skip CE this year',
        'Use another MLO number',
      ],
      correctIndex: 1,
      explanation:
          'Always verify state-specific licensing, sponsorship, and compliance obligations.',
    ),
    _PrepQuestion(
      topic: 'State Compliance',
      prompt:
          'If state law conflicts with a less strict internal policy, the MLO should follow:',
      options: [
        'Internal policy only',
        'State law and stricter requirement',
        'Client preference',
        'No requirement',
      ],
      correctIndex: 1,
      explanation:
          'Regulatory law and stricter controls govern, not weaker internal convenience.',
    ),
    _PrepQuestion(
      topic: 'State Compliance',
      prompt: 'Document retention rules are important mainly for:',
      options: [
        'Office decoration',
        'Audit trail and regulatory examinations',
        'Marketing emails',
        'Rate lock speed',
      ],
      correctIndex: 1,
      explanation: 'Retention supports compliance evidence and exam readiness.',
    ),
  ];
}

List<_FlashcardItem> _buildFlashcards() {
  return const <_FlashcardItem>[
    _FlashcardItem(
      topic: 'Federal Law',
      term: 'SAFE Act',
      definition:
          'Federal law establishing minimum standards for mortgage loan originator licensing and registration.',
      difficulty: 'easy',
    ),
    _FlashcardItem(
      topic: 'Federal Law',
      term: 'TILA',
      definition:
          'Truth in Lending Act; requires clear disclosure of key credit terms and borrowing costs.',
      difficulty: 'easy',
    ),
    _FlashcardItem(
      topic: 'Ethics',
      term: 'Steering',
      definition:
          'Directing a borrower to a less favorable loan for the MLO benefit rather than borrower need.',
      difficulty: 'medium',
    ),
    _FlashcardItem(
      topic: 'Nontraditional Products',
      term: 'Negative Amortization',
      definition:
          'Loan balance grows because scheduled payment does not cover accrued interest.',
      difficulty: 'medium',
    ),
    _FlashcardItem(
      topic: 'Math and Finance',
      term: 'DTI Ratio',
      definition:
          'Debt-to-income; monthly debt obligations divided by gross monthly income.',
      difficulty: 'easy',
    ),
    _FlashcardItem(
      topic: 'Math and Finance',
      term: 'LTV Ratio',
      definition: 'Loan-to-value; mortgage amount divided by property value.',
      difficulty: 'easy',
    ),
    _FlashcardItem(
      topic: 'State Compliance',
      term: 'NMLS Renewal',
      definition:
          'Annual process to maintain active license status through CE completion and filing deadlines.',
      difficulty: 'medium',
    ),
  ];
}
