import 'package:dio/dio.dart';

import 'api_client.dart';
import 'genui_models.dart';

/// Calls the backend generative-UI proxy (`POST /ai/ui`, GLM 5.2 via Ktor).
/// Pro-gated like [AiRepository]; failures degrade to a friendly text spec rather
/// than throwing, so the renderer always has something safe to show.
class GenUiRepository {
  GenUiRepository(this._api);

  final ApiClient _api;

  /// Composes a UI spec grounded in [planSummary] + the engine [changes]
  /// (the RescheduleOutcome changelog) and an optional free-form [question].
  Future<GenUiSpec> compose({
    required String planSummary,
    List<String> changes = const [],
    String? question,
  }) async {
    try {
      final res = await _api.raw.post('/ai/ui', data: {
        'planSummary': planSummary,
        'changes': changes,
        if (question != null && question.trim().isNotEmpty) 'question': question,
      });
      return GenUiSpec.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      return GenUiSpec.message(_friendly(e.response?.statusCode));
    } catch (_) {
      return GenUiSpec.message('Couldn’t compose a view right now. Please try again.');
    }
  }

  String _friendly(int? code) => switch (code) {
        402 => 'Generative-UI coaching is a Pro feature — upgrade to unlock it.',
        401 => 'Please sign in to use AI coaching.',
        503 => 'Generative UI isn’t configured on the server yet.',
        _ => 'Couldn’t reach the coach right now. Please try again.',
      };
}
