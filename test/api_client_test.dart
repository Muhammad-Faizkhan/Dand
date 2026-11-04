import 'dart:convert';

import 'package:dandcollection/controllers/auth_controller.dart';
import 'package:dandcollection/core/api/api_client.dart';
import 'package:dandcollection/core/api/auth_api.dart';
import 'package:dandcollection/core/api/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  test('refreshes once on 401 and retries with the new token', () async {
    final tokens = MemoryTokenStore();
    await tokens.save('old', 'r1');
    var refreshes = 0;
    final client = ApiClient(
      tokens: tokens,
      baseUrl: 'https://api.test',
      httpClient: MockClient((req) async {
        if (req.url.path == '/api/auth/refresh') {
          refreshes++;
          expect(jsonDecode(req.body), {'refreshToken': 'r1'});
          return _json({'accessToken': 'new', 'refreshToken': 'r2'});
        }
        return req.headers['Authorization'] == 'Bearer new' ? _json({'id': 1}) : _json({'error': 'Expired'}, 401);
      }),
    );

    final results = await Future.wait([client.get('/api/users/me'), client.get('/api/users/me')]);

    expect(results, [
      {'id': 1},
      {'id': 1},
    ]);
    expect(refreshes, 1);
    expect(await tokens.refreshToken, 'r2');
  });

  test('a failed refresh clears the session and reports it', () async {
    final tokens = MemoryTokenStore();
    await tokens.save('old', 'r1');
    var expired = false;
    final client = ApiClient(
      tokens: tokens,
      baseUrl: 'https://api.test',
      httpClient: MockClient((_) async => _json({'error': 'Invalid token'}, 401)),
    )..onSessionExpired = () => expired = true;

    await expectLater(
      client.get('/api/users/me'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
    expect(expired, isTrue);
    expect(await tokens.refreshToken, isNull);
  });

  test('server error messages reach the auth controller', () async {
    final client = ApiClient(
      tokens: MemoryTokenStore(),
      baseUrl: 'https://api.test',
      httpClient: MockClient((_) async => _json({'error': 'Invalid email or password'}, 401)),
    );
    final auth = AuthController(api: AuthApi(client));
    addTearDown(auth.dispose);

    expect(await auth.login(), isFalse);
    expect(auth.loggedIn, isFalse);
    expect(auth.error, 'Invalid email or password');
  });

  test('login stores the token pair', () async {
    final tokens = MemoryTokenStore();
    final client = ApiClient(
      tokens: tokens,
      baseUrl: 'https://api.test',
      httpClient: MockClient((_) async => _json({'accessToken': 'a', 'refreshToken': 'r'})),
    );
    final auth = AuthController(api: AuthApi(client));
    addTearDown(auth.dispose);

    expect(await auth.login(), isTrue);
    expect(auth.loggedIn, isTrue);
    expect(await tokens.accessToken, 'a');
  });
}
