import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'course_portal_api.dart';
import 'models/course_model.dart';
import 'repositories/course_repository.dart';
import 'token_provider.dart';
import 'api_client.dart';

import '../config/api_config.dart';
import '../widgets/app_bottom_nav.dart';
import '../course_certificate_screen.dart';

const kDark = Color(0xFF091925);
const kBlue = Color(0xFF2EABFE);
const kBlueFaint = Color(0x1A2EABFE);
const kMuted = Color(0x990B1220);
const kBorder = Color(0x1A020817);
const kTeal = Color(0xFF00B4B4);
const kWhite = Colors.white;

enum _PortalStepType { lesson, pdfGate, quiz, finalExam, reviewSummary }

enum _RocsGateMode { skip, checkAndRequireIfNotAgreed }

class _PortalStep {
  final String id;
  final _PortalStepType type;
  final int? moduleOrder;
  final String? quizType; // checkpoint | quiz_fundamentals | final_exam
  final String title;

  const _PortalStep({
    required this.id,
    required this.type,
    this.moduleOrder,
    this.quizType,
    required this.title,
  });
}

class CoursePortalScreen extends StatefulWidget {
  final String courseId;
  const CoursePortalScreen({super.key, required this.courseId});

  @override
  State<CoursePortalScreen> createState() => _CoursePortalScreenState();
}

class _CoursePortalScreenState extends State<CoursePortalScreen> {
  bool _loading = true;
  String? _error;

  CourseModel? _course;
  bool _reviewMode = false;

  List<_PortalStep> _steps = const [];
  int _currentIdx = 0;
  Set<int> _completedIdxs = <int>{};

  // Lesson seat-time gate (simplified: just counts seconds while this screen is focused)
  Timer? _seatTimer;
  int _seatSeconds = 0;
  bool _pdfGateReviewed = false;

  // Quiz state
  final Map<String, int> _quizAnswers = <String, int>{}; // questionId -> selectedIndex
  DateTime? _quizStartedAt;
  int _quizCorrect = 0;
  int _quizTotal = 0;

  // Final exam flow: after pass, require explicit "Complete Course" click.
  bool _finalExamPassedPendingComplete = false;

  // ROCS / agreement gate
  bool _rocsAgreed = false;

  // Quiz locking info by quizId (step.id) from GET /api/quiz-attempts/:courseId
  final Map<String, Map<String, dynamic>> _quizAttemptsByQuizId =
      <String, Map<String, dynamic>>{};

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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1) fetch course
      final coursesRepo = CourseRepository(
        ApiClient(
          baseUrl: ApiConfig.baseUrl,
          tokenProvider: SharedPreferencesTokenProvider(),
        ),
      );
      final course = await coursesRepo.fetchCourseById(widget.courseId);
      _course = course;

      // 2) Build steps in the exact same ordering used by backend progress.
      _buildSteps(course);

      // 3) progress (needed to decide Start vs Resume gating)
      final progress = await CoursePortalApi.getProgress(widget.courseId);
      final completedIdxsRaw = progress['completed_idxs'] ??
          progress['completedIdxs'] ??
          progress['completedIndexes'] ??
          <dynamic>[];
      final completedIdxs = (completedIdxsRaw is List)
          ? completedIdxsRaw.map((e) => (e as num).toInt()).toList()
          : <int>[];

      final isCompleted = progress['is_completed'] == true;

      _completedIdxs = <int>{};
      for (final idx in completedIdxs) {
        if (idx >= 0 && idx < _steps.length) _completedIdxs.add(idx);
      }

      _reviewMode = isCompleted;

      final serverCurrentIdx =
          (progress['current_idx'] ?? progress['currentIdx'] ?? 0);
      _currentIdx = (serverCurrentIdx is num ? serverCurrentIdx.toInt() : 0)
          .clamp(0, (_steps.length - 1).clamp(0, _steps.length));

      if (_reviewMode) {
        _completedIdxs = _steps.asMap().entries.map((e) => e.key).toSet();
        _currentIdx = _steps.isEmpty ? 0 : (_steps.length - 1);
      }

      final isStart = !_reviewMode &&
          _completedIdxs.isEmpty &&
          _currentIdx == 0;

      // 4) Compliance gates
      // Start: BioSig → ROCS
      // Resume: BioSig only (verify again)
      if (!_reviewMode) {
        if (isStart) {
          await _runComplianceGates(
            courseName: course.title,
            rocsMode: _RocsGateMode.checkAndRequireIfNotAgreed,
          );
        } else {
          await _runComplianceGates(
            courseName: course.title,
            rocsMode: _RocsGateMode.skip,
          );
        }
      }

      // 6) quiz attempts for locking UX
      final quizAttemptsRes = await CoursePortalApi.getQuizAttempts(widget.courseId);
      final attempts = quizAttemptsRes['attempts'];
      if (attempts is Map) {
        _quizAttemptsByQuizId.clear();
        attempts.forEach((k, v) {
          if (k == null) return;
          final key = k.toString();
          if (v is Map<String, dynamic>) {
            _quizAttemptsByQuizId[key] = v;
          } else if (v is Map) {
            _quizAttemptsByQuizId[key] = Map<String, dynamic>.from(v as Map);
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _runComplianceGates({
    required String courseName,
    required _RocsGateMode rocsMode,
  }) async {
    // BioSig is always shown on entry (Start or Resume) per requirement.
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BioSigDialog(
        courseId: widget.courseId,
        courseName: courseName,
      ),
    );
    if (verified != true) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    if (rocsMode == _RocsGateMode.skip) return;

    // ROCS only required on Start (and only if not already agreed).
    final rocs = await CoursePortalApi.rocsCheck(widget.courseId);
    _rocsAgreed = rocs['agreed'] == true;
    if (_rocsAgreed) return;

    await _showRocsAgreementModal(courseName: courseName);
  }

  Future<void> _showRocsAgreementModal({required String courseName}) async {
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RocsV4Dialog(
        courseId: widget.courseId,
        courseName: courseName,
      ),
    );

    if (agreed == true) {
      if (!mounted) return;
      setState(() => _rocsAgreed = true);
      return;
    }

    // Cancel → exit portal.
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _showBioSigModalIfNeeded({required String courseName}) async {
    bool alreadyVerified = false;
    try {
      final status = await CoursePortalApi.biosigStatus(widget.courseId);
      alreadyVerified = status['verified'] == true;
    } catch (_) {
      alreadyVerified = false;
    }

    if (alreadyVerified) return;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BioSigDialog(
        courseId: widget.courseId,
        courseName: courseName,
      ),
    );

    if (verified == true) return;

    // Cancel → exit portal.
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _buildSteps(CourseModel course) {
    final steps = <_PortalStep>[];
    final modules = course.modules;
    for (final module in modules) {
      final order = module.order;

      // Step A: lesson
      steps.add(_PortalStep(
        id: 'lesson-mod-$order',
        type: _PortalStepType.lesson,
        moduleOrder: order,
        title: module.title,
      ));

      // Step B: pdf gate (if show_pdf_before_quiz && pdf_url exists)
      // Backend step ordering is expected to include the PDF gate whenever
      // `show_pdf_before_quiz` is enabled (even if pdf_url is missing).
      if (module.showPdfBeforeQuiz) {
        steps.add(_PortalStep(
          id: 'pdf-gate-mod-$order',
          type: _PortalStepType.pdfGate,
          moduleOrder: order,
          title: 'Review PDF',
        ));
      }

      // Step C: quiz step (checkpoint vs fundamentals)
      final fundamentals = module.showPdfBeforeQuiz && module.quiz.length > 10;
      final quizType = fundamentals ? 'quiz_fundamentals' : 'checkpoint';
      steps.add(_PortalStep(
        id: 'checkpoint-mod-$order',
        type: _PortalStepType.quiz,
        moduleOrder: order,
        quizType: quizType,
        title: fundamentals ? 'Fundamentals Quiz' : 'Checkpoint Quiz',
      ));
    }

    // Step D: final exam
    if (course.finalExamQuestions.isNotEmpty) {
      steps.add(_PortalStep(
        id: 'final-exam',
        type: _PortalStepType.finalExam,
        title: course.finalExamTitle,
        quizType: 'final_exam',
      ));
    }

    // After completion/review mode: review_summary
    steps.add(_PortalStep(
      id: 'review-summary',
      type: _PortalStepType.reviewSummary,
      title: 'Course Summary',
    ));

    _steps = steps;
  }

  void _resetSeatTimer() {
    _seatTimer?.cancel();
    _seatSeconds = 0;
  }

  int _requiredSeatSeconds(_PortalStep step) {
    // Mirror web behavior (currently hardcoded for testing).
    return 10;
  }

  void _startSeatTimer() {
    _seatTimer?.cancel();
    _seatTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seatSeconds += 1);
    });
  }

  CourseModuleModel? _moduleForStep(_PortalStep step) {
    if (step.moduleOrder == null) return null;
    final modules = _course?.modules.where((m) => m.order == step.moduleOrder).toList() ?? const [];
    return modules.isNotEmpty ? modules.first : null;
  }

  Map<String, int> _initialSelectionsForQuizStep(
    _PortalStep step,
    List<QuizQuestionModel> questions,
  ) {
    if (!_reviewMode) return const <String, int>{};

    final meta = _quizAttemptsByQuizId[step.id];
    final attemptsRaw = meta?['attempts'];
    if (attemptsRaw is! List || attemptsRaw.isEmpty) {
      return const <String, int>{};
    }

    Map<String, dynamic>? best;
    double bestScore = -1;
    for (final a in attemptsRaw) {
      if (a is! Map) continue;
      final map = a is Map<String, dynamic> ? a : Map<String, dynamic>.from(a as Map);

      final rawScore = map['scorePct'] ?? map['score_pct'] ?? map['score'] ?? 0;
      final score = rawScore is num
          ? rawScore.toDouble()
          : double.tryParse(rawScore.toString()) ?? 0.0;

      if (score > bestScore) {
        bestScore = score;
        best = map;
      }
    }

    final answersRaw = best?['answers'];
    if (answersRaw is! Map) return const <String, int>{};

    final answerMap = <String, dynamic>{};
    answersRaw.forEach((k, v) {
      if (k == null) return;
      answerMap[k.toString()] = v;
    });

    int? parseAnswer(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return null;
    }

    final res = <String, int>{};
    for (int i = 0; i < questions.length; i++) {
      final key = step.moduleOrder != null
          ? 'mod${step.moduleOrder}-q$i'
          : 'fq$i';
      final parsed = parseAnswer(answerMap[key]);
      if (parsed != null) res[questions[i].questionId] = parsed;
    }
    return res;
  }

  Future<void> _completeCourseFlow({required int finalExamStepIdx}) async {
    final course = _course;
    if (course == null) return;

    // Mark step completed in progress, then run completion endpoints.
    _completedIdxs.add(finalExamStepIdx);
    await _saveProgressAndAdvance(
      completedIdx: finalExamStepIdx,
      saveSeatProgress: false,
    );

    // Per your flow: call completion endpoints after pass + explicit click.
    await CoursePortalApi.completeCourse(courseId: course.id);
    await CoursePortalApi.completeEnrollment(courseId: course.id);

    // Persist a local completion fallback so completed courses stay completed
    // even if the dashboard endpoint lags or is mis-shaped.
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('completed_course_ids') ?? <String>[];
      final updated = <String>{
        ...list,
        course.id,
        widget.courseId,
        if (course.nmlsCourseId.trim().isNotEmpty) course.nmlsCourseId.trim(),
      }.toList();
      await prefs.setStringList('completed_course_ids', updated);

      final title = course.title.trim();
      if (title.isNotEmpty) {
        final titles = prefs.getStringList('completed_course_titles') ?? <String>[];
        await prefs.setStringList(
          'completed_course_titles',
          <String>{...titles, title}.toList(),
        );
      }

      // store a simple completion timestamp for UI fallback
      await prefs.setString('completed_course_at_${course.id}', DateTime.now().toUtc().toIso8601String());
      if (course.nmlsCourseId.trim().isNotEmpty) {
        await prefs.setString(
          'completed_course_at_${course.nmlsCourseId.trim()}',
          DateTime.now().toUtc().toIso8601String(),
        );
      }
      if (title.isNotEmpty) {
        await prefs.setString(
          'completed_course_at_title_${title.toLowerCase()}',
          DateTime.now().toUtc().toIso8601String(),
        );
      }
    } catch (_) {
      // ignore local storage failures
    }

    setState(() {
      _finalExamPassedPendingComplete = false;
      _reviewMode = true;
      _completedIdxs = _steps.asMap().entries.map((e) => e.key).toSet();
      _currentIdx = _steps.isEmpty ? 0 : (_steps.length - 1);
    });
  }

  Future<void> _saveProgressAndAdvance({
    required int completedIdx,
    required bool saveSeatProgress,
  }) async {
    if (_course == null) return;

    final updatedCompleted = <int>{..._completedIdxs};
    updatedCompleted.add(completedIdx);
    final completedIdxsSorted = updatedCompleted.toList()..sort();

    await CoursePortalApi.saveProgress(
      courseId: _course!.id,
      completedIdxs: completedIdxsSorted,
      currentIdx: completedIdx + 1,
      totalSteps: _steps.length,
    );

    if (saveSeatProgress) {
      final completedStep = _steps[completedIdx];
      final moduleOrder = completedStep.moduleOrder ?? 0;
      await CoursePortalApi.saveSeatProgress(
        courseId: _course!.id,
        seatSecondsDelta: _seatSeconds,
        moduleOrder: moduleOrder,
      );
    }
  }

  bool _isQuizStepLocked(_PortalStep quizStep) {
    final meta = _quizAttemptsByQuizId[quizStep.id];
    if (meta == null) return false;
    final locked = meta['locked'] == true;
    final unlockedByInstructor = meta['unlocked_by_instructor'] == true;
    return locked && !unlockedByInstructor;
  }

  Future<void> _refreshQuizAttemptsMeta() async {
    final quizAttemptsRes = await CoursePortalApi.getQuizAttempts(widget.courseId);
    final attempts = quizAttemptsRes['attempts'];
    if (attempts is Map) {
      _quizAttemptsByQuizId.clear();
      attempts.forEach((k, v) {
        if (k == null) return;
        final key = k.toString();
        if (v is Map<String, dynamic>) {
          _quizAttemptsByQuizId[key] = v;
        } else if (v is Map) {
          _quizAttemptsByQuizId[key] = Map<String, dynamic>.from(v as Map);
        }
      });
    }
  }

  Future<void> _submitQuiz({
    required _PortalStep quizStep,
    required int quizStepIdx,
    required int correct,
    required int total,
    required double scorePct,
    required bool passed,
    required int timeSpentSeconds,
  }) async {
    final course = _course;
    if (course == null) return;

    if (_isQuizStepLocked(quizStep)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This quiz is locked. Instructor must unlock to retake.'),
        ),
      );
      return;
    }

    final module = _moduleForStep(quizStep);
    final quizType = quizStep.quizType ?? 'checkpoint';
    final isFinal = quizStep.type == _PortalStepType.finalExam;

    // Web behavior: checkpoints use 100% passing score (all correct).
    final passingScore = quizType == 'checkpoint' ? 100 : course.passingScore.toInt();

    final questionList = isFinal
        ? course.finalExamQuestions
        : (module?.quiz ?? <QuizQuestionModel>[]);

    // Backend quiz-attempts sample stores answer keys as:
    // - module quizzes: `mod{moduleOrder}-q{index}` (e.g. `mod1-q0`)
    // - final exam: fallback to `q{index}` when no questionId is provided
    final answers = <String, dynamic>{};
    for (int i = 0; i < questionList.length; i++) {
      final q = questionList[i];
      final selected = _quizAnswers[q.questionId];
      if (selected == null) continue;

      if (quizStep.moduleOrder != null) {
        answers['mod${quizStep.moduleOrder}-q$i'] = selected;
      } else {
        // Final exam: use `fq{index}` answer keys (e.g. `fq0`, `fq1`...).
        answers['fq$i'] = selected;
      }
    }

    final payloadQuizId = quizStep.id;
    final quizTitle = isFinal ? course.finalExamTitle : module?.title ?? 'Quiz';

    await CoursePortalApi.submitQuizAttempt(
      courseId: course.id,
      quizId: payloadQuizId,
      quizTitle: quizTitle,
      quizType: quizType,
      moduleOrder: quizStep.moduleOrder ?? 0,
      scorePct: scorePct,
      correct: correct,
      total: total,
      passed: passed,
      passingScore: passingScore,
      timeSpentSeconds: timeSpentSeconds,
      answers: answers,
    );

    await _refreshQuizAttemptsMeta();

    if (!passed) {
      // Let the user try again (if not locked after this attempt).
      setState(() {
        _quizAnswers.clear();
        _quizStartedAt = null;
        if (quizStep.type == _PortalStepType.finalExam) {
          _finalExamPassedPendingComplete = false;
        }
      });
      return;
    }

    // Passed:
    // - Module quizzes: persist progress and move forward immediately.
    // - Final exam: do NOT complete/advance yet; require explicit "Complete Course".
    if (quizStep.type == _PortalStepType.finalExam) {
      setState(() {
        _finalExamPassedPendingComplete = true;
      });
      return;
    }

    _completedIdxs.add(quizStepIdx);
    await _saveProgressAndAdvance(
      completedIdx: quizStepIdx,
      saveSeatProgress: false,
    );
    setState(() {
      _currentIdx = (quizStepIdx + 1).clamp(0, _steps.length - 1);
      _quizAnswers.clear();
      _quizStartedAt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course'),),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    final course = _course!;
    final step = _steps.isEmpty ? null : _steps[_currentIdx];

    // Seat-time timer should only run while on a lesson step.
    if (step?.type != _PortalStepType.lesson) {
      if (_seatTimer != null) {
        _seatTimer?.cancel();
        _seatTimer = null;
      }
    }
    final stepTitle = step?.title ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A25),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              course.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stepTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Compliance gates',
            icon: const Icon(Icons.verified_user_outlined),
            onPressed: () async {
              final courseName = _course?.title ?? 'Course';
              // Manual: always show BioSig, then show ROCS dialog.
              final verified = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => _BioSigDialog(
                  courseId: widget.courseId,
                  courseName: courseName,
                ),
              );
              if (verified != true) return;

              await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => _RocsV4Dialog(
                  courseId: widget.courseId,
                  courseName: courseName,
                ),
              );
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_currentIdx > 0) {
              setState(() => _currentIdx -= 1);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: step == null
          ? const SizedBox.shrink()
          : (step.type == _PortalStepType.lesson
              ? Column(
                  children: [
                    Expanded(child: _buildStepContent(course, step)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: _buildNavButtons(step),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step ${_currentIdx + 1} of ${_steps.length}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildStepContent(course, step),
                      ),
                      _buildNavButtons(step),
                    ],
                  ),
                )),
      bottomNavigationBar: AppBottomNav(
        activeTab: AppNavTab.courses,
        userName: '',
        userEmail: '',
      ),
    );
  }

  Widget _buildNavButtons(_PortalStep step) {
    final canPrev = _currentIdx > 0;
    final currentIdxCompleted = _completedIdxs.contains(_currentIdx);
    final canNext = () {
      // In review mode, allow exiting from the summary step.
      if (_reviewMode) {
        return step.type == _PortalStepType.reviewSummary;
      }
      switch (step.type) {
        case _PortalStepType.lesson:
          if (currentIdxCompleted) return true;
          final required = _requiredSeatSeconds(step);
          return _seatSeconds >= required;
        case _PortalStepType.pdfGate:
          return currentIdxCompleted || _pdfGateReviewed;
        case _PortalStepType.quiz:
        case _PortalStepType.finalExam:
          // Outer button is only allowed if quiz is already completed.
          return currentIdxCompleted;
        case _PortalStepType.reviewSummary:
          return false;
      }
    }();

    String nextLabel() {
      if (_reviewMode) return 'Done';
      switch (step.type) {
        case _PortalStepType.lesson:
          return 'Continue';
        case _PortalStepType.pdfGate:
          return 'Proceed';
        case _PortalStepType.quiz:
          return currentIdxCompleted ? 'Next' : 'Submit above';
        case _PortalStepType.finalExam:
          return currentIdxCompleted ? 'Next' : 'Submit above';
        case _PortalStepType.reviewSummary:
          return 'Done';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: canPrev
                  ? () {
                      _resetSeatTimer();
                      _pdfGateReviewed = false;
                      _quizAnswers.clear();
                      _quizStartedAt = null;
                      setState(() => _currentIdx -= 1);
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(
                  color: canPrev ? kBlue.withValues(alpha: 0.35) : kBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.chevron_left_rounded, size: 20),
                  SizedBox(width: 2),
                  Text(
                    'Previous',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: canNext
                  ? () async {
                      // Review summary "Done" should exit the portal back to the previous screen.
                      if (_reviewMode && step.type == _PortalStepType.reviewSummary) {
                        if (!mounted) return;
                        final course = _course;
                        Navigator.of(context).pop(<String, dynamic>{
                          'completed': true,
                          'courseId': course?.id ?? widget.courseId,
                          'nmlsCourseId': course?.nmlsCourseId ?? '',
                          'courseTitle': course?.title ?? '',
                        });
                        return;
                      }
                      if (_course == null) return;
                      final idx = _currentIdx;

                      // If backend already marked this step as completed, just advance.
                      if (currentIdxCompleted) {
                        _resetSeatTimer();
                        _pdfGateReviewed = false;
                        _quizAnswers.clear();
                        _quizStartedAt = null;
                        setState(() => _currentIdx = (idx + 1).clamp(0, _steps.length - 1));
                        return;
                      }

                      if (step.type == _PortalStepType.lesson) {
                        await _saveProgressAndAdvance(
                          completedIdx: idx,
                          saveSeatProgress: true,
                        );
                      } else if (step.type == _PortalStepType.pdfGate) {
                        await _saveProgressAndAdvance(
                          completedIdx: idx,
                          saveSeatProgress: false,
                        );
                      }

                      _resetSeatTimer();
                      _pdfGateReviewed = false;
                      _quizAnswers.clear();
                      _quizStartedAt = null;
                      _completedIdxs.add(idx);
                      setState(() => _currentIdx = (idx + 1).clamp(0, _steps.length - 1));
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nextLabel(),
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(CourseModel course, _PortalStep step) {
    switch (step.type) {
      case _PortalStepType.lesson:
        final module = _moduleForStep(step);
        final required = _requiredSeatSeconds(step);
        return _LessonStep(
          moduleTitle: module?.title ?? step.title,
          sections: module?.sections ?? const [],
          pdfUrl: module?.pdfUrl ?? '',
          showSeatGate: !_reviewMode,
          seatSeconds: _seatSeconds,
          requiredSeatSeconds: required,
          onStartTimer: () {
            if (_seatSeconds == 0) _startSeatTimer();
          },
        );
      case _PortalStepType.pdfGate:
        final module = _moduleForStep(step);
        return _PdfGateStep(
          title: module?.title ?? step.title,
          pdfUrl: module?.pdfUrl ?? '',
          onReviewedChanged: (v) {
            setState(() => _pdfGateReviewed = v);
          },
        );
      case _PortalStepType.quiz:
        final module = _moduleForStep(step);
        final questions = module?.quiz ?? const <QuizQuestionModel>[];
        final attemptMeta = _quizAttemptsByQuizId[step.id];
        final attemptsList = attemptMeta?['attempts'];
        int? initialElapsed;
        if (attemptsList is List && attemptsList.isNotEmpty) {
          final last = attemptsList.last;
          if (last is Map) {
            final t = last['time_spent_seconds'] ?? last['timeSpentSeconds'];
            if (t is num) initialElapsed = t.toInt();
            if (t is String) initialElapsed = int.tryParse(t.trim());
          }
        }
        return _QuizStep(
          quizType: step.quizType ?? 'checkpoint',
          questions: questions,
          passingScore: course.passingScore.toInt(),
          locked: _isQuizStepLocked(step),
          alreadyCompleted: _completedIdxs.contains(_currentIdx),
          contextTitle: module?.title,
          initialElapsedSeconds: initialElapsed,
          initialSelections: _initialSelectionsForQuizStep(step, questions),
          revealResults: _reviewMode,
          onSubmit: (answers, correct, total, scorePct, passed, timeSpentSeconds) async {
            // Prepare local answer map.
            for (final q in questions) {
              final selected = answers[q.questionId];
              if (selected != null) _quizAnswers[q.questionId] = selected;
            }
            final idx = _currentIdx;
            await _submitQuiz(
              quizStep: step,
              quizStepIdx: idx,
              correct: correct,
              total: total,
              scorePct: scorePct,
              passed: passed,
              timeSpentSeconds: timeSpentSeconds,
            );
          },
        );
      case _PortalStepType.finalExam:
        final questions = course.finalExamQuestions;
        final attemptMeta = _quizAttemptsByQuizId[step.id];
        final attemptsList = attemptMeta?['attempts'];
        int? initialElapsed;
        if (attemptsList is List && attemptsList.isNotEmpty) {
          final last = attemptsList.last;
          if (last is Map) {
            final t = last['time_spent_seconds'] ?? last['timeSpentSeconds'];
            if (t is num) initialElapsed = t.toInt();
            if (t is String) initialElapsed = int.tryParse(t.trim());
          }
        }
        return _QuizStep(
          quizType: 'final_exam',
          questions: questions,
          passingScore: course.passingScore.toInt(),
          locked: _isQuizStepLocked(step),
          alreadyCompleted: _completedIdxs.contains(_currentIdx),
          contextTitle: step.title,
          initialElapsedSeconds: initialElapsed,
          initialSelections: _initialSelectionsForQuizStep(step, questions),
          revealResults: _reviewMode,
          finalPassedPendingComplete: _finalExamPassedPendingComplete,
          onCompleteCourse: () async {
            final idx = _currentIdx;
            await _completeCourseFlow(finalExamStepIdx: idx);
          },
          onSubmit: (answers, correct, total, scorePct, passed, timeSpentSeconds) async {
            for (final q in questions) {
              final selected = answers[q.questionId];
              if (selected != null) _quizAnswers[q.questionId] = selected;
            }
            final idx = _currentIdx;
            await _submitQuiz(
              quizStep: step,
              quizStepIdx: idx,
              correct: correct,
              total: total,
              scorePct: scorePct,
              passed: passed,
              timeSpentSeconds: timeSpentSeconds,
            );
          },
        );
      case _PortalStepType.reviewSummary:
        return _ReviewSummaryStep(
          courseId: course.id,
          course: course,
        );
    }
  }
}

class _LessonStep extends StatefulWidget {
  final String moduleTitle;
  final List<String> sections;
  final String pdfUrl;
  final bool showSeatGate;
  final int seatSeconds;
  final int requiredSeatSeconds;
  final VoidCallback onStartTimer;

  const _LessonStep({
    required this.moduleTitle,
    required this.sections,
    required this.pdfUrl,
    required this.showSeatGate,
    required this.seatSeconds,
    required this.requiredSeatSeconds,
    required this.onStartTimer,
  });

  @override
  State<_LessonStep> createState() => _LessonStepState();
}

class _LessonStepState extends State<_LessonStep> {
  @override
  void initState() {
    super.initState();
    // Auto-start seat timer when the lesson step becomes visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStartTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.requiredSeatSeconds <= 0
        ? 1.0
        : (widget.seatSeconds / widget.requiredSeatSeconds).clamp(0.0, 1.0);

    final remaining = (widget.requiredSeatSeconds - widget.seatSeconds).clamp(0, 1 << 30);
    final remainingText = remaining <= 0 ? '0s' : '${remaining}s';

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // ── Player area ─────────────────────────────────────────────
          Container(
            color: const Color(0xFF071A25),
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 260,
                  width: double.infinity,
                  color: const Color(0xFF071A25),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Static placeholder "video" surface.
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF09202C),
                                Color(0xFF061620),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: kBlue.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Title below the video (not inside the player)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.moduleTitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Seat time progress bar (under player)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      valueColor: const AlwaysStoppedAnimation<Color>(kBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // ── Tabs ────────────────────────────────────────────────────
          Material(
            color: kWhite,
            child: TabBar(
              padding: EdgeInsets.zero,
              labelColor: kBlue,
              unselectedLabelColor: kMuted,
              indicatorColor: kBlue,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              tabs: const [
                Tab(text: 'Notes'),
                Tab(text: 'Transcript'),
                Tab(text: 'Resources'),
              ],
            ),
          ),

          // ── Tab content + warning + sticky nav ─────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFFF4F7FB),
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        _NotesTab(moduleTitle: widget.moduleTitle),
                        const _TranscriptTab(),
                        _ResourcesTab(pdfUrl: widget.pdfUrl, sections: widget.sections),
                      ],
                    ),
                  ),
                  if (widget.showSeatGate && remaining > 0)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0x1AF59E0B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x33F59E0B)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Complete this lesson to unlock the next module. State compliance requires minimum $remainingText watch time.',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF9A6100),
                              ),
                            ),
                          ),
                        ],
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
}

class _NotesTab extends StatefulWidget {
  final String moduleTitle;
  const _NotesTab({required this.moduleTitle});

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      children: [
        Text(
          'Personal Notes - ${widget.moduleTitle}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: kMuted,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder.withValues(alpha: 0.18)),
          ),
          child: TextField(
            controller: _ctrl,
            maxLines: 5,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Add your notes here…',
              hintStyle: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note saved (local placeholder).')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Save Note',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _TranscriptTab extends StatelessWidget {
  const _TranscriptTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Transcript (coming soon)',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: kMuted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  final String pdfUrl;
  final List<String> sections;
  const _ResourcesTab({required this.pdfUrl, required this.sections});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      children: [
        const Text(
          'Resources',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 13, color: kMuted),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PDF',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                pdfUrl.trim().isEmpty ? 'No PDF for this lesson.' : pdfUrl,
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11.5, color: kBlue),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (sections.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Topics',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final s in sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      s,
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PdfGateStep extends StatefulWidget {
  final String title;
  final String pdfUrl;
  final ValueChanged<bool> onReviewedChanged;

  const _PdfGateStep({
    required this.title,
    required this.pdfUrl,
    required this.onReviewedChanged,
  });

  @override
  State<_PdfGateStep> createState() => _PdfGateStepState();
}

class _PdfGateStepState extends State<_PdfGateStep> {
  bool _reviewed = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PDF Gate',
                style: TextStyle(color: kBlue, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (widget.pdfUrl.trim().isNotEmpty)
                Text(
                  'Open PDF: ${widget.pdfUrl}',
                  style: TextStyle(color: kMuted, fontWeight: FontWeight.w700, fontSize: 12.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                )
              else
                const Text(
                  'No PDF URL provided.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _reviewed,
                onChanged: (v) {
                  setState(() => _reviewed = v ?? false);
                  widget.onReviewedChanged(_reviewed);
                },
                title: Text('I reviewed the PDF'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Proceed will be enabled once you confirm the review.',
          style: TextStyle(color: kMuted, fontWeight: FontWeight.w700, fontSize: 12.5),
        ),
      ],
    );
  }
}

class _QuizStep extends StatefulWidget {
  final String quizType;
  final List<QuizQuestionModel> questions;
  final int passingScore;
  final bool locked;
  final bool alreadyCompleted;
  final String? contextTitle;
  final int? initialElapsedSeconds;
  final Map<String, int> initialSelections; // questionId -> selectedIndex
  final bool revealResults; // only show correct/incorrect in review mode
  final bool finalPassedPendingComplete;
  final FutureOr<void> Function()? onCompleteCourse;
  final FutureOr<void> Function(
    Map<String, int?> answers,
    int correct,
    int total,
    double scorePct,
    bool passed,
    int timeSpentSeconds,
  ) onSubmit;

  const _QuizStep({
    required this.quizType,
    required this.questions,
    required this.passingScore,
    required this.locked,
    required this.alreadyCompleted,
    this.contextTitle,
    this.initialElapsedSeconds,
    this.initialSelections = const <String, int>{},
    this.revealResults = false,
    this.finalPassedPendingComplete = false,
    this.onCompleteCourse,
    required this.onSubmit,
  });

  @override
  State<_QuizStep> createState() => _QuizStepState();
}

class _QuizStepState extends State<_QuizStep> {
  final Map<String, int> _selected = <String, int>{};
  DateTime? _startedAt;
  int _qIdx = 0;
  Timer? _tick;
  int _elapsedSeconds = 0;
  int? _finalElapsedSeconds;

  bool _submitted = false;
  bool _passed = false;
  double _scorePct = 0;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialSelections);
    _startedAt = DateTime.now();
    _elapsedSeconds = 0;

    // If already completed, show recorded time and keep timer stopped.
    if (widget.alreadyCompleted == true) {
      final initial =
          (widget.initialElapsedSeconds ?? 0).clamp(0, 24 * 60 * 60);
      _finalElapsedSeconds = initial;
      _elapsedSeconds = initial;
      return;
    }

    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_finalElapsedSeconds != null) return;
      final startedAt = _startedAt;
      if (startedAt == null) return;
      setState(() {
        _elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _QuizStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When navigating between different quiz steps (module checkpoints vs final exam),
    // we must reset per-quiz UI state; otherwise the question index can carry over and
    // immediately show "Submit Quiz".
    final questionsChanged = oldWidget.questions.length != widget.questions.length;
    final typeChanged = oldWidget.quizType != widget.quizType;
    final lockChanged = oldWidget.locked != widget.locked ||
        oldWidget.alreadyCompleted != widget.alreadyCompleted;

    if (questionsChanged || typeChanged || lockChanged) {
      _qIdx = 0;
      _selected.clear();
      _selected.addAll(widget.initialSelections);
      _startedAt = DateTime.now();
      _elapsedSeconds = 0;
      _finalElapsedSeconds = widget.alreadyCompleted
          ? (widget.initialElapsedSeconds ?? 0).clamp(0, 24 * 60 * 60)
          : null;
      _submitted = false;
      _passed = false;
      _scorePct = 0;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final q = (total == 0) ? null : widget.questions[_qIdx.clamp(0, total - 1)];
    final selected = q == null ? null : _selected[q.questionId];
    final atLast = total > 0 && _qIdx >= total - 1;

    String headerTitle() {
      if (widget.quizType == 'final_exam') return 'Final Exam';
      return 'Chapter Quiz';
    }

    // Elapsed timer pill (time spent so far).
    String timerLabel() {
      final base = _finalElapsedSeconds ?? _elapsedSeconds;
      final totalSeconds = base.clamp(0, 24 * 60 * 60);
      final m = totalSeconds ~/ 60;
      final s = totalSeconds % 60;
      final mm = m.toString().padLeft(2, '0');
      final ss = s.toString().padLeft(2, '0');
      return '$mm:$ss';
    }

    return Column(
      children: [
        // ── Dark header ─────────────────────────────────────────────
        Container(
          color: const Color(0xFF071A25),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    headerTitle(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Text(
                      timerLabel(),
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    total == 0 ? 'Question 0 of 0' : 'Question ${_qIdx + 1} of $total',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const Spacer(),
                  if ((widget.contextTitle ?? '').trim().isNotEmpty)
                    Text(
                      widget.contextTitle!.trim(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (total > 0)
                Row(
                  children: List.generate(
                    total,
                    (i) => Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(
                          right: i == total - 1 ? 0 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: i <= _qIdx
                              ? kBlue
                              : Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 4),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: const Color(0xFFF4F7FB),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                if (widget.locked) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x1AC0392B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x38C0392B)),
                    ),
                    child: const Text(
                      'This quiz is locked. Instructor must unlock retake.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC0392B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.alreadyCompleted) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x1AD0F5E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x3300B4B4)),
                    ),
                    child: const Text(
                      'Quiz already completed.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00B4B4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (q != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder.withValues(alpha: 0.20)),
                    ),
                    child: Text(
                      q.question,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: kDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final opt in q.options.asMap().entries)
                    _OptionTile(
                      text: opt.value,
                      selected: selected == opt.key,
                      revealResults: widget.revealResults,
                      correct: opt.key == q.correctIndex,
                      onTap: (widget.locked || widget.alreadyCompleted)
                          ? null
                          : () {
                              setState(() {
                                _selected[q.questionId] = opt.key;
                              });
                            },
                    ),
                  const SizedBox(height: 12),
                  if (widget.revealResults && selected != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected == q.correctIndex
                            ? const Color(0x1A22C55E)
                            : const Color(0x1AC0392B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected == q.correctIndex
                              ? const Color(0x3322C55E)
                              : const Color(0x38C0392B),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            selected == q.correctIndex
                                ? '✓ Correct!'
                                : 'Incorrect',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                              color: selected == q.correctIndex
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFC0392B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Correct answer: ${q.options[q.correctIndex]}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0xFF7A1B1B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                ],
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (widget.locked || widget.alreadyCompleted || q == null)
                        ? null
                        : () async {
                            // If final exam has been passed, require explicit completion click.
                            if (widget.quizType == 'final_exam' &&
                                widget.finalPassedPendingComplete == true) {
                              await widget.onCompleteCourse?.call();
                              return;
                            }

                            // After a failed submission, allow retry.
                            if (_submitted && !_passed) {
                              setState(() {
                                _submitted = false;
                                _passed = false;
                                _scorePct = 0;
                                _qIdx = 0;
                                _selected.clear();
                                _startedAt = DateTime.now();
                                _elapsedSeconds = 0;
                                _finalElapsedSeconds = null;
                              });
                              _tick?.cancel();
                              _tick = Timer.periodic(const Duration(seconds: 1), (_) {
                                if (!mounted) return;
                                if (_finalElapsedSeconds != null) return;
                                final startedAt = _startedAt;
                                if (startedAt == null) return;
                                setState(() {
                                  _elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
                                });
                              });
                              return;
                            }

                            // Require selection before advancing.
                            if (selected == null) return;

                            if (!atLast) {
                              setState(() {
                                _qIdx += 1;
                              });
                              return;
                            }

                            final startedAt = _startedAt ?? DateTime.now();
                            final timeSpentSeconds =
                                DateTime.now().difference(startedAt).inSeconds;

                            // Freeze header timer at the exact time taken.
                            _finalElapsedSeconds = timeSpentSeconds;
                            _elapsedSeconds = timeSpentSeconds;
                            _tick?.cancel();
                            _tick = null;

                            int correct = 0;
                            for (final qq in widget.questions) {
                              final sel = _selected[qq.questionId];
                              if (sel != null && sel == qq.correctIndex) correct += 1;
                            }
                            final scorePct = total == 0 ? 0.0 : (correct / total) * 100.0;

                            final passed = widget.quizType == 'checkpoint'
                                ? correct == total
                                : scorePct >= widget.passingScore;

                            final answers = <String, int?>{};
                            for (final qq in widget.questions) {
                              answers[qq.questionId] = _selected[qq.questionId];
                            }

                            await widget.onSubmit(
                              answers,
                              correct,
                              total,
                              scorePct,
                              passed,
                              timeSpentSeconds,
                            );

                            setState(() {
                              _submitted = true;
                              _passed = passed;
                              _scorePct = scorePct;
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      (widget.quizType == 'final_exam' &&
                              widget.finalPassedPendingComplete == true)
                          ? 'Complete Course'
                          : (_submitted && !_passed)
                              ? 'Retry Exam'
                              : (atLast ? 'Submit Quiz' : 'Next Question'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Minimum passing score: ${widget.passingScore}%. Retakes available',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: kMuted.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final bool selected;
  final bool revealResults;
  final bool correct;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.text,
    required this.selected,
    required this.revealResults,
    required this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = revealResults
        ? (correct
            ? const Color(0xFF22C55E)
            : (selected ? const Color(0xFFC0392B) : kBorder.withValues(alpha: 0.22)))
        : (selected
            ? kBlue.withValues(alpha: 0.95)
            : kBorder.withValues(alpha: 0.22));

    final bgColor = revealResults
        ? (correct
            ? const Color(0x1222C55E)
            : (selected ? const Color(0x1AC0392B) : Colors.white))
        : (selected ? kBlue.withValues(alpha: 0.10) : Colors.white);

    final dotColor = revealResults
        ? (correct
            ? const Color(0xFF22C55E)
            : (selected ? const Color(0xFFC0392B) : Colors.transparent))
        : (selected ? kBlue : Colors.transparent);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: revealResults
                        ? (correct
                            ? const Color(0xFF22C55E)
                            : (selected ? const Color(0xFFC0392B) : kBorder))
                        : (selected ? kBlue : kBorder),
                    width: 2,
                  ),
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: kDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewSummaryStep extends StatefulWidget {
  final String courseId;
  final CourseModel course;

  const _ReviewSummaryStep({
    super.key,
    required this.courseId,
    required this.course,
  });

  @override
  State<_ReviewSummaryStep> createState() => _ReviewSummaryStepState();
}

class _ReviewSummaryStepState extends State<_ReviewSummaryStep> {
  bool _loading = true;
  String? _error;

  int? _overallGrade; // rounded average of quiz item best scores
  bool? _overallPassed;
  bool _hasQuizData = false;

  List<_QuizGradeRow> _quizRows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final attemptsRes = await CoursePortalApi.getQuizAttempts(widget.courseId);

      final attemptsRoot = attemptsRes['attempts'] ?? attemptsRes['data'] ?? attemptsRes;

      Map<String, dynamic> attemptsByQuizId = <String, dynamic>{};
      if (attemptsRoot is Map) {
        attemptsByQuizId = attemptsRoot.cast<String, dynamic>();
      } else if (attemptsRoot is List) {
        // Fallback: convert list items into a map by quizId when possible.
        for (final item in attemptsRoot) {
          if (item is! Map) continue;
          final quizId = item['quizId']?.toString() ?? item['quiz_id']?.toString();
          if (quizId == null || quizId.isEmpty) continue;
          attemptsByQuizId[quizId] = item;
        }
      }

      double parseDouble(dynamic value) {
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value.trim()) ?? 0.0;
        return 0.0;
      }

      // bestByQuizId: quizId -> best attempt object (highest scorePct)
      final bestByQuizId = <String, Map<String, dynamic>>{};
      attemptsByQuizId.forEach((quizId, quizMetaRaw) {
        if (quizId.isEmpty) return;
        if (quizMetaRaw is! Map) return;
        final quizMeta = quizMetaRaw.cast<String, dynamic>();
        final attemptsListRaw = quizMeta['attempts'];
        final attemptsList = attemptsListRaw is List ? attemptsListRaw : <dynamic>[];

        Map<String, dynamic>? best;
        double bestScore = -1;
        for (final a in attemptsList) {
          if (a is! Map) continue;
          final attempt = a.cast<String, dynamic>();
          final score = parseDouble(
            attempt['scorePct'] ?? attempt['score_pct'] ?? attempt['score'] ?? 0,
          );
          if (score > bestScore) {
            bestScore = score;
            best = attempt;
          }
        }
        if (best != null) bestByQuizId[quizId] = best;
      });

      final quizRows = <_QuizGradeRow>[];
      for (final module in widget.course.modules) {
        final quizId = 'checkpoint-mod-${module.order}';
        final fundamentals = module.showPdfBeforeQuiz && module.quiz.length > 10;
        final quizType = fundamentals ? 'quiz_fundamentals' : 'checkpoint';
        final title = module.title;

        final best = bestByQuizId[quizId];
        final scorePct = best == null ? null : parseDouble(best['scorePct'] ?? best['score_pct'] ?? best['score'] ?? 0);
        final passed = best == null ? null : (best['passed'] == true);

        quizRows.add(_QuizGradeRow(
          quizId: quizId,
          title: title,
          quizType: quizType,
          scorePct: scorePct,
          passed: passed,
        ));
      }

      // Final exam (if present)
      if (widget.course.finalExamQuestions.isNotEmpty) {
        const quizId = 'final-exam';
        final best = bestByQuizId[quizId];
        final scorePct =
            best == null ? null : parseDouble(best['scorePct'] ?? best['score_pct'] ?? best['score'] ?? 0);
        final passed = best == null ? null : (best['passed'] == true);

        quizRows.add(_QuizGradeRow(
          quizId: quizId,
          title: widget.course.finalExamTitle,
          quizType: 'final_exam',
          scorePct: scorePct,
          passed: passed,
        ));
      }

      final scored = quizRows.where((r) => r.scorePct != null).map((r) => r.scorePct!).toList();
      final hasQuizData = scored.isNotEmpty;
      final overall = hasQuizData
          ? (scored.reduce((a, b) => a + b) / scored.length).round()
          : null;

      setState(() {
        _overallGrade = overall;
        _overallPassed = overall == null ? null : overall >= 70;
        _hasQuizData = hasQuizData;
        _quizRows = quizRows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    final greenBg = const Color(0x1AD0F5E1);
    final redBg = const Color(0x1AC0392B);
    final bgColor = _overallPassed == true ? greenBg : redBg;
    final borderColor = _overallPassed == true ? const Color(0x338BDBA2) : const Color(0x33C0392B);
    final toneText = _overallPassed == true ? const Color(0xFF16A34A) : const Color(0xFFC0392B);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Text(
          'Course Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),

        // Overall grade
        if (!_hasQuizData)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD8E2EC)),
            ),
            child: const Text(
              'No quiz data found.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_overallPassed == true) ? '✓ Passing' : 'Not Passed',
                  style: TextStyle(
                    color: toneText,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Overall Grade: ${_overallGrade ?? 0}%',
                  style: TextStyle(
                    color: toneText,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Grade summary per quiz item
        if (_hasQuizData) ...[
          const Text(
            'Grade Summary',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 10),
          for (final r in _quizRows)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Type: ${r.quizType}',
                      style: TextStyle(color: kMuted, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Score: ${r.scorePct == null ? '—' : '${r.scorePct!.toStringAsFixed(0)}%'}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Result: ${r.passed == null ? '—' : (r.passed == true ? 'Passed' : 'Not Passed')}',
                      style: TextStyle(
                        color: r.passed == true
                            ? const Color(0xFF16A34A)
                            : (r.passed == false ? const Color(0xFFC0392B) : kMuted),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],

        const SizedBox(height: 8),

        // Credit Hours by Module
        const Text(
          'Credit Hours by Module',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBlue.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Credit Hours: ${widget.course.creditHours.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.w900, color: kBlue),
              ),
              const SizedBox(height: 12),
              for (final module in widget.course.modules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          module.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${module.creditHours.toStringAsFixed(1)} hrs',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Action
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CourseCertificateScreen(certCourseId: widget.course.id),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'View Certificate',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizGradeRow {
  final String quizId;
  final String title;
  final String quizType;
  final double? scorePct; // null when no attempt exists
  final bool? passed; // null when no attempt exists

  const _QuizGradeRow({
    required this.quizId,
    required this.title,
    required this.quizType,
    required this.scorePct,
    required this.passed,
  });
}

// ── Identity Verification (BioSig-ID) Dialog ───────────────────────────

class _BioSigDialog extends StatefulWidget {
  final String courseId;
  final String courseName;

  const _BioSigDialog({
    required this.courseId,
    required this.courseName,
  });

  @override
  State<_BioSigDialog> createState() => _BioSigDialogState();
}

class _BioSigDialogState extends State<_BioSigDialog> {
  String step = 'intro'; // intro | verifying | done | error
  String error = '';

  Future<void> _handleVerify() async {
    setState(() {
      step = 'verifying';
      error = '';
    });

    try {
      final res = await CoursePortalApi.biosigVerify(widget.courseId);
      final verified = res['verified'] == true;
      if (!verified) {
        setState(() {
          step = 'error';
          error = 'Identity verification failed. Please try again.';
        });
        return;
      }

      setState(() => step = 'done');
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        step = 'error';
        error = e.toString().isNotEmpty
            ? e.toString()
            : 'Verification failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget contentForStep() {
      if (step == 'verifying') {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 12),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Verifying identity…',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we process your verification.',
              style: TextStyle(fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
          ],
        );
      }

      if (step == 'done') {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 12),
            Icon(Icons.check_circle, size: 56, color: Color(0xFF22C55E)),
            SizedBox(height: 16),
            Text(
              'Identity Verified',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Proceeding to Rules of Conduct…',
              style: TextStyle(fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
          ],
        );
      }

      if (step == 'error') {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.error_outline, size: 56, color: Color(0xCCB91C1C)),
            const SizedBox(height: 16),
            const Text(
              'Verification Failed',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontFamily: 'Poppins', color: Color(0xCCB91C1C)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => setState(() => step = 'intro'),
                child: const Text('Try Again'),
              ),
            ),
          ],
        );
      }

      // intro
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Identity Verification',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'BioSig-ID · Required for NMLS compliance',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBlue.withValues(alpha: 0.22)),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.black),
                children: [
                  const TextSpan(
                    text: 'Course: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: widget.courseName),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x0FFFF5E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x33F59E0B)),
            ),
            child: Row(
              children: const [
                Icon(Icons.error_outline, size: 16, color: Color(0xFFB45309)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BioSig-ID integration pending — placeholder mode active',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Verify Your Identity',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Per NMLS requirements effective August 21, 2017, all Online Self-Study (OSS)\n'
            'courses require BioSig-ID biometric authentication before accessing course content.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 10),
          const Text(
            'This verifies that you — the registered student — are the person completing the course.\n'
            'Your completion will be reported to NMLS under your name and NMLS ID.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              children: const [
                _InfoRow(
                  label: 'Status',
                  value: 'Pending BSI API Integration',
                  isBadge: true,
                ),
                SizedBox(height: 8),
                _InfoRow(
                  label: 'Required by',
                  value: 'NMLS (effective Aug 21, 2017)',
                ),
                SizedBox(height: 8),
                _InfoRow(
                  label: 'Spec source',
                  value: 'nmls.ed1@csbs.org',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _handleVerify,
              icon: const Icon(Icons.fingerprint, size: 18),
              label: const Text(
                'Start Verification (Placeholder)',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    final showCancel = step == 'intro' || step == 'error';

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: contentForStep(),
                ),
              ),
              if (showCancel) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBadge;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = const TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w800,
      color: Colors.black54,
    );

    final valueWidget = isBadge
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: kBorder),
            ),
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
            ),
          )
        : Text(
            value,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          );

    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: 12),
        Flexible(child: valueWidget),
      ],
    );
  }
}

// ── Rules of Conduct (ROCS V4) Dialog ─────────────────────────────────

class _RocsV4Dialog extends StatefulWidget {
  final String courseId;
  final String courseName;

  const _RocsV4Dialog({
    required this.courseId,
    required this.courseName,
  });

  @override
  State<_RocsV4Dialog> createState() => _RocsV4DialogState();
}

class _RocsV4DialogState extends State<_RocsV4Dialog> {
  final ScrollController _scroll = ScrollController();
  bool scrolled = false;
  bool checked = false;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrolled) return;
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final cur = _scroll.position.pixels;
    if (max <= 0) return;
    if (cur >= max - 12) {
      setState(() => scrolled = true);
    }
  }

  Future<void> _saveAgreement() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await CoursePortalApi.rocsAgree(widget.courseId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString().isNotEmpty
            ? e.toString()
            : 'Could not save agreement. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canInteract = scrolled;
    final canAgree = canInteract && checked && !loading;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rules of Conduct for Students',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 4),
              const Text(
                'ROCS V4 · Required before course access',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBlue.withValues(alpha: 0.22)),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'Poppins', color: Colors.black),
                    children: [
                      const TextSpan(
                        text: 'Course: ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: widget.courseName),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (!scrolled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x0FFFF5E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x33F59E0B)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.error_outline, size: 15, color: Color(0xFFB45309)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Read and scroll to the bottom to enable the agreement checkbox.',
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: Scrollbar(
                    controller: _scroll,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.all(14),
                      child: const _RocsV4Body(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              IgnorePointer(
                ignoring: !canInteract,
                child: Opacity(
                  opacity: canInteract ? 1 : 0.55,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: checked,
                        onChanged: (v) => setState(() => checked = v ?? false),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'I have read and agree to the Rules of Conduct for Students (ROCS V4).',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: const TextStyle(fontFamily: 'Poppins', color: Color(0xCCB91C1C), fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: loading ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: canAgree ? _saveAgreement : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: loading
                          ? const Text(
                              'Saving…',
                              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'I Agree — Start Course',
                                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
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
      ),
    );
  }
}

class _RocsV4Body extends StatelessWidget {
  const _RocsV4Body();

  @override
  Widget build(BuildContext context) {
    Text h3(String t) => Text(
          t,
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 16),
        );
    Text h4(String t) => Text(
          t,
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 14),
        );
    Text p(String t) => Text(t, style: const TextStyle(fontFamily: 'Poppins', height: 1.35));
    Widget li(String t) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ', style: TextStyle(fontFamily: 'Poppins')),
              Expanded(child: Text(t, style: const TextStyle(fontFamily: 'Poppins', height: 1.35))),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        h3('Rules of Conduct for Students (ROCS) — Version 4'),
        const SizedBox(height: 8),
        p(
          'The following Rules of Conduct govern your participation in all NMLS-approved\n'
          'education courses offered through this platform. By proceeding, you agree to\n'
          'abide by all rules listed below.',
        ),
        const SizedBox(height: 12),
        h4('1. Identity and Integrity'),
        const SizedBox(height: 6),
        p(
          'You certify that you are the person registered for this course. You may not allow\n'
          'any other individual to complete this course on your behalf. Completion credit will\n'
          'be reported to NMLS under your name and NMLS ID number.',
        ),
        const SizedBox(height: 12),
        h4('2. Independent Completion'),
        const SizedBox(height: 6),
        p(
          'You must complete all course activities independently. You may not use unauthorized\n'
          'aids, share quiz or exam questions with others, or receive assistance from any\n'
          'person during quizzes or exams.',
        ),
        const SizedBox(height: 12),
        h4('3. Prohibited Conduct'),
        const SizedBox(height: 6),
        p('You agree NOT to:'),
        const SizedBox(height: 8),
        li('Attempt to circumvent or "blow through" course content or time requirements.'),
        li('Use any automated tool, script, or program to complete course activities.'),
        li('Share, reproduce, or distribute course content, quiz questions, or exam materials.'),
        li('Misrepresent your identity or credentials in connection with this course.'),
        li('Allow another person to access this course using your credentials.'),
        const SizedBox(height: 12),
        h4('4. Time Requirements'),
        const SizedBox(height: 6),
        p(
          'You understand that this course has minimum time requirements mandated by the SAFE Act\n'
          'and applicable state law. The system will track your active engagement time. You will\n'
          'be automatically logged out after 6 minutes of inactivity and returned to the beginning\n'
          'of the current unit. Time spent inactive does not count toward your seat time.',
        ),
        const SizedBox(height: 12),
        h4('5. Reporting to NMLS'),
        const SizedBox(height: 6),
        p(
          'Upon successful completion of this course, the education provider is required to report\n'
          'your completion to NMLS within seven (7) calendar days. By agreeing to these rules, you\n'
          'authorize the provider to submit your completion data, including your name and NMLS ID,\n'
          'to the Nationwide Multistate Licensing System.',
        ),
        const SizedBox(height: 12),
        h4('6. Consequences of Violations'),
        const SizedBox(height: 6),
        p(
          'Violations of these rules may result in the invalidation of your course completion,\n'
          'reporting to NMLS and applicable state regulators, and possible disciplinary action\n'
          'under state mortgage licensing law.',
        ),
        const SizedBox(height: 12),
        h4('7. Acknowledgment'),
        const SizedBox(height: 6),
        p(
          'By clicking "I Agree" below, you confirm that you have read, understood, and agree to\n'
          'comply with these Rules of Conduct. You further confirm that you are the individual\n'
          'registered for this course and that you will complete it in accordance with all\n'
          'applicable NMLS requirements.',
        ),
      ],
    );
  }
}

