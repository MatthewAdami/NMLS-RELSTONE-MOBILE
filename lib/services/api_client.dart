import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      print('📤 POST $url');
      print('📦 Body: ${jsonEncode(body ?? {})}');

      final res = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Status: ${res.statusCode}');
      print('📥 Body: ${res.body}');

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
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      return {
        'statusCode': 0,
        'data': {'message': 'No internet or server unreachable. Check if backend is running.'},
      };
    } on HttpException catch (e) {
      print('❌ HttpException: $e');
      return {
        'statusCode': 0,
        'data': {'message': 'HTTP error: ${e.message}'},
      };
    } catch (e) {
      print('❌ Unknown error: $e');
      return {
        'statusCode': 0,
        'data': {'message': 'Unexpected error: $e'},
      };
    }
  }

  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      print('📤 GET $url');

      final res = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Status: ${res.statusCode}');
      print('📥 Body: ${res.body}');

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
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      return {
        'statusCode': 0,
        'data': {'message': 'No internet or server unreachable.'},
      };
    } catch (e) {
      print('❌ Unknown error: $e');
      return {
        'statusCode': 0,
        'data': {'message': 'Unexpected error: $e'},
      };
    }
  }
}