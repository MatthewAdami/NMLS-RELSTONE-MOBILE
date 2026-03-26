import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class CoursePortalApiException implements Exception {
  final String message;
  const CoursePortalApiException(this.message);

  @override
  String toString() => message;
}

class CoursePortalApi {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>> _decodeJson(String raw, {required String fallbackMessage}) async {
    try {
      if (raw.trim().isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    } catch (_) {
      return <String, dynamic>{'message': '$fallbackMessage: ${raw.trim()}'};
    }
  }

  static Future<http.Response> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final token = await _getToken();

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.trim().isNotEmpty) {
      final raw = token.trim();
      headers['Authorization'] = raw.toLowerCase().startsWith('bearer ') ? raw : 'Bearer $raw';
    }

    final baseUrl = ApiConfig.baseUrl;
    final apiPrefix = ApiConfig.apiPrefix;
    final uri = Uri.parse('$baseUrl$apiPrefix$path');

    switch (method) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'PUT':
        return await http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
      default:
        throw const CoursePortalApiException('Unsupported HTTP method');
    }
  }

  static Future<Map<String, dynamic>> getJson(String path) async {
    final res = await _request(method: 'GET', path: path);
    final raw = res.body;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = await _decodeJson(raw, fallbackMessage: 'Request failed');
      throw CoursePortalApiException(data['message']?.toString() ?? 'Request failed (${res.statusCode})');
    }
    return _decodeJson(raw, fallbackMessage: 'Invalid JSON');
  }

  static Future<Map<String, dynamic>> postJson(String path, {required Map<String, dynamic> body}) async {
    final res = await _request(method: 'POST', path: path, body: body);
    final raw = res.body;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = await _decodeJson(raw, fallbackMessage: 'POST failed');
      throw CoursePortalApiException(data['message']?.toString() ?? 'POST failed (${res.statusCode})');
    }
    return _decodeJson(raw, fallbackMessage: 'Invalid JSON');
  }

  static Future<Map<String, dynamic>> putJson(String path, {required Map<String, dynamic> body}) async {
    final res = await _request(method: 'PUT', path: path, body: body);
    final raw = res.body;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = await _decodeJson(raw, fallbackMessage: 'PUT failed');
      throw CoursePortalApiException(data['message']?.toString() ?? 'PUT failed (${res.statusCode})');
    }
    return _decodeJson(raw, fallbackMessage: 'Invalid JSON');
  }

  // ── Endpoints from your guide ─────────────────────────────────────────

  static Future<Map<String, dynamic>> rocsCheck(String courseId) async {
    return getJson('/rocs/check/$courseId');
  }

  static Future<Map<String, dynamic>> rocsAgree(String courseId) async {
    // Your guide says POST /api/rocs/agree.
    // Body shape sometimes expects { courseId }.
    return postJson('/rocs/agree', body: {'courseId': courseId});
  }

  static Future<Map<String, dynamic>> getProgress(String courseId) async {
    return getJson('/dashboard/progress/$courseId');
  }

  static Future<Map<String, dynamic>> saveProgress({
    required String courseId,
    required List<int> completedIdxs,
    required int currentIdx,
    required int totalSteps,
  }) async {
    return putJson('/dashboard/progress/$courseId', body: {
      'completed_idxs': completedIdxs,
      'current_idx': currentIdx,
      'total_steps': totalSteps,
    });
  }

  static Future<Map<String, dynamic>> getQuizAttempts(String courseId) async {
    return getJson('/quiz-attempts/$courseId');
  }

  static Future<Map<String, dynamic>> submitQuizAttempt({
    required String courseId,
    required String quizId,
    required String quizTitle,
    required String quizType,
    required int moduleOrder,
    required double scorePct,
    required int correct,
    required int total,
    required bool passed,
    required int passingScore,
    required int timeSpentSeconds,
    required Map<String, dynamic> answers,
  }) async {
    return postJson('/quiz-attempts', body: {
      'courseId': courseId,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'quizType': quizType,
      'moduleOrder': moduleOrder,
      'scorePct': scorePct,
      'correct': correct,
      'total': total,
      'passed': passed,
      'passingScore': passingScore,
      'timeSpentSeconds': timeSpentSeconds,
      'answers': answers,
    });
  }

  static Future<Map<String, dynamic>> saveSeatProgress({
    required String courseId,
    required int seatSecondsDelta,
    required int moduleOrder,
  }) async {
    return putJson('/enrollment/$courseId/progress', body: {
      'seat_seconds_delta': seatSecondsDelta,
      'module_order': moduleOrder,
    });
  }

  static Future<Map<String, dynamic>> completeCourse({required String courseId}) async {
    return postJson('/dashboard/complete', body: {'courseId': courseId});
  }

  static Future<Map<String, dynamic>> completeEnrollment({required String courseId}) async {
    return putJson('/enrollment/$courseId/complete', body: {});
  }

  // ── BioSig gates ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> biosigVerify(String courseId) async {
    return postJson('/biosig/verify', body: {'courseId': courseId});
  }

  static Future<Map<String, dynamic>> biosigStatus(String courseId) async {
    return getJson('/biosig/status/$courseId');
  }
}

