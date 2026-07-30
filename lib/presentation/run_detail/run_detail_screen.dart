import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/errors.dart';
import '../../core/formatting.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../domain/models/completed_run.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/planned_run.dart';
import '../../domain/models/workout_segment.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';
import '../widgets/manual_log_sheet.dart';

class RunDetailScreen extends ConsumerWidget {
  const RunDetailScreen({super.key, required this.runId});

  final int runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reading `.value ?? const []` used to collapse "still loading" into "no
    // runs", so opening a run from a notification reliably greeted the user
    // with "Run not found" before the database had answered.
    return ref.watch(plannedRunsProvider).when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(),
            body: SurfaceError(
              message: friendlyError(e,
                  fallback: 'We couldn’t open this run just now.'),
              onRetry: () => ref.invalidate(plannedRunsProvider),
            ),
          ),
          data: (runs) {
            final run = runs.where((r) => r.id == runId).firstOrNull;
            if (run == null) {
              return Scaffold(
                appBar: AppBar(),
                body: const EmptyState(
                    icon: Icons.help_outline_rounded, title: 'Run not found'),
              );
            }
            return _RunDetailBody(run: run);
          },
        );
  }
}

class _RunDetailBody extends ConsumerWidget {
  const _RunDetailBody({required this.run});

  final PlannedRun run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = (ref.watch(completedRunsProvider).value ?? const [])
        .where((c) => c.plannedRunId == run.id)
        .firstOrNull;
    final plan = ref.watch(activePlanProvider).value;
    final units = ref.watch(unitsProvider);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = RunPalette.of(run.type, scheme);

    return Scaffold(
      appBar: AppBar(title: Text(runTypeLabel(run.type))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Space.screenH, Space.sm, Space.screenH, Space.screenBottom),
        children: [
          HeroSurface(
            tint: color,
            child: Row(
              children: [
                Hero(
                  tag: 'run-badge-${run.id}',
                  child: RunTypeBadge(type: run.type, size: 56),
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatDateLabel(run.scheduledDate),
                          style: theme.textTheme.titleLarge),
                      // A bare "Week 12" says nothing without its denominator.
                      Text(
                          plan == null
                              ? 'Week ${run.weekIndex}'
                              : 'Week ${run.weekIndex} of ${plan.totalWeeks}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      if (run.wasShifted) ...[
                        const SizedBox(height: Space.sm),
                        ShiftBanner(
                            from: run.originalDate, to: run.scheduledDate),
                      ],
                    ],
                  ),
                ),
                StatusChip(status: run.status),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          SectionHeader('Target',
              trailing: Icon(Icons.flag_outlined, size: 18, color: color)),
          QuietSurface(
            padding: const EdgeInsets.all(Space.xl),
            child: Wrap(
              spacing: Space.xxl,
              runSpacing: Space.lg,
              children: [
                MetricBlock(
                    label: 'Distance',
                    countTo: units.toDisplay(run.targetDistanceKm ?? 0),
                    countFormat: (n) =>
                        '${formatDecimal(n)} ${units.distanceLabel}'),
                if (run.targetPaceSecPerKm != null)
                  MetricBlock(
                      value: units.pace(run.targetPaceSecPerKm!),
                      label: 'Target pace'),
                if (run.runWalkRatio != null)
                  MetricBlock(value: run.runWalkRatio!, label: 'Run / walk'),
                if (run.targetDurationMin != null)
                  MetricBlock(
                      value: '${run.targetDurationMin}m',
                      label: 'Duration',
                      countTo: run.targetDurationMin,
                      countFormat: (n) => '${n.round()}m'),
              ],
            ),
          ),
          if (run.isStructured) ...[
            const SizedBox(height: Space.lg),
            SectionHeader('Workout',
                trailing: Icon(Icons.timeline_rounded, size: 18, color: color)),
            _SegmentsCard(run: run, color: color, units: units),
          ],
          const SizedBox(height: Space.lg),
          SectionHeader('Actual',
              trailing: Icon(Icons.check_circle_outline_rounded,
                  size: 18, color: statusColor(RunStatus.completed, scheme))),
          if (completed != null)
            _ActualCard(completed: completed)
          else
            QuietSurface(
              padding: const EdgeInsets.all(Space.xl),
              child: Text('Not logged yet.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          if (run.notes != null) ...[
            const SizedBox(height: Space.lg),
            const SectionHeader('Notes'),
            QuietSurface(
              padding: const EdgeInsets.all(Space.xl),
              child: Text(run.notes!),
            ),
          ],
          const SizedBox(height: Space.xl),
          if (run.status != RunStatus.completed)
            FilledButton.icon(
              onPressed: () => ManualLogSheet.show(context, plannedRun: run),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Log this run'),
            ),
        ],
      ),
    );
  }
}

class _ActualCard extends ConsumerWidget {
  const _ActualCard({required this.completed});

  final CompletedRun completed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final units = ref.watch(unitsProvider);
    return QuietSurface(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.xxl,
            runSpacing: Space.lg,
            children: [
              MetricBlock(
                  label: 'Distance',
                  countTo: units.toDisplay(completed.actualDistanceKm),
                  countFormat: (n) =>
                      '${formatDecimal(n)} ${units.distanceLabel}'),
              // A run logged without a duration stores 0 as the "unknown"
              // sentinel; counting up to "0m" would claim it took no time.
              if (completed.hasDuration)
                MetricBlock(
                    label: 'Time',
                    countTo: completed.durationSec,
                    countFormat: (n) => formatDuration(n.round()))
              else
                const MetricBlock(value: '—', label: 'Time'),
              MetricBlock(
                  value: units.pace(completed.avgPaceSecPerKm), label: 'Pace'),
              if (completed.avgHr != null)
                MetricBlock(
                    value: '${completed.avgHr}',
                    label: 'Avg HR',
                    countTo: completed.avgHr,
                    countFormat: (n) => '${n.round()}'),
              if (completed.maxHr != null)
                MetricBlock(
                    value: '${completed.maxHr}',
                    label: 'Max HR',
                    countTo: completed.maxHr,
                    countFormat: (n) => '${n.round()}'),
              if (completed.calories != null)
                MetricBlock(
                    value: completed.calories!.toStringAsFixed(0),
                    label: 'kcal',
                    countTo: completed.calories,
                    countFormat: (n) => n.round().toString()),
            ],
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Icon(
                completed.source == RunSource.healthConnect
                    ? Icons.watch_rounded
                    : Icons.edit_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: Space.sm),
              Text(
                completed.source == RunSource.healthConnect
                    ? 'Imported automatically'
                    : 'Logged manually',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              // Escape hatch for an automatic match that got it wrong: unlink
              // the workout and reopen the session for the engine.
              if (completed.source == RunSource.healthConnect &&
                  completed.plannedRunId != null) ...[
                const Spacer(),
                TextButton(
                  onPressed: () => ref
                      .read(runRepositoryProvider)
                      .detachCompletedRun(completed),
                  child: const Text('Not this run'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Renders a structured session's segments as a labelled list.
class _SegmentsCard extends StatelessWidget {
  const _SegmentsCard(
      {required this.run, required this.color, required this.units});

  final PlannedRun run;
  final Color color;
  final UnitSystem units;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return QuietSurface(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Column(
        children: [
          for (final seg in run.segments!)
            ListTile(
              dense: true,
              leading: Icon(_iconFor(seg.kind), color: color, size: 20),
              title: Text(seg.label ?? _labelFor(seg.kind)),
              subtitle: Text(_detail(seg)),
              trailing: seg.targetPaceSecPerKm == null
                  ? null
                  : Text(units.pace(seg.targetPaceSecPerKm!),
                      style: theme.textTheme.labelMedium),
            ),
        ].revealStagger(context),
      ),
    );
  }

  String _detail(WorkoutSegment s) {
    final amount = s.distanceKm != null
        ? units.distance(s.distanceKm)
        : (s.durationSec != null ? formatDuration(s.durationSec!) : '');
    return s.reps > 1 ? '${s.reps} × $amount' : amount;
  }

  String _labelFor(SegmentKind k) => switch (k) {
        SegmentKind.warmup => 'Warm-up',
        SegmentKind.hard => 'Hard',
        SegmentKind.recovery => 'Recovery',
        SegmentKind.tempo => 'Tempo',
        SegmentKind.steady => 'Steady',
        SegmentKind.cooldown => 'Cool-down',
      };

  IconData _iconFor(SegmentKind k) => switch (k) {
        SegmentKind.warmup => Icons.local_fire_department_outlined,
        SegmentKind.hard => Icons.bolt_rounded,
        SegmentKind.recovery => Icons.self_improvement_rounded,
        SegmentKind.tempo => Icons.speed_rounded,
        SegmentKind.steady => Icons.trending_flat_rounded,
        SegmentKind.cooldown => Icons.ac_unit_rounded,
      };
}
