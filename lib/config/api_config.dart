class ApiConfig {
  // ✅ Choose ONE depending on how you run your app:

    // Web browser (Edge, Chrome, etc.)
    // Override when needed: flutter run -d edge --dart-define=API_BASE_URL=http://localhost:5000
    static const String baseUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:5000',
    );

  // Android Emulator:
  // static const String baseUrl = "http://10.0.2.2:3000";

  // iOS Simulator:
  // static const String baseUrl = "http://localhost:5000";

  // Real device (phone) -> use your PC IP (same WiFi)
  // static const String baseUrl = "http://192.168.100.3:5000";

  static const String apiPrefix = "/api";

  // Auth
  static String get login => "$baseUrl$apiPrefix/auth/login";
  static String get loginLocalFallback => "http://127.0.0.1:5000$apiPrefix/auth/login";
  static List<String> get loginCandidates {
    final hostBased = 'http://${Uri.base.host}:5000$apiPrefix/auth/login';
    final endpoints = <String>[
      login,
      hostBased,
      loginLocalFallback,
      'http://localhost:5000$apiPrefix/auth/login',
    ];
    return endpoints.toSet().toList();
  }
  static String get register => "$baseUrl$apiPrefix/auth/register";
  static String get forgotPassword => "$baseUrl$apiPrefix/auth/forgot-password";
  static String get resetPassword => "$baseUrl$apiPrefix/auth/reset-password";
  static String get resendCode => "$baseUrl$apiPrefix/auth/resend-code";

  // States
  static String get stateRequirements => "$baseUrl$apiPrefix/states/requirements";
  static String stateRequirementDetail(String stateCode) =>
      "$baseUrl$apiPrefix/states/requirements/$stateCode";

  // Resources
  static String get resources => "$baseUrl$apiPrefix/resources";
  static String resourceDetail(String articleId) =>
      "$baseUrl$apiPrefix/resources/$articleId";
  static String get newsletterSubscribe =>
      "$baseUrl$apiPrefix/resources/newsletter-subscribe";

  // Exam prep
  static String get examPrepQuestions => "$baseUrl$apiPrefix/exam-prep/questions";
  static String get examPrepAnalytics => "$baseUrl$apiPrefix/exam-prep/analytics";
  static String get examPrepAttempt => "$baseUrl$apiPrefix/exam-prep/attempt";

  // Notifications
  static String get notifications => "$baseUrl$apiPrefix/notifications";

  // Support
  static String get contactSupport => "$baseUrl$apiPrefix/support/contact";

  // Health
  static String get health => "$baseUrl$apiPrefix/health";
}