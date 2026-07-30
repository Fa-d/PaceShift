import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/formatting.dart';
import '../../domain/models/planned_run.dart';
import '../providers/providers.dart';
import 'common.dart';
import 'segment_bar.dart';

/// Compact tappable row summarising a planned run (used in the plan list).
class RunCard extends ConsumerWidget {
  const RunCard({super.key, required this.run, this.onTap, this.trailing});

  final PlannedRun run;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final units = ref.watch(unitsProvider);
    // The status chip's width tracks the text scale, and it sits outside the
    // flexible column. At 2× it grew wide enough to starve that column down to
    // 3.2px, so the title row overflowed. Past a moderate scale the chip drops
    // below the text instead of competing with it for the same line.
    final stacked = MediaQuery.textScalerOf(context).scale(1.0) > 1.3;
    final status = trailing ?? StatusChip(status: run.status);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              Hero(
                tag: 'run-badge-${run.id}',
                child: RunTypeBadge(type: run.type),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wrap, not Row: a horizontal Wrap constrains each child to
                    // the full line width, so the label and the distance move
                    // onto separate lines at a large text scale rather than
                    // ellipsising each other down to nothing.
                    Wrap(
                      spacing: Space.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(runTypeLabel(run.type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium),
                        if (run.type.isRun && run.targetDistanceKm != null)
                          Text(units.distance(run.targetDistanceKm),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: Space.xs),
                    Text(formatDateLabel(run.scheduledDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    if (run.wasShifted) ...[
                      const SizedBox(height: Space.xs),
                      ShiftBanner(
                          from: run.originalDate, to: run.scheduledDate),
                    ],
                    if (run.isStructured) ...[
                      const SizedBox(height: Space.sm),
                      SegmentBar(segments: run.segments!),
                    ],
                    if (stacked) ...[
                      const SizedBox(height: Space.sm),
                      status,
                    ],
                  ],
                ),
              ),
              if (!stacked) ...[
                const SizedBox(width: Space.sm),
                status,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
