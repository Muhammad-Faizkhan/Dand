import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_store.dart';

/// Pass `--dart-define=API_URL=http://10.0.2.2:4000` to point a build at a
/// local backend; everything else talks to the Railway deployment.
const apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://dandbackend-production.up.railway.app');

class ApiException implements Exception {
  ApiException(this.statusCode, this.message, [this.details]);

  /// 0 means the request never got an answer (offline, timeout, DNS).
  final int statusCode;
  final String message;
  final Object? details;

  bool get isUnauthorized => statusCode == 401;

  /// The plan's bid/item limit or the free trial is used up; show the plan picker.
  bool get upgradeRequired {
    final d = details;
    return d is Map && d['code'] == 'UPGRADE_REQUIRED';
  }

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.tokens, http.Client? httpClient, String? baseUrl})
    : _http = httpClient ?? http.Client(),
      _base = Uri.parse(baseUrl ?? apiBaseUrl);

  final TokenStore tokens;
  final http.Client _http;
  final Uri _base;

  /// Called once a refresh fails, so the app can send the user back to login.
  void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  static const _timeout = Duration(seconds: 20);

  Future<dynamic> get(String path, {Map<String, Object?>? query, bool auth = true}) =>
      _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) => _send('POST', path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Object? body}) => _send('PATCH', path, body: body);

  Future<dynamic> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Multipart upload to `/api/uploads`. Returns the hosted URLs in order.
  Future<List<String>> upload(List<String> filePaths) async {
    Future<http.StreamedResponse> send() async {
      final req = http.MultipartRequest('POST', _uri('/api/uploads'));
      final token = await tokens.accessToken;
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      for (final path in filePaths) {
        req.files.add(await http.MultipartFile.fromPath('files', path));
      }
      return _http.send(req).timeout(const Duration(seconds: 60));
    }

    var streamed = await _guard(send);
    if (streamed.statusCode == 401 && await _tryRefresh()) streamed = await _guard(send);
    final res = await http.Response.fromStream(streamed);
    final data = _decode(res);
    return [for (final url in (data as Map)['urls'] as List) url as String];
  }

  Uri _uri(String path, [Map<String, Object?>? query]) {
    final params = <String, String>{
      for (final e in (query ?? const {}).entries)
        if (e.value != null && e.value.toString().isNotEmpty) e.key: e.value.toString(),
    };
    return _base.replace(path: path, queryParameters: params.isEmpty ? null : params);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool auth = true,
  }) async {
    Future<http.Response> send() async {
      final req = http.Request(method, _uri(path, query));
      req.headers['Accept'] = 'application/json';
      if (body != null) {
        req.headers['Content-Type'] = 'application/json';
        req.body = jsonEncode(body);
      }
      if (auth) {
        final token = await tokens.accessToken;
        if (token != null) req.headers['Authorization'] = 'Bearer $token';
      }
      return http.Response.fromStream(await _http.send(req).timeout(_timeout));
    }

    var res = await _guard(send);
    if (auth && res.statusCode == 401 && await _tryRefresh()) res = await _guard(send);
    return _decode(res);
  }

  Future<T> _guard<T>(Future<T> Function() send) async {
    try {
      return await send();
    } on TimeoutException {
      throw ApiException(0, 'The server took too long to answer. Try again.');
    } on http.ClientException {
      throw ApiException(0, "Can't reach the server. Check your connection.");
    }
  }

  dynamic _decode(http.Response res) {
    final text = res.body;
    final data = text.isEmpty ? null : _tryJson(text);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final message = data is Map && data['error'] is String
        ? data['error'] as String
        : 'Request failed (${res.statusCode})';
    throw ApiException(res.statusCode, message, data is Map ? data['details'] : null);
  }

  Object? _tryJson(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  /// Concurrent 401s share one refresh call; the refresh token rotates, so a
  /// second parallel refresh would fail with an already-used token.
  Future<bool> _tryRefresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    final refresh = await tokens.refreshToken;
    if (refresh == null) return false;

    final res = await _guard(
      () => _http
          .post(
            _uri('/api/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(_timeout),
    );
    if (res.statusCode != 200) {
      await tokens.clear();
      onSessionExpired?.call();
      return false;
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await tokens.save(data['accessToken'] as String, data['refreshToken'] as String);
    return true;
  }
}
