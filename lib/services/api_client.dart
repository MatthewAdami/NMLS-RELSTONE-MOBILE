import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body ?? {}),
    );

    // Sometimes backend returns HTML/errors; handle safely
    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      data = {'message': res.body};
    }

    return {
      'statusCode': res.statusCode,
      'data': data,
    };
  }
}