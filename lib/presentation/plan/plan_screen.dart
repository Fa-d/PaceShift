import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_utils.dart';
import '../../core/formatting.dart';
import '../../core/theme.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/planned_run.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';
import '../widgets/run_card.dart';

enum _PlanView { week, month }

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  _PlanView _view = _PlanView.week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final runsAsync = ref.watch(plannedRunsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text('Plan', style: theme.textTheme.headlineMedium),
                  const Spacer(),
                  SegmentedButton<_PlanView>(
                    segments: const [
                      ButtonSegment(
                          value: _PlanView.week,
                          icon: Icon(Icons.view_week_rounded)),
                      ButtonSegment(
                          value: _PlanView.month,
                          icon: Icon(Icons.calendar_month_rounded)),
                    ],
                    selected: {_view},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _view = s.first),
                  ),
                ],
              ),
            ),
            Expanded(
              child: runsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load plan',
                    message: '$e'),
                data: (runs) {
                  if (runs.isEmpty) {
                    return const EmptyState(
                      icon: Icons.event_note_rounded,
                      title: 'No plan yet',
                      message: 'Generate a plan to see your schedule here.',
                    );
                  }
                  return _view == _PlanView.week
                      ? _WeekListView(runs: runs)
                      : _MonthView(runs: runs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekListView extends ConsumerWidget {
  const _WeekListView({required this.runs});

  final List<PlannedRun> runs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final byWeek = <int, List<PlannedRun>>{};
    for (final r in runs) {
      byWeek.putIfAbsent(r.weekIndex, () => []).add(r);
    }
    final weeks = byWeek.keys.toList()..sort();

    // Default-scroll to the current week.
    final currentWeek = runs
        .where((r) => !r.scheduledDate.isBefore(addDays(today, -6)))
        .fold<int?>(null, (acc, r) => acc ?? r.weekIndex);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      itemCount: weeks.length,
      itemBuilder: (context, i) {
        final week = weeks[i];
        final weekRuns = byWeek[week]!
          ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
        final volume = weekRuns.fold<double>(
            0, (s, r) => s + (r.type.isRun ? (r.targetDistanceKm ?? 0) : 0));
        final isCurrent = week == currentWeek;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              'Week $week${isCurrent ? '  • this week' : ''}',
              trailing: Text('${volume.toStringAsFixed(0)} km',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.ember, fontWeight: FontWeight.w700)),
            ),
            ...weekRuns.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RunCard(
                    run: r,
                    onTap: () => context.push('/run/${r.id}'),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _MonthView extends ConsumerStatefulWidget {
  const _MonthView({required this.runs});

  final List<PlannedRun> runs;

  @override
  ConsumerState<_MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<_MonthView> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final t = today();
    _month = DateTime(t.year, t.month);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byDate = <DateTime, List<PlannedRun>>{};
    for (final r in widget.runs) {
      byDate.putIfAbsent(dateOnly(r.scheduledDate), () => []).add(r);
    }

    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1; // Mon=1
    final cells = <DateTime?>[
      ...List.filled(leadingBlanks, null),
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(_month.year, _month.month, d),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() =>
                    _month = DateTime(_month.year, _month.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text('${monthName(_month.month)} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium),
              ),
              IconButton(
                onPressed: () => setState(() =>
                    _month = DateTime(_month.year, _month.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (var d = 1; d <= 7; d++)
                Expanded(
                  child: Center(
                    child: Text(weekdayName(d).substring(0, 1),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.72,
            ),
            itemCount: cells.length,
            itemBuilder: (context, i) {
              final date = cells[i];
              if (date == null) return const SizedBox.shrink();
              final dayRuns = byDate[date] ?? const [];
              return _MonthDayCell(date: date, runs: dayRuns);
            },
          ),
        ),
        if (byDate.isNotEmpty) const _MonthLegend(),
      ],
    );
  }
}

class _MonthDayCell extends ConsumerWidget {
  const _MonthDayCell({required this.date, required this.runs});

  final DateTime date;
  final List<PlannedRun> runs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isToday = isSameDate(date, ref.watch(todayProvider));
    final hasRun = runs.any((r) => r.type.isRun);

    return InkWell(
      onTap: hasRun
          ? () {
              final run = runs.firstWhere((r) => r.type.isRun);
              context.push('/run/${run.id}');
            }
          : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? scheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${date.day}',
                style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                for (final r in runs.where((r) => r.type.isRun).take(3))
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor(r.status, scheme),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthLegend extends StatelessWidget {
  const _MonthLegend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget dot(RunStatus s) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: statusColor(s, scheme), shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(runStatusLabel(s),
                style: Theme.of(context).textTheme.labelSmall),
          ],
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          dot(RunStatus.pending),
          dot(RunStatus.completed),
          dot(RunStatus.missed),
          dot(RunStatus.shifted),
        ],
      ),
    );
  }
}
