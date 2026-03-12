import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:5000';
  static const String _localhostBaseUrl = 'http://localhost:5000';

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;

    if (kIsWeb) return _localhostBaseUrl;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidEmulatorBaseUrl;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return _localhostBaseUrl;
    }
  }

  static const String apiPrefix = '/api';

  static String get login => '$baseUrl$apiPrefix/auth/login';
  static String get register => '$baseUrl$apiPrefix/auth/register';
  static String get forgotPassword => '$baseUrl$apiPrefix/auth/forgot-password';
  static String get resetPassword => '$baseUrl$apiPrefix/auth/reset-password';
  static String get resendCode => '$baseUrl$apiPrefix/auth/resend-code';
  static String get health => '$baseUrl$apiPrefix/health';
}