import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/api/auth_api.dart';

/// Holds sign-up / sign-in form state for the onboarding + auth flow.
///
/// Without an [api] (widget tests, design reviews) every call succeeds
/// locally, which is how the app behaved before the backend existed.
class AuthController extends ChangeNotifier {
  AuthController({this.api, this.onSignedIn});

  final AuthApi? api;

  /// Called after a successful login or register so callers can trigger
  /// post-auth data loads (user profile, marketplace, etc.).
  final VoidCallback? onSignedIn;

  bool _busy = false;
  bool get busy => _busy;

  /// Last failure, ready to show to the user.
  String? error;

  /// Set when the server runs with EXPOSE_DEV_CODES, so testers can get past
  /// the code screens without reading the deploy logs.
  String? devCode;

  // The design's sample values only when offline; real sign-in starts blank.
  late final emailCtrl = TextEditingController(text: api == null ? 'rider@example.com' : '');
  late final passwordCtrl = TextEditingController(text: api == null ? 'password' : '');
  late final nameCtrl = TextEditingController(text: api == null ? 'Daniel Dermaree' : '');
  late final confirmCtrl = TextEditingController(text: api == null ? 'password' : '');

  late String _otp = api == null ? '482' : '';
  String get otp => _otp;

  int _onboardingPage = 0;
  int get onboardingPage => _onboardingPage;

  final Set<String> _interests = {'Harley-Davidson', 'Casino Chips'};
  Set<String> get interests => _interests;

  int _selectedPlan = 1;
  int get selectedPlan => _selectedPlan;

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  void setOnboardingPage(int i) {
    _onboardingPage = i;
    notifyListeners();
  }

  void setOtp(String v) {
    _otp = v.length > 6 ? v.substring(0, 6) : v;
    notifyListeners();
  }

  void appendOtp(String d) {
    if (_otp.length < 6) {
      _otp += d;
      notifyListeners();
    }
  }

  void backspaceOtp() {
    if (_otp.isNotEmpty) {
      _otp = _otp.substring(0, _otp.length - 1);
      notifyListeners();
    }
  }

  void toggleInterest(String c) {
    _interests.contains(c) ? _interests.remove(c) : _interests.add(c);
    notifyListeners();
  }

  void selectPlan(int i) {
    _selectedPlan = i;
    notifyListeners();
  }

  String get _email => emailCtrl.text.trim();

  /// Picks up a session saved by a previous launch.
  Future<bool> restoreSession() async {
    final api = this.api;
    if (api == null || !await api.hasSession) return false;
    try {
      await api.me();
      _loggedIn = true;
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> login() async {
    // Flip the flag before the first await so offline callers see it at once.
    final ok = api == null || await _run((api) => api.login(_email, passwordCtrl.text));
    if (ok) {
      _loggedIn = true;
      notifyListeners();
      onSignedIn?.call();
    }
    return ok;
  }

  Future<void> logout() async {
    _loggedIn = false;
    notifyListeners();
    await api?.logout();
  }

  Future<bool> register() {
    final problem = _passwordProblem(passwordCtrl.text, confirmCtrl.text);
    if (problem != null) return _fail(problem);
    return _run((api) async {
      devCode = await api.register(
        email: _email,
        password: passwordCtrl.text,
        username: _usernameFrom(_email),
        fullName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
      );
      _loggedIn = true;
      onSignedIn?.call();
    });
  }

  Future<bool> resendVerification() => _run((api) async => devCode = await api.resendVerification());

  Future<bool> verifyEmail() => _run((api) async {
    await api.verifyEmail(_otp);
    devCode = null;
  });

  Future<bool> requestPasswordReset() => _run((api) async => devCode = await api.forgotPassword(_email));

  Future<bool> verifyResetCode() => _run((api) async {
    await api.verifyResetCode(_email, _otp);
    devCode = null;
  });

  /// The reset code entered on the OTP screen is still in [otp] here.
  Future<bool> resetPassword(String newPassword, String confirm) {
    final problem = _passwordProblem(newPassword, confirm);
    if (problem != null) return _fail(problem);
    return _run((api) => api.resetPassword(_email, _otp, newPassword));
  }

  /// The API wants a username but the design never asks for one, so derive
  /// it from the email. The suffix keeps two "john@" sign-ups apart.
  static String _usernameFrom(String email) {
    // ignore: deprecated_member_use
    final base = email.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final suffix = DateTime.now().millisecondsSinceEpoch.remainder(10000).toString().padLeft(4, '0');
    final trimmed = base.length > 20 ? base.substring(0, 20) : base;
    return '${trimmed.isEmpty ? 'collector' : trimmed}_$suffix';
  }

  String? _passwordProblem(String password, String confirm) {
    if (api == null) return null;
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (password != confirm) return "Passwords don't match.";
    return null;
  }

  Future<bool> _fail(String message) async {
    error = message;
    notifyListeners();
    return false;
  }

  Future<bool> _run(Future<void> Function(AuthApi api) call) async {
    final api = this.api;
    if (api == null) return true;
    if (_busy) return false;
    _busy = true;
    error = null;
    notifyListeners();
    try {
      await call(api);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    nameCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }
}
