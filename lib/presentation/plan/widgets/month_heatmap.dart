import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/date_utils.dart';
import '../../../core/design.dart';
import '../../../core/formatting.dart';
import '../../../core/theme.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/planned_run.dart';
import '../../../domain/models/training_plan.dart';
import '../../providers/providers.dart';
import '../plan_marks.dart';

/// Gap between calendar day cells in the 7-wide month grid — mark geometry, not
/// layout rhythm, so deliberately not a Space token.
const double _cellGutter = 2;

/// A month calendar heatmap of the plan: each run day is filled in its run-type
/// colour with opacity scaled by distance, status shown as a coloured border,
/// and rest / cross / strength days drawn as a faint icon. Paging clamps to the
/// plan's first and last month.
class MonthHeatmap extends ConsumerStatefulWidget {
  const MonthHeatmap({super.key, required this.runs, required this.plan});

  final List<PlannedRun> runs;
  final TrainingPlan plan;

  @override
  ConsumerState<MonthHeatmap> createState() => _MonthHeatmapState();
}

class _MonthHeatmapState extends ConsumerState<MonthHeatmap> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final t = ref.read(todayProvider);
    // Clamp the initial month to the plan's range so a date outside it doesn't
    // open on an empty month.
    _month = _clamp(DateTime(t.year, t.month));
  }

  DateTime get _firstMonth =>
      DateTime(widget.plan.startDate.year, widget.plan.startDate.month);
  DateTime get _lastMonth =>
      DateTime(widget.plan.raceDate.year, widget.plan.raceDate.month);

  /// [month] confined to the plan's own span.
  DateTime _clamp(DateTime month) {
    if (month.isBefore(_firstMonth)) return _firstMonth;
    if (month.isAfter(_lastMonth)) return _lastMonth;
    return month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final units = ref.watch(unitsProvider);
    final today = ref.watch(todayProvider);

    final byDate = <DateTime, List<PlannedRun>>{};
    for (final r in widget.runs) {
      byDate.putIfAbsent(dateOnly(r.scheduledDate), () => []).add(r);
    }

    // Plan-wide max distance drives the intensity scale.
    final maxKm = widget.runs
        .where((r) => r.type.isRun)
        .fold<double>(0, (m, r) => r.targetDistanceKm != null && r.targetDistanceKm! > m ? r.targetDistanceKm! : m);

    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1; // Mon=1
    final cells = <DateTime?>[
      ...List.filled(leadingBlanks, null),
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(_month.year, _month.month, d),
    ];

    final monthVolume = units.toDisplay(widget.runs
        .where((r) =>
            r.type.isRun &&
            r.scheduledDate.year == _month.year &&
            r.scheduledDate.month == _month.month)
        .fold<double>(0, (s, r) => s + r.loadKm));

    final canPrev = _month.isAfter(_firstMonth);
    final canNext = _month.isBefore(_lastMonth);
    // The month "Today" returns to, clamped like the initial one. A plan
    // generated today starts next Monday, so today's month can sit outside the
    // plan entirely — jumping there would strand the athlete on a blank grid,
    // and there is nothing to go back to, so the button hides instead.
    final todayMonth = _clamp(DateTime(today.year, today.month));
    final pagedAway = _month != todayMonth;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Space.screenH, vertical: Space.xs),
          child: Row(
            children: [
              IconButton(
                onPressed: canPrev
                    ? () => setState(() =>
                        _month = DateTime(_month.year, _month.month - 1))
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('${monthName(_month.month)} ${_month.year}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium),
                    Text(
                      '${formatDecimal(monthVolume)} ${units.distanceLabel}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.primary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: canNext
                    ? () => setState(() =>
                        _month = DateTime(_month.year, _month.month + 1))
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        if (pagedAway)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () => setState(() => _month = todayMonth),
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: const Text('Today'),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: Row(
            children: [
              for (var d = 1; d <= 7; d++)
                Expanded(
                  child: Center(
                    child: Text(weekdayName(d).substring(0, 1),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              Space.lg, Space.xs, Space.lg, Space.xl),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.72,
          ),
          itemCount: cells.length,
          itemBuilder: (context, i) {
            final date = cells[i];
            if (date == null) return const SizedBox.shrink();
            final dayRuns = byDate[date] ?? const [];
            return _MonthDayCell(
              date: date,
              runs: dayRuns,
              maxKm: maxKm,
              units: units,
              isToday: isSameDate(date, today),
              onTap: dayRuns.isEmpty
                  ? null
                  : () => context.push('/run/${_representative(dayRuns).id}'),
            );
          },
        ),
        const _MonthLegend(),
      ],
    );
  }

  /// The run to open when a day is tapped: the first running session, else the
  /// first session of any kind.
  PlannedRun _representative(List<PlannedRun> runs) =>
      runs.firstWhere((r) => r.type.isRun, orElse: () => runs.first);
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.runs,
    required this.maxKm,
    required this.units,
    required this.isToday,
    this.onTap,
  });

  final DateTime date;
  final List<PlannedRun> runs;

  /// Plan-wide longest run, in stored kilometres — the intensity scale's top.
  final double maxKm;
  final UnitSystem units;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // A day outside the plan's range has no planned session — show the number
    // and nothing else. Guarded so `runs.first` never throws on an empty list.
    if (runs.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(_cellGutter),
        alignment: Alignment.center,
        child: Text('${date.day}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: scheme.outlineVariant)),
      );
    }

    final tappable = onTap != null;
    final run = runs.firstWhere((r) => r.type.isRun, orElse: () => runs.first);
    final isRunDay = runs.any((r) => r.type.isRun);
    final completed = runs.any((r) => r.status == RunStatus.completed);
    final km = run.targetDistanceKm ?? 0;

    Color? fill;
    IconData? icon;
    if (isRunDay) {
      fill = RunPalette.of(run.type, scheme)
          .withValues(alpha: intensityAlpha(km, maxKm));
    } else {
      // Rest / cross / strength: a faint type icon, no fill.
      icon = RunPalette.icon(run.type);
    }

    return InkWell(
      key: ValueKey('month-day-${date.year}-${date.month}-${date.day}'),
      onTap: tappable ? onTap : null,
      borderRadius: AppRadius.smAll,
      child: Container(
        margin: const EdgeInsets.all(_cellGutter),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: AppRadius.smAll,
          border: _border(scheme),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            // Drop the km line on a short cell so a large text scale never
            // overflows; the day number is always shown. The threshold scales
            // with text size — a 2× scale needs roughly 2× the room.
            final scale = MediaQuery.textScalerOf(context).scale(1.0);
            final showKm = isRunDay && c.maxHeight > 44 * scale;
            return Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null)
                    Icon(icon, size: 13, color: scheme.outline)
                  else
                    Text('${date.day}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall),
                  if (showKm) ...[
                    const SizedBox(height: 1),
                    Text(
                      // Display units, not stored kilometres. This printed a raw
                      // "6" beside a card reading "3.7 mi" — the one number on
                      // the screen that ignored the athlete's unit setting.
                      units.distanceValue(km),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant, fontSize: 9),
                    ),
                  ],
                  if (completed)
                    Icon(Icons.check_rounded,
                        size: 11, color: scheme.success),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Border? _border(ColorScheme scheme) {
    if (isToday) return Border.all(color: scheme.primary, width: 1.5);
    final run = runs.first;
    switch (run.status) {
      case RunStatus.completed:
        return Border.all(color: scheme.success, width: 1.5);
      case RunStatus.missed:
        return Border.all(color: scheme.danger, width: 1.5);
      case RunStatus.shifted:
        return Border.all(color: scheme.warning, width: 1.2);
      case RunStatus.dropped:
        return Border.all(color: scheme.outlineVariant, width: 1);
      case RunStatus.pending:
        return null;
    }
  }
}

class _MonthLegend extends StatelessWidget {
  const _MonthLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget swatch(Color c, String label) => Padding(
          padding: const EdgeInsets.only(right: Space.md, bottom: Space.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: Space.sm,
                height: Space.sm,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: Space.xs),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
        );
    Widget ring(Color c, String label) => Padding(
          padding: const EdgeInsets.only(right: Space.md, bottom: Space.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: Space.sm,
                height: Space.sm,
                decoration: BoxDecoration(
                    border: Border.all(color: c, width: 1.5),
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: Space.xs),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
      child: Wrap(
        spacing: Space.md,
        runSpacing: Space.sm,
        alignment: WrapAlignment.center,
        children: [
          swatch(RunPalette.of(RunType.easy, scheme), 'Easy'),
          swatch(RunPalette.of(RunType.steady, scheme), 'Steady'),
          swatch(RunPalette.of(RunType.long, scheme), 'Long'),
          ring(scheme.success, 'Done'),
          ring(scheme.danger, 'Missed'),
        ],
      ),
    );
  }
}
