class QuizQuestionModel {
  final String questionId;
  final String question;
  final List<String> options;
  final int correctIndex;

  const QuizQuestionModel({
    required this.questionId,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final questionIdRaw = json['id'] ??
        json['question_id'] ??
        json['questionId'] ??
        json['questionId'.toLowerCase()] ??
        json['number'] ??
        json['question_number'];

    final parsedQuestionId = questionIdRaw?.toString().trim();

    // Ensure the questionId is never empty; the quiz-attempt submission
    // expects stable per-question keys for answer mapping.
    final questionId = parsedQuestionId != null && parsedQuestionId.isNotEmpty
        ? parsedQuestionId
        : (json['question']?.toString().trim().isNotEmpty == true
            ? json['question']!.toString().trim()
            : (json['number']?.toString().trim().isNotEmpty == true
                ? json['number']!.toString().trim()
                : 'q_${json.hashCode}'));

    final optionsRaw = json['options'];

    final options = optionsRaw is List
        ? optionsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final correctRaw = json['correct_index'] ?? json['correctIndex'];

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim()) ?? 0;
      return 0;
    }

    return QuizQuestionModel(
      questionId: questionId,
      question: json['question']?.toString() ?? '',
      options: options,
      correctIndex: parseInt(correctRaw),
    );
  }
}

class CourseModuleModel {
  final String id;
  final String title;
  final String description;
  final int order;
  final num creditHours;
  final String pdfUrl;
  final int pdfStartPage;
  final bool showPdfBeforeQuiz;
  final List<String> sections;
  final String videoUrl;
  final List<QuizQuestionModel> quiz;

  const CourseModuleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.creditHours,
    required this.pdfUrl,
    required this.pdfStartPage,
    required this.showPdfBeforeQuiz,
    required this.sections,
    required this.videoUrl,
    required this.quiz,
  });

  factory CourseModuleModel.fromJson(Map<String, dynamic> json) {
    final quizRaw =
        json['quiz'] ??
        json['quiz_questions'] ??
        json['quizQuestions'] ??
        json['questions'] ??
        json['quizQuestionsList'];
    final quizList = quizRaw is List ? quizRaw : <dynamic>[];

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim()) ?? 0;
      return 0;
    }

    num parseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value.trim()) ?? 0;
      return 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final v = value.trim().toLowerCase();
        return v == 'true' || v == '1' || v == 'yes';
      }
      return false;
    }

    return CourseModuleModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title:
          json['title']?.toString() ??
          json['name']?.toString() ??
          json['module_title']?.toString() ??
          '',
      description: json['description']?.toString() ?? '',
      order: parseInt(json['order'] ?? json['module_order'] ?? json['idx']),
      creditHours: parseNum(json['credit_hours'] ?? json['creditHours'] ?? 0),
      pdfUrl: json['pdf_url']?.toString() ?? json['pdfUrl']?.toString() ?? '',
      pdfStartPage: parseInt(
        json['pdf_start_page'] ?? json['pdfStartPage'] ?? 0,
      ),
      showPdfBeforeQuiz: parseBool(
        json['show_pdf_before_quiz'] ??
            json['showPdfBeforeQuiz'] ??
            false,
      ),
      sections: (json['sections'] is List
          ? (json['sections'] as List).map((e) => e.toString()).toList()
          : <String>[]),
      videoUrl: json['video_url']?.toString() ?? json['videoUrl']?.toString() ?? '',
      quiz: quizList
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestionModel.fromJson)
          .toList(),
    );
  }
}

class CourseModel {
  final String id;
  final String nmlsCourseId;
  final String title;
  final String type;
  final num creditHours;
  final num passingScore;
  final num timeLimitMinutes;
  final String finalExamTitle;
  final String description;
  final num price;
  // Optional fields for cart textbook pricing.
  final bool hasTextbook;
  final num textbookPrice;
  final List<String> statesApproved;
  final bool isActive;
  final List<CourseModuleModel> modules;
  final List<QuizQuestionModel> finalExamQuestions;

  int get modulesCount => modules.length;

  const CourseModel({
    required this.id,
    required this.nmlsCourseId,
    required this.title,
    required this.type,
    required this.creditHours,
    required this.passingScore,
    required this.timeLimitMinutes,
    required this.finalExamTitle,
    required this.description,
    required this.price,
    required this.hasTextbook,
    required this.textbookPrice,
    required this.statesApproved,
    required this.isActive,
    required this.modules,
    required this.finalExamQuestions,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final modulesRaw = json['modules'];
    final statesRaw = json['states_approved'];

    final modulesList = modulesRaw is List ? modulesRaw : <dynamic>[];
    final states = statesRaw is List ? statesRaw : <dynamic>[];

    final creditRaw = json['credit_hours'];
    final priceRaw = json['price'];
    final isActiveRaw = json['is_active'];

    num parseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value.trim()) ?? 0;
      return 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final v = value.trim().toLowerCase();
        return v == 'true' || v == '1' || v == 'yes';
      }
      return false;
    }

    final hasTextbookRaw = json['has_textbook'] ?? json['hasTextbook'] ?? false;
    final textbookPriceRaw =
        json['textbook_price'] ?? json['textbookPrice'] ?? 0;

    final modules = modulesList
        .whereType<Map<String, dynamic>>()
        .map(CourseModuleModel.fromJson)
        .toList();

    final finalExamRaw = json['final_exam'] ?? json['finalExam'] ?? {};
    final finalExamMap = finalExamRaw is Map<String, dynamic>
        ? finalExamRaw
        : <String, dynamic>{};

    final passingScoreRaw = finalExamMap['passing_score'] ??
        finalExamMap['passingScore'] ??
        json['passing_score'] ??
        json['passingScore'] ??
        70;
    final timeLimitRaw = finalExamMap['time_limit_minutes'] ??
        finalExamMap['timeLimitMinutes'] ??
        finalExamMap['time_limit'] ??
        finalExamMap['timeLimit'] ??
        0;
    final finalExamTitleRaw = finalExamMap['title'] ??
        finalExamMap['exam_title'] ??
        finalExamMap['examTitle'] ??
        'Final Exam';

    final finalQuestionsRaw = finalExamMap['questions'];
    final finalQuestionsList = finalQuestionsRaw is List
        ? finalQuestionsRaw
        : <dynamic>[];
    final finalExamQuestions = finalQuestionsList
        .whereType<Map<String, dynamic>>()
        .map(QuizQuestionModel.fromJson)
        .toList();

    final nmlsCourseIdRaw =
        json['nmls_course_id'] ?? json['nmlsCourseId'] ?? json['nmls_courseid'];

    return CourseModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nmlsCourseId: nmlsCourseIdRaw?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      creditHours: parseNum(creditRaw),
      passingScore: parseNum(passingScoreRaw),
      timeLimitMinutes: parseNum(timeLimitRaw),
      finalExamTitle: finalExamTitleRaw?.toString() ?? 'Final Exam',
      description: json['description']?.toString() ?? '',
      price: parseNum(priceRaw),
      hasTextbook: parseBool(hasTextbookRaw),
      textbookPrice: parseNum(textbookPriceRaw),
      statesApproved: states.map((e) => e.toString()).toList(),
      isActive: parseBool(isActiveRaw),
      modules: modules,
      finalExamQuestions: finalExamQuestions,
    );
  }
}
