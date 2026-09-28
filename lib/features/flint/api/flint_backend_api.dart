import 'dart:convert';
import 'dart:io';

import '../flint_config.dart';

class FlintBackendException implements Exception {
  FlintBackendException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'FlintBackendException($statusCode): $message';
}

class FlintBackendApi {
  FlintBackendApi({
    String? baseUrl,
    String? token,
    HttpClient? client,
  })  : baseUrl = (baseUrl ?? FlintConfig.apiBaseUrl).trim(),
        token = token ?? FlintConfig.apiToken,
        _client = client ?? HttpClient();

  final String baseUrl;
  String token;
  final HttpClient _client;

  bool get configured => baseUrl.isNotEmpty;

  Uri _uri(String path) {
    if (!configured) {
      throw FlintBackendException(
        'FLINT_API_BASE_URL не задан',
      );
    }

    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final suffix = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$suffix');
  }

  Future<dynamic> getAny(String path) async {
    final request = await _client.getUrl(_uri(path));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    if (token.trim().isNotEmpty) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${token.trim()}',
      );
    }

    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FlintBackendException(
        body.isEmpty ? 'HTTP ${response.statusCode}' : body,
        statusCode: response.statusCode,
      );
    }

    if (body.trim().isEmpty) return null;
    return jsonDecode(body);
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final data = await getAny(path);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    throw FlintBackendException('API вернул не JSON-объект');
  }
}
