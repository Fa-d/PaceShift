import 'package:flutter/material.dart';

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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              RunTypeBadge(type: run.type),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(runTypeLabel(run.type),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        if (run.type.isRun && run.targetDistanceKm != null)
                          Text(formatKm(run.targetDistanceKm),
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(formatDateLabel(run.scheduledDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    if (run.wasShifted) ...[
                      const SizedBox(height: 4),
                      ShiftBanner(
                          from: run.originalDate, to: run.scheduledDate),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? StatusChip(status: run.status),
            ],
          ),
        ),
      ),
    );
  }
}
