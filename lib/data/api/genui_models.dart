/// Client mirror of the backend generative-UI spec (`POST /ai/ui`).
///
/// The backend (GLM 5.2 proxy) returns `{"blocks": [ ... ]}` where each block is
/// an allow-listed [UiBlock]. The client maps these to genui A2UI components for
/// native rendering (see `presentation/genui/paceshift_catalog.dart`). Kept as a
/// plain hand-rolled model (no codegen) so it stays trivial and dependency-free.
class GenUiSpec {
  const GenUiSpec(this.blocks);

  final List<UiBlock> blocks;

  factory GenUiSpec.fromJson(Map<String, dynamic> json) {
    final raw = (json['blocks'] as List?) ?? const [];
    return GenUiSpec(
      raw
          .whereType<Map>()
          .map((e) => UiBlock.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  /// A single safe text block — used as a friendly fallback on errors.
  factory GenUiSpec.message(String body) =>
      GenUiSpec([UiBlock(type: 'text', body: body)]);
}

/// One catalog block. Fields are a permissive superset across all block types
/// (matches the backend `UiBlock`); the renderer reads only what [type] needs.
class UiBlock {
  const UiBlock({
    required this.type,
    this.title,
    this.subtitle,
    this.label,
    this.value,
    this.body,
    this.message,
    this.text,
    this.tone,
    this.status,
    this.runId,
    this.action,
    this.style,
    this.confirm,
  });

  final String type;
  final String? title;
  final String? subtitle;
  final String? label;
  final String? value;
  final String? body;
  final String? message;
  final String? text;
  final String? tone;
  final String? status;
  final int? runId;
  final String? action;
  final String? style;
  final bool? confirm;

  factory UiBlock.fromJson(Map<String, dynamic> j) => UiBlock(
        type: j['type'] as String? ?? 'text',
        title: j['title'] as String?,
        subtitle: j['subtitle'] as String?,
        label: j['label'] as String?,
        value: j['value'] as String?,
        body: j['body'] as String?,
        message: j['message'] as String?,
        text: j['text'] as String?,
        tone: j['tone'] as String?,
        status: j['status'] as String?,
        runId: (j['runId'] as num?)?.toInt(),
        action: j['action'] as String?,
        style: j['style'] as String?,
        confirm: j['confirm'] as bool?,
      );
}
