import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/date_utils.dart';
import '../../../core/design.dart';
import '../../../core/formatting.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/planned_run.dart';
import '../../../domain/models/training_plan.dart';
import '../../../domain/progress/plan_phase.dart';
import '../../providers/providers.dart';
import '../../stats/stats_data.dart';
import '../../widgets/pressable.dart';
import '../../widgets/run_card.dart';

/// One training week in the plan list: a rich header (phase, planned-vs-done
/// volume, a Mon→Sun run-type strip) followed by its run cards.
///
/// The header always describes the **full** week ([allWeekRuns]) so the at-a-
/// glance summary never changes shape when a filter narrows the cards; the cards
/// themselves reflect [visibleRuns] (the filtered set). Built from
/// `planWeekStart(plan.startDate, week)` so the strip can never disagree with the
/// engine's own `weekIndex`.
class WeekBlock extends ConsumerWidget {
  const WeekBlock({
    super.key,
    required this.week,
    required this.plan,
    required this.allWeekRuns,
    required this.visibleRuns,
    required this.isCurrent,
  });

  final int week;
  final TrainingPlan plan;
  final List<PlannedRun> allWeekRuns;
  final List<PlannedRun> visibleRuns;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final units = ref.watch(unitsProvider);
    final stats = ref.watch(statsProvider);

    final phase = phaseForWeek(week,
        totalWeeks: plan.totalWeeks, taperWeeks: plan.taperWeeks);
    final phaseTint = phaseColor(phase, scheme);

    // Bounds-checked: the list is contiguous 1-based, but a filtered/extra week
    // index can exceed it.
    final wvIndex = week - 1;
    final wv = (wvIndex >= 0 && wvIndex < stats.weeklyVolumes.length)
        ? stats.weeklyVolumes[wvIndex]
        : null;
    final plannedKm = wv?.plannedKm ??
        allWeekRuns.fold<double>(0, (s, r) => s + r.loadKm);
    final doneKm = wv?.completedKm ??
        allWeekRuns
            .where((r) => r.status == RunStatus.completed)
            .fold<double>(0, (s, r) => s + r.loadKm);
    final pct = plannedKm <= 0 ? 0.0 : (doneKm / plannedKm).clamp(0.0, 1.0);

    final runTypeRuns = allWeekRuns.where((r) => r.type.isRun).toList();
    final completedRuns =
        runTypeRuns.where((r) => r.status == RunStatus.completed).length;

    final weekStart = planWeekStart(plan.startDate, week);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom header rather than SectionHeader: the title flexes so a large
        // text scale plus the "this week" pill can't overflow the row.
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xs, Space.sm, Space.xs, Space.sm),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'WEEK $week · ${phase.label.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: scheme.onSurface),
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: Space.sm),
                _ThisWeekPill(color: phaseTint),
              ],
            ],
          ),
        ),
        // Planned-vs-done bar.
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.smAll,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: pct),
                  duration:
                      AppMotion.on(context) ? AppMotion.fill : Duration.zero,
                  curve: AppMotion.standard,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: Space.sm,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: phaseTint,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Space.sm),
            Flexible(
              child: Text(
                '${units.distanceValue(doneKm)} / '
                '${units.distanceValue(plannedKm)} ${units.distanceLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        // Mon→Sun run-type strip + completion count.
        Row(
          children: [
            for (var offset = 0; offset < 7; offset++)
              Padding(
                padding: EdgeInsets.only(right: offset == 6 ? 0 : Space.xs),
                child: _DayDot(
                  date: addDays(weekStart, offset),
                  runs: allWeekRuns,
                ),
              ),
            // Expanded, not Spacer + Flexible: those split the leftover space
            // evenly, so the count lost half the room it could have used and
            // ellipsised early at a large text scale.
            if (runTypeRuns.isNotEmpty)
              Expanded(
                child: Text('$completedRuns of ${runTypeRuns.length} runs',
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              )
            else
              const Spacer(),
          ],
        ),
        const SizedBox(height: Space.sm),
        for (final r in visibleRuns)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Pressable(
              child: RunCard(
                run: r,
                onTap: () => context.push('/run/${r.id}'),
              ),
            ),
          ),
      ],
    );
  }
}

/// A single day in the week strip: coloured by run type, filled when done, a
/// ring when missed, faint for rest / non-run / empty days.
class _DayDot extends StatelessWidget {
  const _DayDot({required this.date, required this.runs});

  final DateTime date;
  final List<PlannedRun> runs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dayRuns =
        runs.where((r) => isSameDate(r.scheduledDate, date)).toList();
    const size = 11.0;

    if (dayRuns.isEmpty) {
      // A free day — faint dot so the strip still reads as a full week.
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.outlineVariant,
        ),
      );
    }

    final run = dayRuns.first;
    if (!run.type.isRun) {
      // Rest / cross / strength — a hairline ring, no fill.
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant),
        ),
      );
    }

    final color = RunPalette.of(run.type, scheme);
    if (run.status == RunStatus.missed) {
      // A ring in the run-type colour reads as "was due, didn't happen".
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.danger, width: 1.5),
        ),
      );
    }
    final filled = run.status == RunStatus.completed;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Completed at full strength; pending (and moved) planned but not yet
        // done at a muted strength.
        color: filled ? color : color.muted,
      ),
    );
  }
}

class _ThisWeekPill extends StatelessWidget {
  const _ThisWeekPill({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.tint,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text('this week',
          style: theme.textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}
