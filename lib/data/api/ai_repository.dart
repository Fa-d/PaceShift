import 'package:dio/dio.dart';

import 'api_client.dart';

/// One coaching chat turn.
class CoachTurn {
  const CoachTurn({required this.role, required this.content});
  final String role; // "user" | "assistant"
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Calls the backend AI proxy (Claude via Ktor). All requests require a Pro
/// account; failures surface a friendly message rather than throwing raw.
class AiRepository {
  AiRepository(this._api);

  final ApiClient _api;

  /// Explains an engine reshuffle, grounded in [changes] (the changelog).
  Future<String> explainChanges({
    required List<String> changes,
    required String planSummary,
  }) async {
    return _post('/ai/explain', {
      'changes': changes,
      'planSummary': planSummary,
    });
  }

  /// Coaching Q&A grounded in the plan summary + prior [turns].
  Future<String> chat({
    required List<CoachTurn> turns,
    required String planSummary,
  }) async {
    return _post('/ai/chat', {
      'messages': turns.map((t) => t.toJson()).toList(),
      'planSummary': planSummary,
    });
  }

  Future<String> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _api.raw.post(path, data: body);
      return (res.data as Map<String, dynamic>)['text'] as String? ?? '';
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 402) return 'AI coaching is a Pro feature — upgrade to unlock it.';
      if (code == 401) return 'Please sign in to use AI coaching.';
      if (code == 503) return 'AI coaching isn’t configured on the server yet.';
      return 'Couldn’t reach the coach right now. Please try again.';
    }
  }
}
