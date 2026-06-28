import 'package:flutter/material.dart';

import '../../core/formatting.dart';
import '../../core/motion.dart';
import '../../domain/engine/reschedule_outcome.dart';

/// Builds a friendly, plain-language summary of an engine reshuffle
/// (spec §8): "Moved Saturday's 28km long run to Sunday; shortened Tuesday's
/// easy run to keep your week safe."
String buildShiftSummary(RescheduleOutcome outcome) {
  if (!outcome.hasChanges) {
    return 'Nothing needed moving — you’re on track.';
  }
  final parts = <String>[];
  for (final c in outcome.changes) {
    switch (c) {
      case RunMovedChange(:final from, :final to, :final run):
        // Skip the paired "reduced" entry's move noise by describing distance here.
        final km = run.targetDistanceKm != null
            ? '${formatKm(run.targetDistanceKm)} '
            : '';
        parts.add('Moved ${weekdayName(from.weekday)}’s $km'
            '${runTypeLabel(run.type).toLowerCase()} to ${weekdayName(to.weekday)}');
      case RunReducedChange(:final toKm, :final run):
        parts.add('shortened ${runTypeLabel(run.type).toLowerCase()} to '
            '${formatKm(toKm)}');
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
List<String> changeLines(RescheduleOutcome outcome) {
  final lines = <String>[];
  for (final c in outcome.changes) {
    switch (c) {
      case RunMovedChange(:final from, :final to, :final run):
        lines.add('Moved ${runTypeLabel(run.type).toLowerCase()} from '
            '${formatDateLabel(from)} to ${formatDateLabel(to)}'
            '${run.targetDistanceKm != null ? ' (${formatKm(run.targetDistanceKm)})' : ''}');
      case RunReducedChange(:final fromKm, :final toKm, :final run):
        lines.add('Shortened ${runTypeLabel(run.type).toLowerCase()} from '
            '${formatKm(fromKm)} to ${formatKm(toKm)}');
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

/// Bottom sheet shown when the engine can't safely fit a long run and needs the
/// user to choose how to degrade the plan (spec §4.6).
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Your plan needs a decision',
                    style: theme.textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'There isn’t a safe way to fit everything in the time left. Choose '
            'how you’d like to adapt — PaceShift won’t build unsafe weeks.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ...options.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  title: Text(o.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
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
