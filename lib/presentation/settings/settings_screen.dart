import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatting.dart';
import '../../data/api/cloud_sync_repository.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/enums.dart';
import '../auth/sign_in_screen.dart';
import '../providers/auth_providers.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';
import '../widgets/pro_gate.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final repo = ref.read(settingsRepositoryProvider);

    Future<void> pickTime(bool morning) async {
      final mins =
          morning ? settings.reminderMorningMinutes : settings.reminderEveningMinutes;
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
            const SizedBox(height: 12),
            const SectionHeader('Account'),
            const _AccountCard(),
            const SizedBox(height: 8),
            const SectionHeader('Watch & sync'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.watch_rounded),
                title: const Text('Health Connect'),
                subtitle: const Text('Sync runs from your watch'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/sync'),
              ),
            ),
            const SizedBox(height: 8),
            const SectionHeader('Reminders'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.wb_sunny_outlined),
                    title: const Text('Morning reminder'),
                    trailing:
                        Text(formatMinutesOfDay(settings.reminderMorningMinutes)),
                    onTap: () => pickTime(true),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.nightlight_outlined),
                    title: const Text('Evening check-in'),
                    trailing:
                        Text(formatMinutesOfDay(settings.reminderEveningMinutes)),
                    onTap: () => pickTime(false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const SectionHeader('Adaptivity'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How aggressively to redistribute missed runs',
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
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
            ),
            const SizedBox(height: 8),
            const SectionHeader('Units & catch-up'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.straighten_rounded),
                    title: const Text('Metric (km)'),
                    value: settings.units == UnitSystem.metric,
                    onChanged: (v) => repo.update(settings.copyWith(
                        units: v ? UnitSystem.metric : UnitSystem.imperial)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.event_repeat_rounded),
                    title: const Text('Catch-up window'),
                    subtitle:
                        Text('${settings.catchupWindowDays} days (long runs ${settings.longRunCatchupWindowDays})'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const SectionHeader('Cloud backup'),
            const _CloudBackupCard(),
            const SizedBox(height: 16),
            Text(
              'PaceShift is a training aid, not medical advice. Listen to your '
              'body and consult a healthcare professional before starting or '
              'changing a training program, or if you experience pain or injury.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sign-in status / sign-out.
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.login_rounded),
          title: const Text('Sign in'),
          subtitle: const Text('Back up & sync across devices'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showSignIn(context),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(
                (user.displayName ?? user.email).characters.first.toUpperCase(),
              ),
            ),
            title: Text(user.displayName ?? user.email),
            subtitle: Text(user.proEntitled ? 'PaceShift Pro' : user.email),
            trailing: TextButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).logout(),
              child: const Text('Sign out'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error),
            title: const Text('Delete account'),
            subtitle: const Text('Permanently removes your account & cloud data'),
            onTap: () => _confirmDelete(context, ref),
          ),
        ],
      ),
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

/// Cloud backup / restore actions (requires sign-in).
class _CloudBackupCard extends ConsumerStatefulWidget {
  const _CloudBackupCard();

  @override
  ConsumerState<_CloudBackupCard> createState() => _CloudBackupCardState();
}

class _CloudBackupCardState extends ConsumerState<_CloudBackupCard> {
  bool _busy = false;

  Future<void> _do(Future<CloudSyncResult> Function() action, String okMsg) async {
    if (!await ensurePro(context, ref)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    final msg = switch (result.status) {
      CloudSyncStatus.ok => okMsg,
      CloudSyncStatus.conflict =>
        'Server has newer data — pull first, then back up.',
      CloudSyncStatus.notSignedIn => 'Sign in to use cloud backup.',
      CloudSyncStatus.error => 'Sync failed. Try again.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(isSignedInProvider);
    final repo = ref.read(cloudSyncRepositoryProvider);
    if (!signedIn) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.cloud_off_outlined),
          title: Text('Not signed in'),
          subtitle: Text('Sign in above to enable cloud backup'),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Back up now'),
            subtitle: const Text('Upload your plan & history'),
            trailing: _busy ? const _MiniSpinner() : null,
            onTap: _busy
                ? null
                : () => _do(repo.push, 'Backed up to the cloud.'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Restore from cloud'),
            subtitle: const Text('Replace local data with your backup'),
            trailing: _busy ? const _MiniSpinner() : null,
            onTap: _busy ? null : () => _do(repo.pull, 'Restored from the cloud.'),
          ),
        ],
      ),
    );
  }
}

class _MiniSpinner extends StatelessWidget {
  const _MiniSpinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
}
