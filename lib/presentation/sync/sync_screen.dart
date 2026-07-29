import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/formatting.dart';
import '../../core/motion.dart';
import '../../data/repositories/sync_repository.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';

/// Health Connect sync status & manual "sync now" (spec §8.6).
class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    if (AppMotion.on(context)) HapticFeedback.lightImpact();
    setState(() => _syncing = true);
    final result = await syncAndSettle(
      sync: ref.read(syncRepositoryProvider),
      scheduler: ref.read(schedulerRepositoryProvider),
    );
    ref.invalidate(healthAvailableProvider);
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_messageFor(result))));
  }

  String _messageFor(SyncResult r) {
    switch (r.status) {
      case SyncStatus.success:
        if (r.newRuns == 0) return 'You’re up to date — no new runs.';
        return '${r.totalKm.toStringAsFixed(1)} km logged across '
            '${r.newRuns} run${r.newRuns == 1 ? '' : 's'}.';
      case SyncStatus.unavailable:
        return 'No health data source is available on this device.';
      case SyncStatus.permissionDenied:
        return 'Permission denied. Grant access to sync runs.';
      case SyncStatus.noPlan:
        return 'Create a plan first.';
      case SyncStatus.skipped:
        return 'You’re up to date.';
      case SyncStatus.error:
        return 'Something went wrong during sync.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = ref.watch(healthAvailableProvider);
    final lastSync = ref.watch(lastSyncProvider);
    final sync = ref.watch(syncRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Space.screenH, Space.sm, Space.screenH, Space.screenBottom),
        children: [
          QuietSurface(
            padding: const EdgeInsets.all(Space.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.watch_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: Space.md),
                    Text(sync.providerName, style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: Space.lg),
                available.when(
                  loading: () => const _StatusRow(
                      label: 'Checking availability…', ok: null),
                  error: (e, st) =>
                      const _StatusRow(label: 'Unavailable', ok: false),
                  data: (ok) => _StatusRow(
                    label: ok ? 'Connected & available' : 'Not available',
                    ok: ok,
                  ),
                ),
                const Divider(height: Space.xxl),
                Row(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: Space.md),
                    Text('Last sync', style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    Text(
                      lastSync == null
                          ? 'Never'
                          : '${formatDateLabel(lastSync)}, '
                              '${formatMinutesOfDay(lastSync.hour * 60 + lastSync.minute)}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          FilledButton.icon(
            onPressed: _syncing ? null : _syncNow,
            icon: _syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync_rounded),
            label: Text(_syncing ? 'Syncing…' : 'Sync now'),
          ),
          const SizedBox(height: Space.sm),
          // Nothing to install on iOS — HealthKit ships with the OS.
          if (available.value == false && sync.canInstallProvider)
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(syncRepositoryProvider).installHealthConnect(),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Install Health Connect'),
            ),
          const SizedBox(height: Space.xl),
          const SectionHeader('How it works'),
          _SetupGuide(canInstallProvider: sync.canInstallProvider),
        ].revealStagger(context),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.ok});

  final String label;
  final bool? ok;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color =
        ok == null ? scheme.outline : (ok! ? scheme.success : scheme.danger);
    return Row(
      children: [
        Icon(
          ok == null
              ? Icons.hourglass_empty_rounded
              : (ok! ? Icons.check_circle_rounded : Icons.cancel_rounded),
          color: color,
          size: 20,
        ),
        const SizedBox(width: Space.md),
        Text(label, style: theme.textTheme.titleSmall?.copyWith(color: color)),
      ],
    );
  }
}

class _SetupGuide extends StatelessWidget {
  const _SetupGuide({required this.canInstallProvider});

  /// Android needs the Health Connect app; iOS has HealthKit built in.
  final bool canInstallProvider;

  @override
  Widget build(BuildContext context) {
    final steps = canInstallProvider
        ? const [
            'Install Health Connect (or use the built-in version on Android 14+).',
            'Install your watch app (Samsung Health, Garmin Connect, …) and pair your watch.',
            'In that app, enable syncing to Health Connect.',
            'Grant PaceShift read access — new runs then appear on their own.',
          ]
        : const [
            'Record runs with Apple Watch, or any app that writes to Apple Health.',
            'Open the Health app → Sharing → Apps, and allow PaceShift to read workouts.',
            'New runs then appear on their own — no logging needed.',
          ];
    return QuietSurface(
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: Space.md,
                    child: Text('${i + 1}',
                        style: Theme.of(context).textTheme.labelSmall),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(child: Text(steps[i])),
                ],
              ),
            ),
        ].revealStagger(context),
      ),
    );
  }
}
