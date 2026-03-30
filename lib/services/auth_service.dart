import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';

class AuthService {
  /// LOGIN: POST /api/auth/login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await ApiClient.post(
      ApiConfig.login,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    final int status = result['statusCode'] as int;
    final Map<String, dynamic> data = result['data'] as Map<String, dynamic>;

    if (status == 200) {
      final token = data['token'];
      final user = data['user'];

      final prefs = await SharedPreferences.getInstance();
      // ✅ Save token as string, user as JSON string (not .toString())
      if (token != null) await prefs.setString('token', token.toString());
      if (user != null) await prefs.setString('user', jsonEncode(user));

      return {'success': true, 'user': user};
    }

    return {
      'success': false,
      'message': data['message'] ?? 'Login failed',
    };
  }

  /// REGISTER: POST /api/auth/register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? nmlsId,
    String? state,
  }) async {
    final result = await ApiClient.post(
      ApiConfig.register,
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        if (nmlsId != null && nmlsId.isNotEmpty) 'nmls_id': nmlsId.trim(),
        if (state != null && state.isNotEmpty) 'state': state.trim(),
      },
    );

    final int status = result['statusCode'] as int;
    final Map<String, dynamic> data = result['data'] as Map<String, dynamic>;

    if (status == 201) {
      final token = data['token'];
      final user = data['user'];

      final prefs = await SharedPreferences.getInstance();
      // ✅ Save token as string, user as JSON string
      if (token != null) await prefs.setString('token', token.toString());
      if (user != null) await prefs.setString('user', jsonEncode(user));

      return {'success': true, 'user': user};
    }

    return {
      'success': false,
      'message': data['message'] ?? 'Registration failed',
    };
  }

  /// LOGOUT
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  /// Get stored JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Get stored user as Map
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr == null) return null;
    try {
      return jsonDecode(userStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Check if user is currently logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}