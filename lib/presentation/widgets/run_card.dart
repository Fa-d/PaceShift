import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../core/formatting.dart';
import '../../domain/models/planned_run.dart';
import 'common.dart';

/// Compact tappable row summarising a planned run (used in the plan list).
class RunCard extends StatelessWidget {
  const RunCard({super.key, required this.run, this.onTap, this.trailing});

  final PlannedRun run;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    Row(
                      children: [
                        Text(runTypeLabel(run.type),
                            style: theme.textTheme.titleMedium),
                        const SizedBox(width: Space.sm),
                        if (run.type.isRun && run.targetDistanceKm != null)
                          Text(formatKm(run.targetDistanceKm),
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
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              trailing ?? StatusChip(status: run.status),
            ],
          ),
        ),
      ),
    );
  }
}
