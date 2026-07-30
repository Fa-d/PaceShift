import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/date_utils.dart';
import '../../../core/design.dart';
import '../../../core/formatting.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../domain/progress/plan_phase.dart';
import '../../providers/providers.dart';
import '../../stats/stats_data.dart';
import '../../widgets/common.dart';
import '../../widgets/count_up_text.dart';
import 'volume_ramp.dart';

/// The plan screen's hero: where you are in the plan, the race countdown, this
/// week's volume, the volume ramp, and current-week progress.
///
/// Exactly one [HeroSurface] on the screen — the tier *is* the hierarchy. Tinted
/// with the current week's phase colour so the hero and the ramp read as one.
class PlanHero extends ConsumerWidget {
  const PlanHero({super.key, this.onJumpToWeek});

  /// Called when a ramp rod is tapped. Switches to the week view and scrolls.
  final ValueChanged<int>? onJumpToWeek;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(activePlanProvider).value;
    if (plan == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final units = ref.watch(unitsProvider);
    final t = ref.watch(todayProvider);
    final stats = ref.watch(statsProvider);

    final week = planWeekClamped(plan.startDate, t);
    final phase = phaseForWeek(week,
        totalWeeks: plan.totalWeeks, taperWeeks: plan.taperWeeks);
    final tint = phaseColor(phase, scheme);
    final daysLeft = daysBetween(t, plan.raceDate);

    final wvIndex = week - 1;
    final wv = (wvIndex >= 0 && wvIndex < stats.weeklyVolumes.length)
        ? stats.weeklyVolumes[wvIndex]
        : null;
    final plannedKm = wv?.plannedKm ?? 0;
    final doneKm = wv?.completedKm ?? 0;
    final pct = plannedKm <= 0 ? 0.0 : (doneKm / plannedKm).clamp(0.0, 1.0);

    return HeroSurface(
      tint: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overline: "Week N of M" + phase pill.
          Row(
            children: [
              Flexible(
                child: Text('Week $week of ${plan.totalWeeks}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.primary)),
              ),
              const SizedBox(width: Space.sm),
              _PhasePill(phase: phase, color: tint),
            ],
          ),
          const SizedBox(height: Space.lg),
          // Two hero metrics, each scaled to fit so a long value or a large text
          // scale never overflows.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _daysMetric(context, daysLeft)),
              const SizedBox(width: Space.xl),
              Expanded(
                child: _metric(
                  context,
                  number: CountUpText(
                    value: units.toDisplay(plannedKm),
                    format: (n) => '${formatDecimal(n)} ${units.distanceLabel}',
                  ),
                  caption: 'this week',
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(formatDateLabel(plan.raceDate),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: Space.md),
          VolumeRamp(
            volumes: stats.weeklyVolumes,
            color: tint,
            currentWeek: week,
            units: units,
            onWeekTap: onJumpToWeek,
          ),
          const SizedBox(height: Space.md),
          // Current-week planned-vs-done bar.
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
                      color: tint,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.sm),
              Text(
                '${units.distanceValue(doneKm)} / '
                '${units.distanceValue(plannedKm)} ${units.distanceLabel}',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Days-to-race, or "Race day" / "Race complete" on and after the race — never
  /// a negative countdown.
  Widget _daysMetric(BuildContext context, int daysLeft) {
    if (daysLeft > 0) {
      return _metric(
        context,
        number: CountUpText(value: daysLeft, format: (n) => '${n.round()}'),
        caption: 'days to race',
      );
    }
    return _metric(
      context,
      number: Text(daysLeft == 0 ? 'Race day' : 'Race complete'),
      caption: daysLeft == 0 ? 'today' : 'complete',
    );
  }

  Widget _metric(BuildContext context,
      {required Widget number, required String caption}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: DefaultTextStyle.merge(
            style: theme.textTheme.displaySmall!,
            child: number,
          ),
        ),
        const SizedBox(height: Space.xs),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _PhasePill extends StatelessWidget {
  const _PhasePill({required this.phase, required this.color});

  final PlanPhase phase;
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
      child: Text(
        phase.label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
