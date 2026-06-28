import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../core/theme.dart';
import '../../data/api/genui_models.dart';
import '../widgets/common.dart';

/// The catalog id shared between [CreateSurface] messages and the [Catalog].
const paceShiftCatalogId = 'paceshift';

/// genui component type names. The spec→message mapper ([specToMessages]) must
/// emit exactly these, and the catalog registers a builder for each.
abstract final class PaceComponents {
  static const root = 'PaceColumn';
  static const section = 'PaceSection';
  static const text = 'PaceText';
  static const metric = 'PaceMetric';
  static const chip = 'PaceChip';
  static const banner = 'PaceBanner';
  static const runCard = 'PaceRunCard';
  static const empty = 'PaceEmpty';
  static const button = 'PaceButton';
}

/// An interaction emitted by a generated [PaceComponents.button] or run card.
/// The host (a surface view) decides what to do — deep-link, run an engine
/// action, or re-compose the surface (the feedback loop).
class GenUiAction {
  const GenUiAction({
    required this.action,
    this.runId,
    this.confirm = false,
    this.label,
  });

  /// One of: `open_run`, `apply_reshuffle`, `mark_done`, `ask`.
  final String action;
  final int? runId;
  final bool confirm;
  final String? label;
}

/// Builds the PaceShift genui [Catalog] — maps allow-listed component types to
/// native PaceShift widgets. [onAction] receives button/run-card interactions.
Catalog buildPaceShiftCatalog({required void Function(GenUiAction) onAction}) {
  return Catalog(
    <CatalogItem>[
      _column(),
      _section(),
      _text(),
      _metric(),
      _chip(),
      _banner(),
      _runCard(onAction),
      _empty(),
      _button(onAction),
    ],
    catalogId: paceShiftCatalogId,
  );
}

// ---- Spec → A2UI messages ----------------------------------------------------

/// Translates a backend [GenUiSpec] into the genui A2UI messages that build a
/// surface: a [CreateSurface] plus an [UpdateComponents] carrying a `root`
/// vertical container and one component per block.
List<A2uiMessage> specToMessages(GenUiSpec spec, String surfaceId) {
  final childIds = <String>[];
  final components = <Component>[];
  for (var i = 0; i < spec.blocks.length; i++) {
    final id = 'b$i';
    final component = _blockToComponent(id, spec.blocks[i]);
    if (component == null) continue;
    components.add(component);
    childIds.add(id);
  }
  final root = Component(
    id: 'root',
    type: PaceComponents.root,
    properties: <String, Object?>{'children': childIds},
  );
  return [
    CreateSurface(surfaceId: surfaceId, catalogId: paceShiftCatalogId),
    UpdateComponents(surfaceId: surfaceId, components: [root, ...components]),
  ];
}

Component? _blockToComponent(String id, UiBlock b) {
  final String? type;
  final Map<String, Object?> props;
  switch (b.type) {
    case 'section':
      type = PaceComponents.section;
      props = <String, Object?>{'title': b.title ?? ''};
    case 'text':
      type = PaceComponents.text;
      props = <String, Object?>{'body': b.body ?? b.text ?? ''};
    case 'metric':
      type = PaceComponents.metric;
      props = <String, Object?>{
        'value': b.value ?? '',
        'label': b.label ?? '',
        if (b.tone != null) 'tone': b.tone,
      };
    case 'status_chip':
      type = PaceComponents.chip;
      props = <String, Object?>{
        'label': b.label ?? '',
        if (b.tone != null) 'tone': b.tone,
      };
    case 'shift_banner':
      type = PaceComponents.banner;
      props = <String, Object?>{'text': b.text ?? b.body ?? ''};
    case 'run_card':
      type = PaceComponents.runCard;
      props = <String, Object?>{
        if (b.title != null) 'title': b.title,
        if (b.subtitle != null) 'subtitle': b.subtitle,
        if (b.status != null) 'status': b.status,
        if (b.runId != null) 'runId': b.runId,
      };
    case 'empty_state':
      type = PaceComponents.empty;
      props = <String, Object?>{
        'title': b.title ?? '',
        if (b.message != null) 'message': b.message,
      };
    case 'action_button':
      type = PaceComponents.button;
      props = <String, Object?>{
        'label': b.label ?? b.title ?? 'OK',
        'action': b.action ?? 'ask',
        if (b.style != null) 'style': b.style,
        if (b.runId != null) 'runId': b.runId,
        'confirm': b.confirm ?? false,
      };
    default:
      type = null;
      props = const <String, Object?>{};
  }
  if (type == null) return null;
  return Component(id: id, type: type, properties: props);
}

// ---- Catalog items -----------------------------------------------------------

JsonMap _data(CatalogItemContext ctx) => ctx.data as JsonMap;
String? _s(JsonMap d, String k) => d[k] as String?;

CatalogItem _column() => CatalogItem(
      name: PaceComponents.root,
      dataSchema: S.object(
        properties: {'children': S.list(items: S.string())},
      ),
      widgetBuilder: (ctx) {
        final ids = (_data(ctx)['children'] as List?)?.cast<String>() ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final id in ids)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ctx.buildChild(id),
              ),
          ],
        );
      },
    );

CatalogItem _section() => CatalogItem(
      name: PaceComponents.section,
      dataSchema: S.object(properties: {'title': S.string()}),
      widgetBuilder: (ctx) => SectionHeader(_s(_data(ctx), 'title') ?? ''),
    );

CatalogItem _text() => CatalogItem(
      name: PaceComponents.text,
      dataSchema: S.object(properties: {'body': S.string()}),
      widgetBuilder: (ctx) => Text(
        _s(_data(ctx), 'body') ?? '',
        style: Theme.of(ctx.buildContext).textTheme.bodyMedium,
      ),
    );

CatalogItem _metric() => CatalogItem(
      name: PaceComponents.metric,
      dataSchema: S.object(properties: {
        'value': S.string(),
        'label': S.string(),
        'tone': S.string(),
      }),
      widgetBuilder: (ctx) {
        final d = _data(ctx);
        return MetricBlock(
          value: _s(d, 'value') ?? '',
          label: _s(d, 'label') ?? '',
          color: _toneColor(ctx.buildContext, _s(d, 'tone')),
        );
      },
    );

CatalogItem _chip() => CatalogItem(
      name: PaceComponents.chip,
      dataSchema: S.object(properties: {
        'label': S.string(),
        'tone': S.string(),
      }),
      widgetBuilder: (ctx) {
        final d = _data(ctx);
        final scheme = Theme.of(ctx.buildContext).colorScheme;
        final color = _toneColor(ctx.buildContext, _s(d, 'tone')) ?? scheme.primary;
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _s(d, 'label') ?? '',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        );
      },
    );

CatalogItem _banner() => CatalogItem(
      name: PaceComponents.banner,
      dataSchema: S.object(properties: {'text': S.string()}),
      widgetBuilder: (ctx) {
        final color = _toneColor(ctx.buildContext, 'caution') ?? AppTheme.ember;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz_rounded, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _s(_data(ctx), 'text') ?? '',
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );

CatalogItem _runCard(void Function(GenUiAction) onAction) => CatalogItem(
      name: PaceComponents.runCard,
      dataSchema: S.object(properties: {
        'title': S.string(),
        'subtitle': S.string(),
        'status': S.string(),
        'runId': S.integer(),
      }),
      widgetBuilder: (ctx) {
        final d = _data(ctx);
        final scheme = Theme.of(ctx.buildContext).colorScheme;
        final runId = (d['runId'] as num?)?.toInt();
        final status = _s(d, 'status');
        return Card(
          elevation: 0,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.directions_run_rounded, color: AppTheme.ember),
            title: Text(_s(d, 'title') ?? 'Run'),
            subtitle: _s(d, 'subtitle') == null ? null : Text(_s(d, 'subtitle')!),
            trailing: status == null
                ? null
                : Text(
                    _titleCase(status),
                    style: Theme.of(ctx.buildContext)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
            onTap: runId == null
                ? null
                : () => onAction(GenUiAction(action: 'open_run', runId: runId)),
          ),
        );
      },
    );

CatalogItem _empty() => CatalogItem(
      name: PaceComponents.empty,
      dataSchema: S.object(properties: {
        'title': S.string(),
        'message': S.string(),
      }),
      widgetBuilder: (ctx) {
        final d = _data(ctx);
        return EmptyState(
          icon: Icons.inbox_rounded,
          title: _s(d, 'title') ?? '',
          message: _s(d, 'message'),
        );
      },
    );

CatalogItem _button(void Function(GenUiAction) onAction) => CatalogItem(
      name: PaceComponents.button,
      dataSchema: S.object(properties: {
        'label': S.string(),
        'action': S.string(),
        'style': S.string(),
        'runId': S.integer(),
        'confirm': S.boolean(),
      }),
      widgetBuilder: (ctx) {
        final d = _data(ctx);
        final label = _s(d, 'label') ?? 'OK';
        void fire() => onAction(GenUiAction(
              action: _s(d, 'action') ?? 'ask',
              runId: (d['runId'] as num?)?.toInt(),
              confirm: d['confirm'] == true,
              label: label,
            ));
        final child = Text(label);
        final button = switch (_s(d, 'style')) {
          'outlined' => OutlinedButton(onPressed: fire, child: child),
          'text' => TextButton(onPressed: fire, child: child),
          _ => FilledButton(onPressed: fire, child: child),
        };
        return Align(alignment: Alignment.centerLeft, child: button);
      },
    );

// ---- helpers -----------------------------------------------------------------

Color? _toneColor(BuildContext context, String? tone) {
  final scheme = Theme.of(context).colorScheme;
  return switch (tone) {
    'positive' => const Color(0xFF2E7D32),
    'caution' => const Color(0xFFB26A00),
    'critical' => scheme.error,
    'neutral' => scheme.onSurfaceVariant,
    _ => null,
  };
}

String _titleCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
