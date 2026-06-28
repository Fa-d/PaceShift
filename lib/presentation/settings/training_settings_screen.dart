import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          SettingsSection(
            title: 'Adaptivity',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How aggressively to redistribute missed runs.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
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
          const SizedBox(height: 24),
          SettingsSection(
            title: 'Catch-up windows',
            children: [
              SettingsTile(
                leading: Icons.event_repeat_rounded,
                title: 'Make-up window',
                subtitle: 'How long a missed run can still be made up',
                trailing: Text('${settings.catchupWindowDays} days'),
              ),
              SettingsTile(
                leading: Icons.directions_run_rounded,
                title: 'Long-run window',
                subtitle: 'Extra room for missed long runs',
                trailing: Text('${settings.longRunCatchupWindowDays} days'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
