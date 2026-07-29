import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';

import '../../core/formatting.dart';
import '../../core/motion.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/enums.dart';
import '../../data/billing/subscription_service.dart';
import '../auth/sign_in_screen.dart';
import '../providers/auth_providers.dart';
import '../providers/entitlement_providers.dart';
import '../providers/providers.dart';
import '../providers/subscription_providers.dart';
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
          padding: Space.screenPadding,
          children: [
            Text('Settings', style: theme.textTheme.headlineMedium),
            const SizedBox(height: Space.xl),
            const _AccountSection(),
            const SizedBox(height: Space.xl),
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
            const SizedBox(height: Space.xl),
            const _ProSection(),
            const SizedBox(height: Space.xl),
            SettingsSection(
              title: 'More',
              children: [
                SettingsTile(
                  leading: Icons.event_note_rounded,
                  title: 'Your plan',
                  subtitle: 'Race date, distance, weekly shape',
                  onTap: () => context.push('/settings/plan'),
                ),
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

/// Subscription status, and the way in and out of it.
///
/// Pro used to be reachable only by walking into a wall: `showPaywall` was
/// called exclusively from `ensurePro`, and "Restore purchases" lived *inside*
/// the paywall — so someone who had already bought on another device had to
/// trigger a paywall before they could tell the app they'd paid.
class _ProSection extends ConsumerWidget {
  const _ProSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(proStatusProvider);
    return SettingsSection(
      title: 'Subscription',
      children: [
        SettingsTile(
          leading: isPro ? Icons.verified_rounded : Icons.bolt_rounded,
          title: isPro ? 'PaceShift Pro' : 'Upgrade to Pro',
          subtitle: isPro
              ? 'AI coaching and cloud backup are active'
              : 'AI coaching and cloud backup',
          onTap: isPro ? null : () => showPaywall(context),
          trailing: isPro ? const Icon(Icons.check_rounded) : null,
        ),
        SettingsTile(
          leading: Icons.restore_rounded,
          title: 'Restore purchases',
          onTap: () => _restore(context, ref),
        ),
      ],
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final result =
        await ref.read(subscriptionServiceProvider).restore();
    messenger.showSnackBar(SnackBar(content: Text(switch (result) {
      PurchaseResult.success => 'Pro restored — welcome back.',
      PurchaseResult.cancelled => 'Nothing to restore.',
      PurchaseResult.notConfigured =>
        'The store isn’t available right now. Try again shortly.',
      PurchaseResult.error => 'We couldn’t restore that. Try again shortly.',
    })));
    if (result == PurchaseResult.success) {
      ref.read(proStatusProvider.notifier).grantLocally();
    }
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
          padding: const EdgeInsets.symmetric(
              horizontal: Space.lg, vertical: Space.md),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  (user.displayName ?? user.email).characters.first.toUpperCase(),
                ),
              ),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(user.displayName ?? user.email,
                        style: theme.textTheme.bodyLarge),
                    const SizedBox(height: Space.xs),
                    Text(
                      user.proEntitled ? 'PaceShift Pro' : user.email,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _confirmSignOut(context, ref),
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
    if (ok != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // Deleting an account is slow and can fail. It used to run with no
    // progress, no result and no error handling — a failed server-side
    // deletion signed you out and looked exactly like success.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final deleted =
        await ref.read(authControllerProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss the progress dialog
    messenger.showSnackBar(SnackBar(
      content: Text(deleted
          ? 'Your account has been deleted.'
          : 'We couldn’t delete your account. Nothing has changed — '
              'try again shortly.'),
    ));
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'Your plan and history stay on this device. You’ll need to sign '
            'in again to back up or sync.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
      ref.read(proStatusProvider.notifier).reset();
    }
  }
}
