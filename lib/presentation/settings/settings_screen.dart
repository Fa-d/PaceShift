import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatting.dart';
import '../../core/motion.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/enums.dart';
import '../auth/sign_in_screen.dart';
import '../providers/auth_providers.dart';
import '../providers/providers.dart';
import 'widgets/settings_section.dart';

/// Settings hub: a lean top level with the account and the few common controls
/// inline, and heavier groups (Training, Data & backup, About) on focused
/// sub-pages. Styled as a flat grouped list (see [SettingsSection]).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final repo = ref.read(settingsRepositoryProvider);

    Future<void> pickTime(bool morning) async {
      final mins = morning
          ? settings.reminderMorningMinutes
          : settings.reminderEveningMinutes;
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: mins ~/ 60, minute: mins % 60),
      );
      if (picked != null) {
        final v = picked.hour * 60 + picked.minute;
        await repo.update(morning
            ? settings.copyWith(reminderMorningMinutes: v)
            : settings.copyWith(reminderEveningMinutes: v));
      }
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text('Settings', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 20),
            const _AccountSection(),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Preferences',
              children: [
                SettingsTile(
                  leading: Icons.straighten_rounded,
                  title: 'Units',
                  trailing: SegmentedButton<UnitSystem>(
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: UnitSystem.metric, label: Text('km')),
                      ButtonSegment(value: UnitSystem.imperial, label: Text('mi')),
                    ],
                    selected: {settings.units},
                    onSelectionChanged: (s) =>
                        repo.update(settings.copyWith(units: s.first)),
                  ),
                ),
                SettingsTile(
                  leading: Icons.wb_sunny_outlined,
                  title: 'Morning reminder',
                  trailing:
                      Text(formatMinutesOfDay(settings.reminderMorningMinutes)),
                  onTap: () => pickTime(true),
                ),
                SettingsTile(
                  leading: Icons.nightlight_outlined,
                  title: 'Evening check-in',
                  trailing:
                      Text(formatMinutesOfDay(settings.reminderEveningMinutes)),
                  onTap: () => pickTime(false),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'More',
              children: [
                SettingsTile(
                  leading: Icons.tune_rounded,
                  title: 'Training & adaptivity',
                  onTap: () => context.push('/settings/training'),
                ),
                SettingsTile(
                  leading: Icons.cloud_outlined,
                  title: 'Data & backup',
                  onTap: () => context.push('/settings/data'),
                ),
                SettingsTile(
                  leading: Icons.info_outline_rounded,
                  title: 'About & legal',
                  onTap: () => context.push('/settings/about'),
                ),
              ],
            ),
          ].revealStagger(context),
        ),
      ),
    );
  }
}

/// Sign-in status / sign-out / delete, as a flat grouped section.
class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return SettingsSection(
        title: 'Account',
        children: [
          SettingsTile(
            leading: Icons.login_rounded,
            title: 'Sign in',
            subtitle: 'Back up & sync across devices',
            onTap: () => showSignIn(context),
          ),
        ],
      );
    }

    return SettingsSection(
      title: 'Account',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  (user.displayName ?? user.email).characters.first.toUpperCase(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(user.displayName ?? user.email,
                        style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      user.proEntitled ? 'PaceShift Pro' : user.email,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
        SettingsTile(
          leading: Icons.delete_outline_rounded,
          title: 'Delete account',
          subtitle: 'Permanently removes your account & cloud data',
          titleColor: theme.colorScheme.error,
          onTap: () => _confirmDelete(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently deletes your account and cloud backup. Your local '
            'plan on this device is kept. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).deleteAccount();
    }
  }
}
