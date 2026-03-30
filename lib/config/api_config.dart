class ApiConfig {
  // ── Android Emulator (local testing) ────────────────────────────────────
  static const String baseUrl = 'http://10.0.2.2:8000';

  // ── Production (Heroku) ──────────────────────────────────────────────────
  // static const String baseUrl = 'https://relstone-nmls-62fc9b1f5f80.herokuapp.com';

  // ── Real Device (same WiFi) ──────────────────────────────────────────────
  // static const String baseUrl = 'http://192.168.100.3:8000';

  // ── iOS Simulator / Web ──────────────────────────────────────────────────
  // static const String baseUrl = 'http://localhost:8000';

  static const String apiPrefix = '/api';

  // ── Auth ─────────────────────────────────────────────────────────────────
  static String get login          => '$baseUrl$apiPrefix/auth/login';
  static String get register       => '$baseUrl$apiPrefix/auth/register';
  static String get forgotPassword => '$baseUrl$apiPrefix/auth/forgot-password';
  static String get resetPassword  => '$baseUrl$apiPrefix/auth/reset-password';
  static String get resendCode     => '$baseUrl$apiPrefix/auth/resend-code';
  static String get profile        => '$baseUrl$apiPrefix/auth/profile';

  // ── Courses ──────────────────────────────────────────────────────────────
  static String get courses        => '$baseUrl$apiPrefix/courses';
  static String courseDetail(String id) => '$baseUrl$apiPrefix/courses/$id';

  // ── Orders ───────────────────────────────────────────────────────────────
  static String get orders         => '$baseUrl$apiPrefix/orders';

  // ── Dashboard ────────────────────────────────────────────────────────────
  static String get dashboard      => '$baseUrl$apiPrefix/dashboard';

  // ── Certificates ─────────────────────────────────────────────────────────
  static String get certificates   => '$baseUrl$apiPrefix/certificates';

  // ── Instructor ───────────────────────────────────────────────────────────
  static String get instructor     => '$baseUrl$apiPrefix/instructor';

  // ── Enrollment ───────────────────────────────────────────────────────────
  static String get enrollment     => '$baseUrl$apiPrefix/enrollment';

  // ── Quiz Attempts ────────────────────────────────────────────────────────
  static String get quizAttempts   => '$baseUrl$apiPrefix/quiz-attempts';

  // ── ROCS ─────────────────────────────────────────────────────────────────
  static String get rocs           => '$baseUrl$apiPrefix/rocs';

  // ── Support ──────────────────────────────────────────────────────────────
  static String get support        => '$baseUrl$apiPrefix/support';
  static String get contactSupport => '$baseUrl$apiPrefix/support/contact';
  static String get supportMine    => '$baseUrl$apiPrefix/support/mine';
  static String supportDetail(String id)  => '$baseUrl$apiPrefix/support/$id';
  static String supportReply(String id)   => '$baseUrl$apiPrefix/support/$id/reply';

  // ── Testimonials ─────────────────────────────────────────────────────────
  static String get testimonials   => '$baseUrl$apiPrefix/testimonials';

  // ── Biosig ───────────────────────────────────────────────────────────────
  static String get biosig         => '$baseUrl$apiPrefix/biosig';

  // ── Resources (Blog) ─────────────────────────────────────────────────────
  static String get resources      => '$baseUrl$apiPrefix/resources';
  static String resourceDetail(String articleId) =>
      '$baseUrl$apiPrefix/resources/$articleId';
  static String get newsletterSubscribe =>
      '$baseUrl$apiPrefix/resources/newsletter-subscribe';

  // ── States ───────────────────────────────────────────────────────────────
  static String get stateRequirements => '$baseUrl$apiPrefix/states/requirements';
  static String stateRequirementDetail(String stateCode) =>
      '$baseUrl$apiPrefix/states/requirements/$stateCode';

  // ── Exam Prep ────────────────────────────────────────────────────────────
  static String get examPrepQuestions => '$baseUrl$apiPrefix/exam-prep/questions';
  static String get examPrepAnalytics => '$baseUrl$apiPrefix/exam-prep/analytics';
  static String get examPrepAttempt   => '$baseUrl$apiPrefix/exam-prep/attempt';

  // ── Notifications ────────────────────────────────────────────────────────
  static String get notifications     => '$baseUrl$apiPrefix/notifications';

  // ── Health ───────────────────────────────────────────────────────────────
  static String get health            => '$baseUrl$apiPrefix/health';
}