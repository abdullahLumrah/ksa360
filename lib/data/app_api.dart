import 'package:http/http.dart' as http;

import 'app_api_config.dart';
import 'auth_session.dart';

/// All app traffic to the KSA Guide API goes through here so a JWT is
/// attached when the user is signed in, and omitted for guests.
class AppApi {
  static Uri uri(String path, [Map<String, String>? query]) {
    final parsed = Uri.parse('${AppApiConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return parsed;
    return parsed.replace(queryParameters: query);
  }

  static Map<String, String> headers({bool json = false}) {
    final token = AuthSession.instance.token;
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(
    Uri uri, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final res = await http.get(uri, headers: headers()).timeout(timeout);
    await _handleAuth(res);
    return res;
  }

  static Future<http.Response> post(
    Uri uri, {
    String? body,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final res = await http
        .post(uri, headers: headers(json: true), body: body)
        .timeout(timeout);
    await _handleAuth(res);
    return res;
  }

  static Future<http.Response> patch(
    Uri uri, {
    String? body,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final res = await http
        .patch(uri, headers: headers(json: true), body: body)
        .timeout(timeout);
    await _handleAuth(res);
    return res;
  }

  static Future<http.Response> delete(
    Uri uri, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final res = await http.delete(uri, headers: headers()).timeout(timeout);
    await _handleAuth(res);
    return res;
  }

  static Future<http.Response> postMultipart(
    Uri uri, {
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(headers());
    req.fields.addAll(fields);
    req.files.addAll(files);
    final streamed = await req.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);
    await _handleAuth(res);
    return res;
  }

  static Future<void> _handleAuth(http.Response res) async {
    if (res.statusCode != 401) return;
    final path = res.request?.url.path ?? '';
    if (path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/google') ||
        path.contains('/analytics/')) {
      return;
    }
    await AuthSession.instance.clearLocal();
  }
}
