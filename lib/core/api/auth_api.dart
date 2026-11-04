import 'api_client.dart';

class AuthApi {
  AuthApi(this.client);

  final ApiClient client;

  Future<bool> get hasSession async => await client.tokens.refreshToken != null;

  /// Returns the dev code when the server runs with EXPOSE_DEV_CODES.
  Future<String?> register({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    final data = await client.post(
      '/api/auth/register',
      auth: false,
      body: {'email': email, 'password': password, 'username': username, 'fullName': ?fullName},
    );
    await _saveTokens(data);
    return (data as Map)['devCode'] as String?;
  }

  Future<void> login(String email, String password) async {
    final data = await client.post('/api/auth/login', auth: false, body: {'email': email, 'password': password});
    await _saveTokens(data);
  }

  Future<void> logout() async {
    final refresh = await client.tokens.refreshToken;
    try {
      if (refresh != null) await client.post('/api/auth/logout', body: {'refreshToken': refresh});
    } on ApiException {
      // The local session goes either way; a stale token on the server expires on its own.
    } finally {
      await client.tokens.clear();
    }
  }

  Future<String?> resendVerification() async {
    final data = await client.post('/api/auth/verify-email/resend');
    return (data as Map?)?['devCode'] as String?;
  }

  Future<void> verifyEmail(String code) => client.post('/api/auth/verify-email', body: {'code': code});

  Future<String?> forgotPassword(String email) async {
    final data = await client.post('/api/auth/forgot-password', auth: false, body: {'email': email});
    return (data as Map?)?['devCode'] as String?;
  }

  Future<void> verifyResetCode(String email, String code) =>
      client.post('/api/auth/forgot-password/verify', auth: false, body: {'email': email, 'code': code});

  Future<void> resetPassword(String email, String code, String newPassword) => client.post(
    '/api/auth/reset-password',
    auth: false,
    body: {'email': email, 'code': code, 'newPassword': newPassword},
  );

  Future<Map<String, dynamic>> me() async => (await client.get('/api/users/me')) as Map<String, dynamic>;

  Future<void> _saveTokens(dynamic data) async {
    final map = data as Map;
    await client.tokens.save(map['accessToken'] as String, map['refreshToken'] as String);
  }
}
