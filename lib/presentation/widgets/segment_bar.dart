import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/formatting.dart';
import '../../core/theme.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/workout_segment.dart';
import '../providers/providers.dart';

/// A pill-shaped bar that renders a structured workout's segments as
/// proportionally-sized coloured slices, plus a one-line summary of the hard set.
///
/// The plan screen's RunCards use it to make an interval session readable at a
/// glance instead of looking identical to a steady jog. Proportion is by
/// distance, falling back to duration, then to equal shares — `Expanded` throws
/// on a zero flex and freezed leaves both segment sizes nullable, so a block
/// with no recorded size still gets a visible sliver rather than an assertion.
class SegmentBar extends ConsumerWidget {
  const SegmentBar({
    super.key,
    required this.segments,
    this.height = Space.sm,
  });

  final List<WorkoutSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final units = ref.watch(unitsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: AppRadius.pillAll,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (final seg in segments)
                  Expanded(
                    flex: _flexFor(seg),
                    child: ColoredBox(
                      color: SegmentPalette.of(seg.kind, scheme),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Text(
          _hardSummary(segments, units),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// Whole-number flex for a segment, scaled by distance then duration. Never
  /// below 1 — a zero-weight `Expanded` throws — and equal-share when neither
  /// size is recorded.
  int _flexFor(WorkoutSegment s) {
    final km = s.totalKm;
    if (km > 0) {
      // Scale kilometres up so a sub-kilometre rep (e.g. 800 m) isn't rounded
      // away to a flex of 1 next to a 6 km block.
      final scaled = (km * 10).round();
      return scaled < 1 ? 1 : scaled;
    }
    final dur = s.durationSec;
    if (dur != null && dur > 0) {
      final scaled = (dur / 60).round(); // minutes
      return scaled < 1 ? 1 : scaled;
    }
    return 1;
  }

  /// Summarises the quality work, e.g. `6 × 800 m`. Falls back to the first
  /// segment when there is no hard block.
  String _hardSummary(List<WorkoutSegment> segments, UnitSystem units) {
    final hard = segments.firstWhere(
      (s) => s.kind == SegmentKind.hard,
      orElse: () => segments.first,
    );
    final amount = hard.distanceKm != null
        ? units.distance(hard.distanceKm)
        : (hard.durationSec != null ? formatDuration(hard.durationSec!) : '');
    if (amount.isEmpty) return '';
    return hard.reps > 1 ? '${hard.reps} × $amount' : amount;
  }
}
