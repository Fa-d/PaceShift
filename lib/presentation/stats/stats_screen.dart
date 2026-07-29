import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/formatting.dart';
import '../../core/motion.dart';
import '../../domain/models/enums.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';
import '../widgets/count_up_text.dart';
import '../widgets/readiness_dial.dart';
import 'stats_data.dart';

/// fl_chart mark geometry. Bar corner rounding is a property of the mark, not
/// of the layout grid, so it doesn't come from [AppRadius].
const double _barRadius = 3;
const double _barWidth = 7;
const double _chartHeight = 200;

/// Progress & stats: readiness dial, weekly volume bars, long-run progression,
/// and completion streak (spec §8.5).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final units = ref.watch(unitsProvider);
    final stats = ref.watch(statsProvider);
    final readiness = ref.watch(readinessProvider);
    final prediction = ref.watch(racePredictionProvider);

    return Scaffold(
      body: SafeArea(
        child: stats.isEmpty
            ? const EmptyState(
                icon: Icons.insights_rounded,
                title: 'No stats yet',
                message: 'Log a few runs and your progress will appear here.',
              )
            : ListView(
                padding: Space.screenPadding,
                children: [
                  Text('Progress', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: Space.lg),
                  // Readiness is the one number that answers "how am I doing?",
                  // so it gets the screen's only hero surface.
                  if (readiness != null)
                    HeroSurface(
                      child: Center(child: ReadinessDial(readiness: readiness)),
                    ),
                  if (prediction != null) ...[
                    const SizedBox(height: Space.md),
                    QuietSurface(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(Icons.flag_circle_rounded,
                            color: scheme.primary, size: 32),
                        title: CountUpText(
                            value: prediction.predictedSec,
                            format: (n) => formatFinishTime(n.round()),
                            style: theme.textTheme.titleLarge),
                        subtitle: Text(prediction.confident
                            ? 'Predicted finish · ${units.pace(prediction.paceSecPerKm)}'
                            : 'Early estimate — log a long run to sharpen it'),
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.local_fire_department_rounded,
                          value: '${stats.completionStreak}',
                          label: 'run streak',
                          color: scheme.primary,
                          countTo: stats.completionStreak,
                          countFormat: (n) => '${n.round()}',
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.route_rounded,
                          value: units.distanceValue(stats.totalCompletedKm),
                          label: 'total ${units.distanceLabel}',
                          color: scheme.info,
                          countTo: units.toDisplay(stats.totalCompletedKm),
                          countFormat: (n) => n.round().toString(),
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.terrain_rounded,
                          value: units.distanceValue(stats.longestRunKm),
                          label: 'longest ${units.distanceLabel}',
                          color: scheme.success,
                          countTo: units.toDisplay(stats.longestRunKm),
                          countFormat: (n) => n.round().toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  const SectionHeader('Weekly volume'),
                  QuietSurface(
                    padding: const EdgeInsets.fromLTRB(
                        Space.md, Space.xl, Space.lg, Space.md),
                    child: SizedBox(
                        height: _chartHeight,
                        child: _WeeklyVolumeChart(
                            data: stats.weeklyVolumes, units: units)),
                  ),
                  const SizedBox(height: Space.sm),
                  const _LegendRow(),
                  const SizedBox(height: Space.lg),
                  const SectionHeader('Long-run progression'),
                  QuietSurface(
                    padding: const EdgeInsets.fromLTRB(
                        Space.md, Space.xl, Space.lg, Space.md),
                    child: SizedBox(
                        height: _chartHeight,
                        child: _LongRunChart(
                            data: stats.longRunProgression, units: units)),
                  ),
                ].revealStagger(context),
              ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.countTo,
    this.countFormat,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final num? countTo;
  final String Function(num)? countFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.titleLarge;
    return QuietSurface(
      padding: const EdgeInsets.symmetric(
          vertical: Space.lg, horizontal: Space.md),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: Space.sm),
          if (countTo != null && countFormat != null)
            CountUpText(
                value: countTo!, format: countFormat!, style: valueStyle)
          else
            Text(value, style: valueStyle),
          Text(label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _WeeklyVolumeChart extends StatelessWidget {
  const _WeeklyVolumeChart({required this.data, required this.units});

  final List<WeeklyVolume> data;
  final UnitSystem units;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = units.toDisplay(data.fold<double>(
            0,
            (m, w) => [m, w.plannedKm, w.completedKm]
                .reduce((a, b) => a > b ? a : b))) *
        1.2;

    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 10 : maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (maxY / 4).clamp(5, 100).toDouble(),
              getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
                  style: theme.textTheme.labelSmall),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                // Show every other week label to avoid crowding.
                if (data.length > 8 && i.isOdd) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Text('W${data[i].week}',
                      style: theme.textTheme.labelSmall),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: units.toDisplay(data[i].plannedKm),
                  width: _barWidth,
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(_barRadius),
                ),
                BarChartRodData(
                  toY: units.toDisplay(data[i].completedKm),
                  width: _barWidth,
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(_barRadius),
                ),
              ],
            ),
        ],
      ),
      duration: AppMotion.on(context) ? AppMotion.fill : Duration.zero,
      curve: AppMotion.standard,
    );
  }
}

class _LongRunChart extends StatelessWidget {
  const _LongRunChart({required this.data, required this.units});

  final List<LongRunPoint> data;
  final UnitSystem units;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = units.toDisplay(
            data.fold<double>(0, (m, p) => p.targetKm > m ? p.targetKm : m)) *
        1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 35 : maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (maxY / 4).clamp(5, 100).toDouble(),
                getTitlesWidget: (v, meta) =>
                    Text(v.toInt().toString(), style: theme.textTheme.labelSmall)),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                if (data.length > 8 && i.isOdd) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child:
                      Text('W${data[i].week}', style: theme.textTheme.labelSmall),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          // Target progression.
          LineChartBarData(
            spots: [
              for (var i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), units.toDisplay(data[i].targetKm)),
            ],
            isCurved: true,
            color: theme.colorScheme.outline,
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          ),
          // Actual achieved (only points that exist).
          LineChartBarData(
            spots: [
              for (var i = 0; i < data.length; i++)
                if (data[i].actualKm != null)
                  FlSpot(i.toDouble(), units.toDisplay(data[i].actualKm!)),
            ],
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
      duration: AppMotion.on(context) ? AppMotion.fill : Duration.zero,
      curve: AppMotion.standard,
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: Space.md,
                height: Space.md,
                decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(_barRadius))),
            const SizedBox(width: Space.sm),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        item(scheme.outlineVariant, 'Planned'),
        const SizedBox(width: Space.xl),
        item(scheme.primary, 'Completed'),
      ],
    );
  }
}
