import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/models/enums.dart';
import '../providers/providers.dart';
import 'widgets/settings_section.dart';

/// How aggressively the engine redistributes missed runs, plus the make-up
/// windows. Split out of the Settings hub to keep the top level minimal.
class TrainingSettingsScreen extends ConsumerWidget {
  const TrainingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final repo = ref.read(settingsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Training')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Space.screenH, Space.md, Space.screenH, Space.screenBottom),
        children: [
          SettingsSection(
            title: 'Adaptivity',
            children: [
              Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // "Aggressiveness" is the enum's name, not a word to
                      // put in front of a runner.
                      'How much PaceShift will move around to make up a '
                      'missed run.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: Space.md),
                    SegmentedButton<Aggressiveness>(
                      segments: const [
                        ButtonSegment(
                            value: Aggressiveness.conservative,
                            label: Text('Easy')),
                        ButtonSegment(
                            value: Aggressiveness.balanced,
                            label: Text('Balanced')),
                        ButtonSegment(
                            value: Aggressiveness.aggressive,
                            label: Text('Bold')),
                      ],
                      selected: {settings.adaptivityAggressiveness},
                      onSelectionChanged: (s) => repo.update(
                          settings.copyWith(adaptivityAggressiveness: s.first)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          // These two are informational, and they now *look* informational.
          //
          // They used to be `SettingsTile`s with no `onTap`, sitting in the
          // same rounded group as the tappable rows and near-identical to
          // them — the only difference was a missing chevron. A row that
          // looks like a control and does nothing when you press it reads as
          // a broken app, not a read-only value. ("Catch-up window" was also
          // the engine's own vocabulary leaking onto the screen.)
          SettingsSection(
            title: 'How long a missed run stays catchable',
            children: [
              _ReadOnlyRow(
                icon: Icons.event_repeat_rounded,
                title: 'Most runs',
                value: '${settings.catchupWindowDays} days',
              ),
              _ReadOnlyRow(
                icon: Icons.directions_run_rounded,
                title: 'Long runs',
                value: '${settings.longRunCatchupWindowDays} days',
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Text(
              'After this, a missed run is let go rather than crammed into a '
              'week that can’t safely hold it.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// A value the athlete can read but not set — visibly not a control.
class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.lg, vertical: Space.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.outline),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Text(title,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
