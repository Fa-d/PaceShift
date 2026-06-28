import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_utils.dart';
import '../../core/formatting.dart';
import '../../core/theme.dart';
import '../../domain/models/completed_run.dart';
import '../../domain/engine/reschedule_outcome.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/planned_run.dart';
import '../../domain/readiness/readiness_scorer.dart';
import '../ai/coach_chat_sheet.dart';
import '../genui/genui_surface_view.dart';
import '../providers/providers.dart';
import '../shift/shift_summary.dart';
import '../widgets/common.dart';
import '../widgets/manual_log_sheet.dart';
import '../widgets/pro_gate.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(activePlanProvider).value;
    final todayRuns = ref.watch(todayRunsProvider);
    final t = ref.watch(todayProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(plannedRunsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today', style: theme.textTheme.headlineMedium),
                        Text(formatDateLabel(t),
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => CoachChatSheet.show(context, ref),
                    icon: const Icon(Icons.psychology_rounded),
                    tooltip: 'Ask your coach',
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => context.push('/sync'),
                    icon: const Icon(Icons.sync_rounded),
                    tooltip: 'Sync from watch',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (plan != null) ...[
                Row(
                  children: [
                    Expanded(flex: 3, child: _WeekGlance(planId: plan.id, today: t)),
                    const SizedBox(width: 12),
                    const Expanded(flex: 2, child: _ReadinessGlance()),
                  ],
                ),
                const SizedBox(height: 12),
                const _CoachBriefing(),
              ],
              const SizedBox(height: 16),
              if (todayRuns.isEmpty)
                _RestCard()
              else
                ...todayRuns.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TodayRunCard(run: r),
                    )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => ManualLogSheet.show(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Log an extra run'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const RunTypeBadge(type: RunType.rest, size: 52),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rest day', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Recovery is training too. Enjoy the day off.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayRunCard extends ConsumerWidget {
  const _TodayRunCard({required this.run});

  final PlannedRun run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = RunPalette.of(run.type, scheme);
    final done = run.status == RunStatus.completed;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RunTypeBadge(type: run.type, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(runTypeLabel(run.type),
                          style: theme.textTheme.titleLarge),
                      Text('Week ${run.weekIndex}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (done) StatusChip(status: run.status),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (run.targetDistanceKm != null)
                  _bigMetric(theme, formatKm(run.targetDistanceKm), 'target'),
                if (run.runWalkRatio != null) ...[
                  const SizedBox(width: 28),
                  _bigMetric(theme, run.runWalkRatio!, 'run / walk'),
                ],
                if (run.targetDurationMin != null) ...[
                  const SizedBox(width: 28),
                  _bigMetric(theme, '${run.targetDurationMin}m', 'approx'),
                ],
              ],
            ),
            if (run.notes != null) ...[
              const SizedBox(height: 12),
              Text(run.notes!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
            if (!done) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          ManualLogSheet.show(context, plannedRun: run),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Mark complete'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _couldntRun(context, ref),
                icon: const Icon(Icons.event_busy_rounded),
                label: const Text('Couldn’t run today'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _couldntRun(BuildContext context, WidgetRef ref) async {
    // The adaptive reshuffle is a Pro feature — gate it behind the paywall.
    if (!await ensurePro(context, ref)) return;
    if (!context.mounted) return;
    // Run the adaptive engine so the user immediately sees the reshuffle.
    final outcome = await ref
        .read(schedulerRepositoryProvider)
        .reportCouldNotRun(run.id, today: ref.read(todayProvider));
    if (outcome == null || !context.mounted) return;

    if (outcome.needsDecision) {
      await DegradeDecisionSheet.show(context, outcome.decisions);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.auto_fix_high_rounded),
        title: const Text('Plan adjusted'),
        content: Text(buildShiftSummary(outcome)),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _explainWithAi(context, ref, outcome);
            },
            icon: const Icon(Icons.psychology_rounded),
            label: const Text('Explain with AI'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _explainWithAi(
      BuildContext context, WidgetRef ref, RescheduleOutcome outcome) async {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.psychology_rounded),
        title: const Text('Coach’s take'),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.6),
            // Generative UI grounded in the engine's reshuffle changelog.
            child: GenUiSurfaceView(
              changes: changeLines(outcome),
              composeOnStart: true,
              showInput: false,
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Thanks'),
          ),
        ],
      ),
    );
  }

  Widget _bigMetric(ThemeData theme, String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      );
}

/// Compact readiness glance (mini dial + label).
class _ReadinessGlance extends ConsumerWidget {
  const _ReadinessGlance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readiness = ref.watch(readinessProvider);
    final score = readiness?.score ?? 0;
    final color = switch (readiness?.band) {
      ReadinessBand.onTrack => const Color(0xFF2BB673),
      ReadinessBand.slightlyBehind => const Color(0xFFE0A800),
      ReadinessBand.atRisk => theme.colorScheme.error,
      null => theme.colorScheme.outline,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Readiness', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 5,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: color,
                      ),
                      Text('$score',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(readiness?.label ?? '—',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: color, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact strip showing this week's completed vs planned volume.
class _WeekGlance extends ConsumerWidget {
  const _WeekGlance({required this.planId, required this.today});

  final int planId;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final runs = ref.watch(plannedRunsProvider).value ?? const <PlannedRun>[];
    final completed =
        ref.watch(completedRunsProvider).value ?? const <CompletedRun>[];

    // The training week containing today (Mon–Sun).
    final weekStart = previousOrSameWeekday(today, DateTime.monday);
    final weekEnd = addDays(weekStart, 7);
    final weekRuns = runs.where((r) =>
        !r.scheduledDate.isBefore(weekStart) &&
        r.scheduledDate.isBefore(weekEnd) &&
        r.type.isRun);
    final plannedKm =
        weekRuns.fold<double>(0, (s, r) => s + (r.targetDistanceKm ?? 0));
    final doneKm = completed
        .where((c) =>
            !c.date.isBefore(weekStart) && c.date.isBefore(weekEnd))
        .fold<double>(0, (s, c) => s + c.actualDistanceKm);
    final pct = plannedKm <= 0 ? 0.0 : (doneKm / plannedKm).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('This week', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('${doneKm.toStringAsFixed(0)} / ${plannedKm.toStringAsFixed(0)} km',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.ember, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: AppTheme.ember,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A lazy, Pro-gated AI-composed dashboard section. It does NOT call the model on
/// screen load — it composes a generative-UI briefing (grounded in the plan
/// summary: readiness, week, taper, predicted finish) only when the user taps
/// "Generate", then renders it natively.
class _CoachBriefing extends ConsumerStatefulWidget {
  const _CoachBriefing();

  @override
  ConsumerState<_CoachBriefing> createState() => _CoachBriefingState();
}

class _CoachBriefingState extends ConsumerState<_CoachBriefing> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.ember, size: 20),
                const SizedBox(width: 8),
                Text('Coach’s briefing', style: theme.textTheme.titleMedium),
              ],
            ),
            if (!_show)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      if (!await ensurePro(context, ref)) return;
                      setState(() => _show = true);
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Generate'),
                  ),
                ),
              )
            else
              const GenUiSurfaceView(composeOnStart: true, showInput: false),
          ],
        ),
      ),
    );
  }
}
