import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the backend lives. Defaults to this dev machine's LAN IP so a physical
/// device on the same Wi-Fi can reach it. **Update this if your router reassigns
/// the IP** (find it with `ipconfig getifaddr en0`), or override per-run with
/// `--dart-define=API_BASE_URL=...`. The Android emulator and iOS simulator can
/// also reach the host's LAN IP, so this default works for them too (emulator
/// alternative: `http://10.0.2.2:8080`).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.0.213:8080',
);

/// Secure storage keys for the JWT pair.
class _Keys {
  static const access = 'ps_access_token';
  static const refresh = 'ps_refresh_token';
}

/// Thin Dio wrapper that attaches the access token and transparently refreshes
/// it on a 401 using the stored refresh token.
class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ?? Dio(BaseOptions(baseUrl: kApiBaseUrl)) {
    _dio.options.baseUrl = kApiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _refreshing = false;

  Dio get raw => _dio;

  Future<String?> get accessToken => _storage.read(key: _Keys.access);
  Future<String?> get refreshToken => _storage.read(key: _Keys.refresh);
  Future<bool> get hasSession async => (await refreshToken) != null;

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _Keys.access, value: access);
    await _storage.write(key: _Keys.refresh, value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _Keys.access);
    await _storage.delete(key: _Keys.refresh);
  }

  Future<void> _onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Don't attach tokens to the auth endpoints themselves.
    if (!options.path.startsWith('/auth/')) {
      final token = await accessToken;
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    final isAuthCall = err.requestOptions.path.startsWith('/auth/');
    if (!is401 || isAuthCall || _refreshing) return handler.next(err);

    final refreshed = await _tryRefresh();
    if (!refreshed) return handler.next(err);

    // Replay the original request with the new token.
    try {
      final token = await accessToken;
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $token';
      final clone = await _dio.fetch(opts);
      return handler.resolve(clone);
    } catch (_) {
      return handler.next(err);
    }
  }

  Future<bool> _tryRefresh() async {
    final refresh = await refreshToken;
    if (refresh == null) return false;
    _refreshing = true;
    try {
      final res = await _dio.post('/auth/refresh',
          data: {'refreshToken': refresh});
      final data = res.data as Map<String, dynamic>;
      await saveTokens(
          data['accessToken'] as String, data['refreshToken'] as String);
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    } finally {
      _refreshing = false;
    }
  }
}
