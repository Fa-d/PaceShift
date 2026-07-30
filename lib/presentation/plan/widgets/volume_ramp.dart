import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/design.dart';
import '../../../core/formatting.dart';
import '../../../core/motion.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/progress/progress_stats.dart';

/// A compact bar chart of planned-vs-completed volume, one thin rod per week,
/// that lives in the plan hero.
///
/// Each week's [WeeklyVolume] is one rod: a neutral track up to its planned
/// distance with the completed distance drawn on top in the phase colour — the
/// same planned/completed colour language as the Progress screen's weekly-volume
/// chart. The current week's *track* carries the phase colour, so "you are here"
/// is legible on a fresh plan where nothing has been completed and every
/// completed rod is therefore zero-height. Tapping a rod (only on a real tap-up,
/// never a hover or drag) jumps to that week. No axes, grid or border — the ramp
/// is a shape, not a chart.
class VolumeRamp extends StatelessWidget {
  const VolumeRamp({
    super.key,
    required this.volumes,
    required this.color,
    required this.currentWeek,
    required this.units,
    this.onWeekTap,
  });

  final List<WeeklyVolume> volumes;
  final Color color;
  final int currentWeek;
  final UnitSystem units;
  final ValueChanged<int>? onWeekTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final plannedMaxDisplay = units.toDisplay(volumes.fold<double>(
        0, (m, v) => v.plannedKm > m ? v.plannedKm : m));
    final maxY = plannedMaxDisplay <= 0 ? 1.0 : plannedMaxDisplay * 1.15;

    return SizedBox(
      height: 64,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            touchCallback: (event, response) {
              // Hover and drag must not navigate — only a deliberate tap.
              if (event is! FlTapUpEvent) return;
              final i = response?.spot?.touchedBarGroupIndex;
              if (i != null && i >= 0 && i < volumes.length) {
                onWeekTap?.call(volumes[i].week);
              }
            },
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          barGroups: [
            for (var i = 0; i < volumes.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: units.toDisplay(volumes[i].completedKm),
                    width: 6,
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: units.toDisplay(volumes[i].plannedKm),
                      color: volumes[i].week == currentWeek
                          ? color.muted
                          : scheme.outlineVariant,
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: AppMotion.on(context) ? AppMotion.fill : Duration.zero,
        curve: AppMotion.standard,
      ),
    );
  }
}
