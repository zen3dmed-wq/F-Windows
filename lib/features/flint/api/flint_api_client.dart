import 'dart:convert';
import 'dart:io';

class FlintApiException implements Exception {
  FlintApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'FlintApiException($statusCode): $message';
}

class FlintApiClient {
  FlintApiClient({
    required this.baseUrl,
    this.token,
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  final String baseUrl;
  String? token;
  final HttpClient _httpClient;

  Uri _uri(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final request = await _httpClient.getUrl(_uri(path));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (token != null && token!.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }

    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FlintApiException(
        body.isEmpty ? 'HTTP ${response.statusCode}' : body,
        statusCode: response.statusCode,
      );
    }

    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw FlintApiException('Ожидался JSON-объект');
    }
    return decoded;
  }
}
