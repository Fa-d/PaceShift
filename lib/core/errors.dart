import 'dart:async';
import 'dart:io';

/// Turns an exception into something a runner can read.
///
/// Nothing in `lib/presentation/` may interpolate a raw error into UI text.
/// Before this existed, `plan_screen.dart` rendered `'$e'` (a
/// `DriftWrappedException` with SQL in it) and the sign-in screen rendered a
/// `DioException.toString()` — complete with the API URL and status line —
/// directly to the user in red.
String friendlyError(Object error, {String? fallback}) {
  if (error is SocketException || error is HttpException) {
    return 'No connection. Check your network and try again.';
  }
  if (error is TimeoutException) {
    return 'That took too long. Try again in a moment.';
  }
  if (error is FormatException) {
    return 'We got an unexpected response. Try again in a moment.';
  }

  // Dio and other HTTP clients are matched by shape rather than by type so
  // this file stays dependency-free and usable from anywhere.
  final text = error.toString();
  if (text.contains('401') || text.contains('403')) {
    return 'Your session expired. Sign in again to continue.';
  }
  if (text.contains('SocketException') ||
      text.contains('Connection refused') ||
      text.contains('Network is unreachable')) {
    return 'No connection. Check your network and try again.';
  }
  if (text.contains('429')) {
    return 'Too many requests just now. Try again shortly.';
  }
  if (text.contains('500') || text.contains('502') || text.contains('503')) {
    return 'Our server is having a moment. Try again shortly.';
  }

  return fallback ?? 'Something went wrong. Try again.';
}
