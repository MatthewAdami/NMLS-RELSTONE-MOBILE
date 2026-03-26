import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  /// LOGIN: matches backend POST /api/auth/login
  /// Backend expects: { email, password }
  /// Backend returns 200: { token, user: { id, name, email, nmls_id, state, role } }
  /// Backend returns 400: { message: 'Invalid credentials' }
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
      print(await prefs.getString('token'));  // To verify if the token is stored
      if (token != null) await prefs.setString('token', token.toString());
      if (user != null) await prefs.setString('user', user.toString());

      return {'success': true, 'user': user};
    }

    // status 400 or 500
    return {
      'success': false,
      'message': data['message'] ?? 'Login failed',
    };
  }

  /// REGISTER: matches backend POST /api/auth/register
  /// Backend expects: { name, email, password, nmls_id?, state? }
  /// Backend returns 201: { token, user: { id, name, email, nmls_id, state, role } }
  /// Backend returns 400: { message: 'Email already registered' }
  ///
  /// NOTE: Web uses { email, password } only on login — register takes full name.
  /// Flutter register mirrors the same backend fields.
  static Future<Map<String, dynamic>> register({
    required String name,      // Single 'name' field — matches User model
    required String email,
    required String password,
    String? nmlsId,            // Optional nmls_id
    String? state,             // Optional state
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
      // Backend returns token + user immediately on register (no email verification)
      final token = data['token'];
      final user = data['user'];

      final prefs = await SharedPreferences.getInstance();
      if (token != null) await prefs.setString('token', token.toString());
      if (user != null) await prefs.setString('user', user.toString());

      return {'success': true, 'user': user};
    }

    // status 400 (email already registered) or 500
    return {
      'success': false,
      'message': data['message'] ?? 'Registration failed',
    };
  }

  /// LOGOUT: clears stored token and user
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

  /// Check if user is currently logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Update profile (Account Setup)
  /// Calls PUT /api/auth/profile
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
    String? address,
    String? nmlsId,
    String? state,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final result = await ApiClient.put(
      ApiConfig.profile,
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        'name': name.trim(),
        'phone': (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null,
        'address': (address != null && address.trim().isNotEmpty) ? address.trim() : null,
        'nmls_id': (nmlsId != null && nmlsId.trim().isNotEmpty) ? nmlsId.trim() : null,
        'state': (state != null && state.trim().isNotEmpty) ? state.trim() : null,
      },
    );

    final int status = result['statusCode'] as int;
    final Map<String, dynamic> data = result['data'] as Map<String, dynamic>;

    if (status >= 200 && status < 300) {
      return {'success': true, 'data': data};
    }

    return {'success': false, 'message': data['message'] ?? 'Profile update failed'};
  }

  /// Change password (Account Setup)
  /// Calls PUT /api/auth/change-password with currentPassword="__setup__"
  static Future<Map<String, dynamic>> changePassword({required String newPassword}) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final result = await ApiClient.put(
      ApiConfig.changePassword,
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        'currentPassword': '__setup__',
        'newPassword': newPassword,
      },
    );

    final int status = result['statusCode'] as int;
    final Map<String, dynamic> data = result['data'] as Map<String, dynamic>;

    if (status >= 200 && status < 300) {
      return {'success': true, 'data': data};
    }

    return {'success': false, 'message': data['message'] ?? 'Password change failed'};
  }
}