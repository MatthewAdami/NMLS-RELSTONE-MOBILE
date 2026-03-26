class QuizQuestionModel {
  final String question;
  final List<String> options;
  final int correctIndex;

  const QuizQuestionModel({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
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
  final List<QuizQuestionModel> quiz;

  const CourseModuleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.quiz,
  });

  factory CourseModuleModel.fromJson(Map<String, dynamic> json) {
    final quizRaw = json['quiz'];
    final quizList = quizRaw is List ? quizRaw : <dynamic>[];

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim()) ?? 0;
      return 0;
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
      quiz: quizList
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestionModel.fromJson)
          .toList(),
    );
  }
}

class CourseModel {
  final String id;
  final String title;
  final String type;
  final num creditHours;
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
    required this.title,
    required this.type,
    required this.creditHours,
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
    final finalQuestionsRaw = finalExamMap['questions'];
    final finalQuestionsList = finalQuestionsRaw is List
        ? finalQuestionsRaw
        : <dynamic>[];
    final finalExamQuestions = finalQuestionsList
        .whereType<Map<String, dynamic>>()
        .map(QuizQuestionModel.fromJson)
        .toList();

    return CourseModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      creditHours: parseNum(creditRaw),
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
