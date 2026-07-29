import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../widgets/common.dart';
import 'widgets/settings_section.dart';

/// App identity + the medical disclaimer (moved off the Settings hub).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Display version. Kept in sync with `pubspec.yaml` (`version:`); shown
  /// statically to avoid pulling in a platform plugin just for this.
  static const _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Space.screenH, Space.xl, Space.screenH, Space.screenBottom),
        children: [
          Column(
            children: [
              const IconChip(icon: Icons.directions_run_rounded, size: 64),
              const SizedBox(height: Space.md),
              Text('PaceShift', style: theme.textTheme.titleLarge),
              const SizedBox(height: Space.xs),
              Text(
                'Version $_version',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          SettingsSection(
            title: 'Legal',
            children: [
              Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Text(
                  'PaceShift is a training aid, not medical advice. Listen to your '
                  'body and consult a healthcare professional before starting or '
                  'changing a training program, or if you experience pain or injury.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
