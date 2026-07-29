import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/formatting.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';

/// The full pitch for automatic run capture.
///
/// This used to be a forced redirect the instant a plan existed — the first
/// thing a new athlete saw after eight onboarding questions was a screen
/// headed "Your plan is ready" that showed them none of their plan and asked
/// for a sensitive health permission instead. It is now reached on purpose,
/// from the Today attention queue, by someone who has seen what the app does
/// and wants it to keep itself up to date.
///
/// Every exit path stamps `healthPromptedAt`, which quiets the offer for a
/// fortnight.
class ConnectHealthScreen extends ConsumerStatefulWidget {
  const ConnectHealthScreen({super.key});

  @override
  ConsumerState<ConnectHealthScreen> createState() =>
      _ConnectHealthScreenState();
}

class _ConnectHealthScreenState extends ConsumerState<ConnectHealthScreen> {
  bool _busy = false;

  /// Records that we asked (which quiets the offer on Today) and closes.
  Future<void> _dismiss() async {
    await ref.read(settingsRepositoryProvider).markHealthPrompted();
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    // Grab the messenger up front: this screen closes before we report back.
    final messenger = ScaffoldMessenger.of(context);
    final units = ref.read(unitsProvider);
    try {
      // No explicit permission request needed — a manual sync raises the
      // platform prompt itself, on both Health Connect and HealthKit.
      final result = await syncAndSettle(
        sync: ref.read(syncRepositoryProvider),
        scheduler: ref.read(schedulerRepositoryProvider),
        onAdjustment: ref.read(recentAdjustmentProvider.notifier).record,
      );
      // Always say something. Success with zero new runs used to produce no
      // feedback at all — the screen simply vanished, which is
      // indistinguishable from the connection having failed.
      messenger.showSnackBar(SnackBar(
        content: Text(!result.isSuccess
            ? 'We couldn’t read your health data. You can try again from '
                'Settings → Data.'
            : result.newRuns == 0
                ? 'Connected. Nothing new to import yet — future runs will '
                    'arrive on their own.'
                : 'Connected — imported ${result.newRuns} '
                    'run${result.newRuns == 1 ? '' : 's'}, '
                    '${units.distance(result.totalKm)}.'),
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('We couldn’t connect just now. You can try again from '
            'Settings → Data.'),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
      await _dismiss();
    }
  }

  Future<void> _install() async {
    await ref.read(syncRepositoryProvider).installHealthConnect();
    ref.invalidate(healthAvailableProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sync = ref.watch(syncRepositoryProvider);
    final available = ref.watch(healthAvailableProvider).value;
    final needsInstall = available == false && sync.canInstallProvider;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Space.xl, Space.xl, Space.xl, Space.xl),
          child: Column(
            children: <Widget>[
              const Spacer(flex: 2),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: scheme.secondary,
                  borderRadius: AppRadius.lgAll,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.watch_rounded,
                    size: 52, color: scheme.onSecondary),
              ),
              const SizedBox(height: Space.xl),
              Text('Let your runs log themselves',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall),
              const SizedBox(height: Space.sm),
              Text(
                'Connect once and your plan keeps itself up to date.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: Space.xl),
              const FeatureRow(
                icon: Icons.bolt_rounded,
                title: 'Runs arrive on their own',
                description: 'Your watch already records them. Connect once '
                    'and they land here.',
              ),
              const FeatureRow(
                icon: Icons.autorenew_rounded,
                title: 'Your plan adapts to reality',
                description: 'PaceShift sees what you actually did, without '
                    'you telling it anything.',
              ),
              const FeatureRow(
                icon: Icons.lock_rounded,
                title: 'Read-only, stays on your phone',
                description: 'You can revoke access at any time.',
              ),
              const Spacer(flex: 3),
              if (needsInstall) ...[
                FilledButton.icon(
                  onPressed: _busy ? null : _install,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Install Health Connect'),
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'Health Connect isn’t set up on this device yet.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ] else
                FilledButton(
                  onPressed: _busy ? null : _connect,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Connect to ${sync.providerName}'),
                ),
              const SizedBox(height: Space.sm),
              TextButton(
                onPressed: _busy ? null : _dismiss,
                child: const Text('Not now — I’ll log runs myself'),
              ),
            ]
                .animate(interval: 70.ms)
                .fadeIn(duration: 360.ms, curve: Curves.easeOut)
                .slideY(begin: 0.14, end: 0, curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }
}
