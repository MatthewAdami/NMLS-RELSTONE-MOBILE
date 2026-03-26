import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'token_provider.dart';

class ApiClientException implements Exception {
  final String message;
  const ApiClientException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiClientException {
  const NetworkException(super.message);
}

class UnauthorizedException extends ApiClientException {
  const UnauthorizedException(super.message);
}

class HttpErrorException extends ApiClientException {
  final int statusCode;
  const HttpErrorException(this.statusCode, super.message);
}

class ApiClient {
  final String baseUrl;
  final TokenProvider tokenProvider;
  final http.Client _httpClient;

  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    try {
      final headers = <String, String>{'Accept': 'application/json'};

      if (auth) {
        final token = await tokenProvider.getToken();
        if (token != null && token.trim().isNotEmpty) {
          final raw = token.trim();
          // Some storage implementations might already include the "Bearer " prefix.
          headers['Authorization'] = raw.toLowerCase().startsWith('bearer ')
              ? raw
              : 'Bearer $raw';
        }
      }

      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: query == null ? null : Map<String, String>.from(query),
      );

      final response = await _httpClient.get(uri, headers: headers);
      final body = response.body.trim();

      // Handle non-2xx responses before attempting to decode JSON.
      // Some servers return HTML/text for errors (including unauthorized).
      if (response.statusCode == 401 || response.statusCode == 403) {
        String message = 'Your session has expired.';
        if (body.isNotEmpty && (body.startsWith('{') || body.startsWith('['))) {
          try {
            final decodedForMessage = jsonDecode(body);
            if (decodedForMessage is Map<String, dynamic>) {
              message = decodedForMessage['message']?.toString() ?? message;
            }
          } catch (_) {
            // Ignore JSON parse issues for error message.
          }
        }
        throw UnauthorizedException(message);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Request failed with status ${response.statusCode}.';
        if (body.isNotEmpty && (body.startsWith('{') || body.startsWith('['))) {
          try {
            final decodedForMessage = jsonDecode(body);
            if (decodedForMessage is Map<String, dynamic>) {
              message = decodedForMessage['message']?.toString() ?? message;
            }
          } catch (_) {
            // Ignore JSON parse issues for error message.
          }
        }
        throw HttpErrorException(response.statusCode, message);
      }

      final dynamic decodedRaw;
      try {
        decodedRaw = body.isEmpty ? null : jsonDecode(body);
      } on FormatException {
        final snippet = body.length > 220 ? '${body.substring(0, 220)}…' : body;
        throw ApiClientException(
          'Invalid JSON received from server. Status: ${response.statusCode}. Body: $snippet',
        );
      }
      final Map<String, dynamic> decoded;
      if (decodedRaw == null) {
        decoded = <String, dynamic>{};
      } else if (decodedRaw is Map<String, dynamic>) {
        decoded = decodedRaw;
      } else if (decodedRaw is List) {
        // Support endpoints that return a top-level JSON array.
        decoded = <String, dynamic>{'data': decodedRaw};
      } else {
        decoded = <String, dynamic>{'data': decodedRaw};
      }

      return decoded;
    } on SocketException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on HttpException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on UnauthorizedException {
      rethrow;
    } on HttpErrorException {
      rethrow;
    } on ApiClientException {
      rethrow;
    } catch (e) {
      throw ApiClientException('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    bool auth = true,
  }) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (auth) {
        final token = await tokenProvider.getToken();
        if (token != null && token.trim().isNotEmpty) {
          final raw = token.trim();
          headers['Authorization'] = raw.toLowerCase().startsWith('bearer ')
              ? raw
              : 'Bearer $raw';
        }
      }

      final uri = Uri.parse('$baseUrl$path');
      final response = await _httpClient.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      final responseBody = response.body.trim();

      // Handle non-2xx responses before attempting to decode JSON.
      if (response.statusCode == 401 || response.statusCode == 403) {
        String message = 'Your session has expired.';
        if (responseBody.isNotEmpty &&
            (responseBody.startsWith('{') || responseBody.startsWith('['))) {
          try {
            final decodedForMessage = jsonDecode(responseBody);
            if (decodedForMessage is Map<String, dynamic>) {
              message = decodedForMessage['message']?.toString() ?? message;
            }
          } catch (_) {
            // Ignore JSON parse issues for error message.
          }
        }
        throw UnauthorizedException(message);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Request failed with status ${response.statusCode}.';
        if (responseBody.isNotEmpty &&
            (responseBody.startsWith('{') || responseBody.startsWith('['))) {
          try {
            final decodedForMessage = jsonDecode(responseBody);
            if (decodedForMessage is Map<String, dynamic>) {
              message = decodedForMessage['message']?.toString() ?? message;
            }
          } catch (_) {
            // Ignore JSON parse issues for error message.
          }
        }
        throw HttpErrorException(response.statusCode, message);
      }

      final dynamic decodedRaw;
      try {
        decodedRaw = responseBody.isEmpty ? null : jsonDecode(responseBody);
      } on FormatException {
        final snippet = responseBody.length > 220
            ? '${responseBody.substring(0, 220)}…'
            : responseBody;
        throw ApiClientException(
          'Invalid JSON received from server. Status: ${response.statusCode}. Body: $snippet',
        );
      }
      final Map<String, dynamic> decoded;
      if (decodedRaw == null) {
        decoded = <String, dynamic>{};
      } else if (decodedRaw is Map<String, dynamic>) {
        decoded = decodedRaw;
      } else if (decodedRaw is List) {
        decoded = <String, dynamic>{'data': decodedRaw};
      } else {
        decoded = <String, dynamic>{'data': decodedRaw};
      }

      return decoded;
    } on SocketException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on HttpException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on UnauthorizedException {
      rethrow;
    } on HttpErrorException {
      rethrow;
    } on ApiClientException {
      rethrow;
    } catch (e) {
      throw ApiClientException('Unexpected error: $e');
    }
  }
}
