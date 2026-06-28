import 'package:dio/dio.dart';

import 'api_client.dart';
import 'auth_models.dart';

/// Raised for auth failures with a user-friendly message.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Talks to the backend's `/auth/*` endpoints and manages the session.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<bool> hasSession() => _api.hasSession;

  Future<AuthUser> register(String email, String password,
      {String? displayName}) async {
    final body = <String, dynamic>{'email': email, 'password': password};
    if (displayName != null) body['displayName'] = displayName;
    final res = await _post('/auth/register', body);
    return _handleAuth(res);
  }

  Future<AuthUser> login(String email, String password) async {
    final res = await _post('/auth/login', {'email': email, 'password': password});
    return _handleAuth(res);
  }

  /// Exchanges a Google/Apple ID token for our session.
  Future<AuthUser> oauth(String provider, String idToken) async {
    final res = await _post('/auth/oauth/$provider', {'idToken': idToken});
    return _handleAuth(res);
  }

  /// Loads the current profile (used on cold start when a session exists).
  Future<AuthUser?> currentUser() async {
    if (!await _api.hasSession) return null;
    try {
      final res = await _api.raw.get('/profile');
      return AuthUser.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() => _api.clearTokens();

  /// Permanently deletes the account on the server, then clears local tokens.
  Future<void> deleteAccount() async {
    try {
      await _api.raw.delete('/profile');
    } catch (_) {
      // Even if the server call fails, clear the local session.
    }
    await _api.clearTokens();
  }

  Future<Response<dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      return await _api.raw.post(path, data: body);
    } on DioException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<AuthUser> _handleAuth(Response<dynamic> res) async {
    final data = res.data as Map<String, dynamic>;
    await _api.saveTokens(
        data['accessToken'] as String, data['refreshToken'] as String);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  String _messageFor(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Can’t reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
