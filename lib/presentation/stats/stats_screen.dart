import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../core/theme.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';
import '../widgets/readiness_dial.dart';
import 'stats_data.dart';

/// Progress & stats: readiness dial, weekly volume bars, long-run progression,
/// and completion streak (spec §8.5).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text('Progress', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  if (readiness != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: ReadinessDial(readiness: readiness)),
                      ),
                    ),
                  if (prediction != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.flag_circle_rounded,
                            color: AppTheme.ember, size: 32),
                        title: Text(formatFinishTime(prediction.predictedSec),
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        subtitle: Text(prediction.confident
                            ? 'Predicted finish · ${formatPace(prediction.paceSecPerKm)}'
                            : 'Early estimate — log a long run to sharpen it'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.local_fire_department_rounded,
                          value: '${stats.completionStreak}',
                          label: 'run streak',
                          color: AppTheme.ember,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.route_rounded,
                          value: stats.totalCompletedKm.toStringAsFixed(0),
                          label: 'total km',
                          color: const Color(0xFF3A7BD5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.terrain_rounded,
                          value: stats.longestRunKm.toStringAsFixed(0),
                          label: 'longest km',
                          color: const Color(0xFF2BB673),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader('Weekly volume'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                      child: SizedBox(
                          height: 200,
                          child: _WeeklyVolumeChart(data: stats.weeklyVolumes)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _LegendRow(),
                  const SizedBox(height: 16),
                  const SectionHeader('Long-run progression'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                      child: SizedBox(
                          height: 200,
                          child: _LongRunChart(data: stats.longRunProgression)),
                    ),
                  ),
                ],
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
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _WeeklyVolumeChart extends StatelessWidget {
  const _WeeklyVolumeChart({required this.data});

  final List<WeeklyVolume> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = data.fold<double>(
            0,
            (m, w) =>
                [m, w.plannedKm, w.completedKm].reduce((a, b) => a > b ? a : b)) *
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
                  padding: const EdgeInsets.only(top: 4),
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
                  toY: data[i].plannedKm,
                  width: 7,
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: data[i].completedKm,
                  width: 7,
                  color: AppTheme.ember,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LongRunChart extends StatelessWidget {
  const _LongRunChart({required this.data});

  final List<LongRunPoint> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = data.fold<double>(0, (m, p) => p.targetKm > m ? p.targetKm : m) *
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
                  padding: const EdgeInsets.only(top: 4),
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
                FlSpot(i.toDouble(), data[i].targetKm),
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
                  FlSpot(i.toDouble(), data[i].actualKm!),
            ],
            isCurved: true,
            color: AppTheme.ember,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        item(scheme.outlineVariant, 'Planned'),
        const SizedBox(width: 20),
        item(AppTheme.ember, 'Completed'),
      ],
    );
  }
}
