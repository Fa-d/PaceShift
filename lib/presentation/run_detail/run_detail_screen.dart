import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final runs = ref.watch(plannedRunsProvider).value ?? const <PlannedRun>[];
    final run = runs.where((r) => r.id == runId).firstOrNull;

    if (run == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
            icon: Icons.help_outline_rounded, title: 'Run not found'),
      );
    }

    final completed = (ref.watch(completedRunsProvider).value ?? const [])
        .where((c) => c.plannedRunId == run.id)
        .firstOrNull;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = RunPalette.of(run.type, scheme);

    return Scaffold(
      appBar: AppBar(title: Text(runTypeLabel(run.type))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Hero(
                    tag: 'run-badge-${run.id}',
                    child: RunTypeBadge(type: run.type, size: 56),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatDateLabel(run.scheduledDate),
                            style: theme.textTheme.titleLarge),
                        Text('Week ${run.weekIndex}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant)),
                        if (run.wasShifted) ...[
                          const SizedBox(height: 6),
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
          ),
          const SizedBox(height: 16),
          SectionHeader('Target', trailing: Icon(Icons.flag_outlined,
              size: 18, color: color)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 32,
                runSpacing: 16,
                children: [
                  MetricBlock(
                      value: formatKm(run.targetDistanceKm),
                      label: 'Distance',
                      countTo: run.targetDistanceKm,
                      countFormat: (n) => formatKm(n.toDouble())),
                  if (run.targetPaceSecPerKm != null)
                    MetricBlock(
                        value: formatPace(run.targetPaceSecPerKm!),
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
          ),
          if (run.isStructured) ...[
            const SizedBox(height: 16),
            SectionHeader('Workout',
                trailing: Icon(Icons.timeline_rounded, size: 18, color: color)),
            _SegmentsCard(run: run, color: color),
          ],
          const SizedBox(height: 16),
          SectionHeader('Actual',
              trailing: Icon(Icons.check_circle_outline_rounded,
                  size: 18, color: statusColor(RunStatus.completed, scheme))),
          if (completed != null)
            _ActualCard(completed: completed)
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Not logged yet.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            ),
          if (run.notes != null) ...[
            const SizedBox(height: 16),
            SectionHeader('Notes'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(run.notes!),
              ),
            ),
          ],
          const SizedBox(height: 24),
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

class _ActualCard extends StatelessWidget {
  const _ActualCard({required this.completed});

  final CompletedRun completed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                MetricBlock(
                    value: formatKm(completed.actualDistanceKm),
                    label: 'Distance',
                    countTo: completed.actualDistanceKm,
                    countFormat: (n) => formatKm(n.toDouble())),
                MetricBlock(
                    value: formatDuration(completed.durationSec),
                    label: 'Time',
                    countTo: completed.durationSec,
                    countFormat: (n) => formatDuration(n.round())),
                MetricBlock(
                    value: formatPace(completed.avgPaceSecPerKm), label: 'Pace'),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  completed.source == RunSource.healthConnect
                      ? Icons.watch_rounded
                      : Icons.edit_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  completed.source == RunSource.healthConnect
                      ? 'From Health Connect'
                      : 'Logged manually',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a structured session's segments as a labelled list.
class _SegmentsCard extends StatelessWidget {
  const _SegmentsCard({required this.run, required this.color});

  final PlannedRun run;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
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
                    : Text(formatPace(seg.targetPaceSecPerKm!),
                        style: theme.textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
              ),
          ].revealStagger(context),
        ),
      ),
    );
  }

  String _detail(WorkoutSegment s) {
    final amount = s.distanceKm != null
        ? formatKm(s.distanceKm)
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
