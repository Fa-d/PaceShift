import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
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
    setState(() => _syncing = true);
    final result = await ref.read(syncRepositoryProvider).syncNow();
    ref.invalidate(lastSyncProvider);
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
        return 'Health Connect isn’t available on this device.';
      case SyncStatus.permissionDenied:
        return 'Permission denied. Grant access to sync runs.';
      case SyncStatus.noPlan:
        return 'Create a plan first.';
      case SyncStatus.error:
        return 'Something went wrong during sync.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = ref.watch(healthAvailableProvider);
    final lastSync = ref.watch(lastSyncProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.watch_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text('Health Connect', style: theme.textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                  const Divider(height: 28),
                  Row(
                    children: [
                      Icon(Icons.history_rounded,
                          size: 20, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text('Last sync',
                          style: theme.textTheme.bodyMedium),
                      const Spacer(),
                      lastSync.when(
                        loading: () => const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (e, st) => const Text('—'),
                        data: (when) => Text(
                          when == null
                              ? 'Never'
                              : '${formatDateLabel(when)}, ${formatMinutesOfDay(when.hour * 60 + when.minute)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 8),
          if (available.value == false)
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(syncRepositoryProvider).installHealthConnect(),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Install Health Connect'),
            ),
          const SizedBox(height: 24),
          const SectionHeader('How it works'),
          const _SetupGuide(),
        ],
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
    final scheme = Theme.of(context).colorScheme;
    final color = ok == null
        ? scheme.outline
        : (ok! ? const Color(0xFF2BB673) : scheme.error);
    return Row(
      children: [
        Icon(
          ok == null
              ? Icons.hourglass_empty_rounded
              : (ok! ? Icons.check_circle_rounded : Icons.cancel_rounded),
          color: color,
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SetupGuide extends StatelessWidget {
  const _SetupGuide();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Install Health Connect (or use the built-in version on Android 14+).',
      'Install Samsung Health and pair your watch.',
      'In Samsung Health, enable syncing to Health Connect.',
      'Grant PaceShift read access — then tap “Sync now”.',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text('${i + 1}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(steps[i])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
