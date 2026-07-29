import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/formatting.dart';
import '../../core/motion.dart';
import '../../domain/engine/adaptive_scheduler.dart';
import '../../domain/engine/reschedule_outcome.dart';
import '../../domain/models/enums.dart';
import '../genui/genui_surface_view.dart';
import '../providers/providers.dart';

/// Builds a friendly, plain-language summary of an engine reshuffle
/// (spec §8): "Moved Saturday's 28km long run to Sunday; shortened Tuesday's
/// easy run to keep your week safe."
String buildShiftSummary(RescheduleOutcome outcome, UnitSystem units) {
  if (!outcome.hasChanges) {
    return 'Nothing needed moving — you’re on track.';
  }
  final parts = <String>[];
  for (final c in outcome.changes) {
    switch (c) {
      case RunMovedChange(:final from, :final to, :final run):
        // Skip the paired "reduced" entry's move noise by describing distance here.
        final km = run.targetDistanceKm != null
            ? '${units.distance(run.targetDistanceKm)} '
            : '';
        parts.add('Moved ${weekdayName(from.weekday)}’s $km'
            '${runTypeLabel(run.type).toLowerCase()} to ${weekdayName(to.weekday)}');
      case RunReducedChange(:final toKm, :final run):
        parts.add('shortened ${runTypeLabel(run.type).toLowerCase()} to '
            '${units.distance(toKm)}');
      case RunDroppedChange(:final run):
        parts.add('set aside ${weekdayName(run.scheduledDate.weekday)}’s '
            '${runTypeLabel(run.type).toLowerCase()}');
      case RunExpiredChange(:final run):
        parts.add('let go of a stale ${runTypeLabel(run.type).toLowerCase()}');
      case LongRunRebalancedChange():
        parts.add('rebalanced your long runs');
    }
  }
  if (parts.isEmpty) return 'Your plan has been updated.';
  final body = parts.length == 1
      ? parts.first
      : '${parts.sublist(0, parts.length - 1).join('; ')}; ${parts.last}';
  return '$body — to keep your week safe.';
}

/// The reshuffle as a list of individual change lines — used to ground the AI
/// "explain this change" feature (Claude phrases these facts, never invents).
List<String> changeLines(RescheduleOutcome outcome, UnitSystem units) {
  final lines = <String>[];
  for (final c in outcome.changes) {
    switch (c) {
      case RunMovedChange(:final from, :final to, :final run):
        lines.add('Moved ${runTypeLabel(run.type).toLowerCase()} from '
            '${formatDateLabel(from)} to ${formatDateLabel(to)}'
            '${run.targetDistanceKm != null ? ' (${units.distance(run.targetDistanceKm)})' : ''}');
      case RunReducedChange(:final fromKm, :final toKm, :final run):
        lines.add('Shortened ${runTypeLabel(run.type).toLowerCase()} from '
            '${units.distance(fromKm)} to ${units.distance(toKm)}');
      case RunDroppedChange(:final run, :final reason):
        lines.add('Dropped ${runTypeLabel(run.type).toLowerCase()} on '
            '${formatDateLabel(run.scheduledDate)} — $reason');
      case RunExpiredChange(:final run):
        lines.add('Let go of a stale ${runTypeLabel(run.type).toLowerCase()} '
            'past its catch-up window');
      case LongRunRebalancedChange(:final run):
        lines.add('Rebalanced long runs around '
            '${formatDateLabel(run.scheduledDate)} to stay within the weekly limit');
    }
  }
  return lines;
}

/// Ask the athlete how to degrade the plan, then **carry out their answer**.
///
/// This is the only supported way to show [DegradeDecisionSheet]. Both former
/// call sites awaited the sheet and then threw the returned [DegradeKind] away
/// — the athlete read three options, picked one, and nothing whatsoever
/// happened. Routing every caller through here makes that failure structurally
/// impossible to repeat.
///
/// Dismissing without choosing leaves the decision outstanding on purpose: the
/// plan genuinely still doesn't fit, so the question comes back rather than
/// evaporating.
Future<void> resolveDegradeDecision(
  BuildContext context,
  WidgetRef ref, {
  List<DegradeOption>? options,
}) async {
  final kind = await DegradeDecisionSheet.show(
      context, options ?? AdaptiveScheduler.degradeOptions);
  if (kind == null) return;

  final units = ref.read(unitsProvider);
  final outcome =
      await ref.read(schedulerRepositoryProvider).applyDegradeDecision(kind);
  if (!context.mounted) return;

  final message = outcome == null || !outcome.hasChanges
      ? 'Noted — your plan stays as it is.'
      : buildShiftSummary(outcome, units);
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

/// What the engine just did, in plain language — with the coach's fuller
/// explanation one tap away, grounded in the same changelog.
///
/// This replaces a dialog whose "Explain with AI" action opened a *second*
/// dialog hosting a whole generative-UI surface inside an `AlertDialog`. One
/// sheet, one level.
class PlanAdjustedSheet extends StatefulWidget {
  const PlanAdjustedSheet({
    super.key,
    required this.outcome,
    required this.units,
  });

  final RescheduleOutcome outcome;
  final UnitSystem units;

  static Future<void> show(
      BuildContext context, RescheduleOutcome outcome, UnitSystem units) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PlanAdjustedSheet(outcome: outcome, units: units),
    );
  }

  @override
  State<PlanAdjustedSheet> createState() => _PlanAdjustedSheetState();
}

class _PlanAdjustedSheetState extends State<PlanAdjustedSheet> {
  bool _explain = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Space.screenH, Space.xs, Space.screenH, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded,
                  color: theme.colorScheme.primary),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text('Plan adjusted',
                    style: theme.textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(buildShiftSummary(widget.outcome, widget.units),
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: Space.lg),
          if (_explain)
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: GenUiSurfaceView(
                changes: changeLines(widget.outcome, widget.units),
                composeOnStart: true,
                showInput: false,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => setState(() => _explain = true),
              icon: const Icon(Icons.psychology_rounded),
              label: const Text('Why is this still safe?'),
            ),
          const SizedBox(height: Space.sm),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet shown when the engine can't safely fit a long run and needs the
/// user to choose how to degrade the plan (spec §4.6).
///
/// Prefer [resolveDegradeDecision] over calling [show] directly — it is what
/// applies the answer.
class DegradeDecisionSheet extends StatelessWidget {
  const DegradeDecisionSheet({super.key, required this.options});

  final List<DegradeOption> options;

  static Future<DegradeKind?> show(
      BuildContext context, List<DegradeOption> options) {
    return showModalBottomSheet<DegradeKind>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DegradeDecisionSheet(options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Space.screenH, Space.xs, Space.screenH, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text('Your plan needs a decision',
                    style: theme.textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            'There isn’t a safe way to fit everything in the time left. Choose '
            'how you’d like to adapt — PaceShift won’t build unsafe weeks.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Space.lg),
          ...options.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Card(
                child: ListTile(
                  title: Text(o.title, style: theme.textTheme.titleSmall),
                  subtitle: Text(o.description),
                  onTap: () => Navigator.of(context).pop(o.kind),
                ),
              ),
            ),
          ),
        ].revealStagger(context),
      ),
    );
  }
}
