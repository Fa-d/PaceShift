import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';

/// One-time "connect your health data" step, shown straight after the plan is
/// generated (spec: automatic capture).
///
/// Deliberately *after* onboarding rather than inside it: asking for a sensitive
/// permission before the user has seen their plan converts badly. By this point
/// they have something concrete to attach the value to.
///
/// Every exit path stamps `healthPromptedAt`, so this screen is asked once and
/// never nags again — if it's declined, a card on Today carries the offer.
class ConnectHealthScreen extends ConsumerStatefulWidget {
  const ConnectHealthScreen({super.key});

  @override
  ConsumerState<ConnectHealthScreen> createState() =>
      _ConnectHealthScreenState();
}

class _ConnectHealthScreenState extends ConsumerState<ConnectHealthScreen> {
  bool _busy = false;

  /// Stamping `healthPromptedAt` is what releases the router's connect gate and
  /// moves us to Today — navigating by hand instead would race the settings
  /// stream and bounce the user straight back here.
  Future<void> _dismiss() =>
      ref.read(settingsRepositoryProvider).markHealthPrompted();

  Future<void> _connect() async {
    setState(() => _busy = true);
    // Grab the messenger up front: the gate releases the moment we stamp, and
    // this screen's context is gone by then.
    final messenger = ScaffoldMessenger.of(context);
    try {
      // No explicit permission request needed — a manual sync raises the
      // platform prompt itself, on both Health Connect and HealthKit.
      final result = await syncAndSettle(
        sync: ref.read(syncRepositoryProvider),
        scheduler: ref.read(schedulerRepositoryProvider),
      );
      if (result.isSuccess && result.newRuns > 0) {
        messenger.showSnackBar(SnackBar(
          content: Text('Imported ${result.newRuns} '
              'run${result.newRuns == 1 ? '' : 's'} — '
              '${result.totalKm.toStringAsFixed(1)} km.'),
        ));
      }
    } catch (_) {
      // Fall through: we still record that we asked, so this is never a dead end.
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
              Text('Your plan is ready',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall),
              const SizedBox(height: Space.sm),
              Text(
                'Now let it keep itself up to date.',
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
