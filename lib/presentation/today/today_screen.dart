import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_utils.dart';
import '../../core/design.dart';
import '../../core/formatting.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../domain/models/completed_run.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/planned_run.dart';
import '../../domain/sync/workout_matcher.dart';
import '../genui/genui_surface_view.dart';
import '../providers/entitlement_providers.dart';
import '../providers/providers.dart';
import '../shift/shift_summary.dart';
import '../widgets/celebration.dart';
import '../widgets/common.dart';
import '../widgets/count_up_text.dart';
import '../widgets/manual_log_sheet.dart';
import '../widgets/pro_gate.dart';

/// Time-of-day greeting prefix used when a display name is set.
String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

/// The dashboard.
///
/// Structure matters more here than anywhere else in the app, so it is fixed
/// and deliberate:
///
/// 1. **Spine** — where you are in the plan. Always visible.
/// 2. **Hero** — today's run. Exactly one, always above the fold.
/// 3. **Attention queue** — *one* thing to answer, with the rest folded away.
/// 4. **Glances** — week progress and readiness.
/// 5. **Coach's briefing** — optional, below the fold.
///
/// The previous version was a flat `ListView` that could stack nine cards and
/// twelve competing buttons with no ordering, and put the connect-health nag
/// and unconfirmed-match cards *above* today's run — so the one thing the
/// screen exists for was pushed below the fold whenever anything else was
/// pending.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final todayRuns = ref.watch(todayRunsProvider);
    final t = ref.watch(todayProvider);
    final name = ref.watch(settingsProvider).value?.userName.trim() ?? '';
    final hasName = name.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          // An explicit pull is a request for fresh data, so it really syncs —
          // it used to only re-read what was already on disk.
          onRefresh: () async {
            await syncAndSettle(
              sync: ref.read(syncRepositoryProvider),
              scheduler: ref.read(schedulerRepositoryProvider),
            );
            ref
              ..invalidate(plannedRunsProvider)
              ..invalidate(completedRunsProvider)
              ..invalidate(unconfirmedRunsProvider);
          },
          child: ListView(
            padding: Space.screenPadding,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hasName ? '${_greeting()}, $name' : 'Today',
                            style: theme.textTheme.headlineMedium),
                        Text(formatDateLabel(t),
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  // The sync icon used to live here too, but pull-to-refresh
                  // already syncs and Settings → Data holds the full screen.
                  // Three doors to one room is not three features.
                  IconButton.filledTonal(
                    onPressed: () => _openCoach(context, ref),
                    icon: const Icon(Icons.psychology_rounded),
                    tooltip: 'Ask your coach',
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              const _PlanSpine(),
              const SizedBox(height: Space.lg),
              if (todayRuns.isEmpty)
                const _RestHero()
              else
                ...todayRuns.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: Space.md),
                      child: _TodayRunHero(run: r),
                    )),
              const SizedBox(height: Space.md),
              const _AttentionQueue(),
              const SizedBox(height: Space.lg),
              const _Glances(),
              const SizedBox(height: Space.lg),
              const _CoachBriefing(),
              const SizedBox(height: Space.md),
              OutlinedButton.icon(
                onPressed: () => ManualLogSheet.show(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Log an extra run'),
              ),
            ].revealStagger(context),
          ),
        ),
      ),
    );
  }

  Future<void> _openCoach(BuildContext context, WidgetRef ref) async {
    if (!await ensurePro(context, ref)) return;
    if (context.mounted) context.push('/coach');
  }
}

/// Where you are in the plan, and how long is left.
///
/// The fixed race date is the whole premise of the app — it was previously
/// nowhere on the dashboard, and the week number appeared as a bare "Week 12"
/// with no denominator. `planSummaryProvider` has built this exact sentence
/// all along, but only ever fed it to the AI prompt.
class _PlanSpine extends ConsumerWidget {
  const _PlanSpine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(activePlanProvider).value;
    if (plan == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = ref.watch(todayProvider);
    final week = (daysBetween(plan.startDate, t) ~/ 7) + 1;
    final daysLeft = daysBetween(t, plan.raceDate);

    return Row(
      children: [
        Icon(Icons.flag_rounded, size: 16, color: scheme.primary),
        const SizedBox(width: Space.sm),
        Text('Week $week of ${plan.totalWeeks}',
            style: theme.textTheme.labelMedium),
        Text('  ·  ', style: theme.textTheme.labelMedium
            ?.copyWith(color: scheme.outlineVariant)),
        Text(
          daysLeft <= 0
              ? 'Race day'
              : '$daysLeft day${daysLeft == 1 ? '' : 's'} to race day',
          style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary),
        ),
      ],
    );
  }
}

// ---- The hero -----------------------------------------------------------

class _RestHero extends ConsumerWidget {
  const _RestHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // "Rest day" is a claim about the plan, so it must not be shown before the
    // plan has actually loaded. Reading `.value ?? const []` meant a cold start
    // — or a database error — cheerfully told the athlete to take the day off.
    final runs = ref.watch(plannedRunsProvider);
    if (runs.isLoading) {
      return const QuietSurface(
        padding: EdgeInsets.all(Space.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (runs.hasError) {
      return SurfaceError(
        message: 'We couldn’t load today’s run.',
        compact: true,
        onRetry: () => ref.invalidate(plannedRunsProvider),
      );
    }

    return HeroSurface(
      tint: theme.colorScheme.secondary,
      child: Row(
        children: [
          const RunTypeBadge(type: RunType.rest, size: 52),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rest day', style: theme.textTheme.titleLarge),
                const SizedBox(height: Space.xs),
                Text('Recovery is training too. Enjoy the day off.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayRunHero extends ConsumerWidget {
  const _TodayRunHero({required this.run});

  final PlannedRun run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final units = ref.watch(unitsProvider);
    final color = RunPalette.of(run.type, scheme);
    final done = run.status == RunStatus.completed;

    return HeroSurface(
      tint: color,
      // Run detail was reachable from the Plan tab but not from the screen the
      // athlete actually looks at.
      onTap: () => context.push('/run/${run.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'run-badge-${run.id}',
                child: RunTypeBadge(type: run.type, size: 52),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(runTypeLabel(run.type),
                    style: theme.textTheme.titleLarge),
              ),
              if (done) StatusChip(status: run.status),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              if (run.targetDistanceKm != null)
                _bigMetric(theme, units.distance(run.targetDistanceKm),
                    'target'),
              if (run.runWalkRatio != null) ...[
                const SizedBox(width: Space.xxl),
                _bigMetric(theme, run.runWalkRatio!, 'run / walk'),
              ],
              if (run.targetDurationMin != null) ...[
                const SizedBox(width: Space.xxl),
                _bigMetric(theme, '${run.targetDurationMin}m', 'approx'),
              ],
            ],
          ),
          if (run.notes != null) ...[
            const SizedBox(height: Space.md),
            Text(run.notes!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
          if (!done) ...[
            const SizedBox(height: Space.xl),
            // Finishing the run you were told to do should be one tap. It used
            // to open a form demanding a distance *and* a time before it would
            // accept "yes, I did it".
            FilledButton.icon(
              onPressed: () => _markAsPlanned(context, ref),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Did it as planned'),
            ),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        ManualLogSheet.show(context, plannedRun: run),
                    child: const Text('Log details'),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _couldntRun(context, ref),
                    child: const Text('Couldn’t run'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _markAsPlanned(BuildContext context, WidgetRef ref) async {
    await ref.read(runRepositoryProvider).logAsPlanned(run.id);
    if (!context.mounted) return;
    Celebrate.burst(context);
  }

  Future<void> _couldntRun(BuildContext context, WidgetRef ref) async {
    // Deliberately **not** Pro-gated. This is the core adaptive loop, it is
    // already free from the notification action and from every background
    // rollover, and gating it meant declining the paywall silently discarded
    // the athlete's report at the worst possible moment.
    final units = ref.read(unitsProvider);
    final outcome = await ref
        .read(schedulerRepositoryProvider)
        .reportCouldNotRun(run.id, today: ref.read(todayProvider));
    if (outcome == null || !context.mounted) return;

    if (outcome.needsDecision) {
      await resolveDegradeDecision(context, ref, options: outcome.decisions);
      return;
    }
    // One sheet, not a dialog that opens another dialog.
    await PlanAdjustedSheet.show(context, outcome, units);
  }

  Widget _bigMetric(ThemeData theme, String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.displaySmall),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      );
}

// ---- The attention queue -------------------------------------------------

/// One question at a time.
///
/// Everything that wants a decision from the athlete funnels through here,
/// ranked. Previously each source rendered its own unbounded stack of cards
/// directly into the dashboard, so a week away could produce five near-identical
/// "is this your long run?" cards above the fold with no ordering between them
/// and the health-connect nag.
class _AttentionQueue extends ConsumerStatefulWidget {
  const _AttentionQueue();

  @override
  ConsumerState<_AttentionQueue> createState() => _AttentionQueueState();
}

class _AttentionQueueState extends ConsumerState<_AttentionQueue> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    // 1. An unanswered engine decision outranks everything: the plan is
    //    currently unsafe and only the athlete can say how to fix it.
    if (ref.watch(pendingDegradeProvider)) {
      items.add(const _DecisionItem());
    }

    // 2. Workouts the matcher wasn't confident enough to attach on its own.
    final pending = ref.watch(unconfirmedRunsProvider).value ?? const [];
    final planned = ref.watch(plannedRunsProvider).value ?? const [];
    for (final run in pending) {
      final target =
          planned.where((p) => p.id == run.suggestedPlannedRunId).firstOrNull;
      // Drop suggestions whose target is gone or has since been satisfied some
      // other way — asking about an already-completed run is just noise.
      if (target != null && isClaimableByWorkout(target)) {
        items.add(_ConfirmMatchItem(run: run, planned: target));
      }
    }

    // 3. The standing offer of automatic capture, for anyone still typing runs
    //    in by hand.
    if (_shouldOfferConnect()) items.add(const _ConnectItem());

    if (items.isEmpty) return const SizedBox.shrink();

    final hidden = items.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in _expanded ? items : items.take(1))
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: item,
          ),
        if (hidden > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded),
              label: Text(_expanded
                  ? 'Show less'
                  : '$hidden more need${hidden == 1 ? 's' : ''} your attention'),
            ),
          ),
      ],
    );
  }

  bool _shouldOfferConnect() {
    final settings = ref.watch(settingsProvider).value;
    if (settings == null) return false;
    if (ref.watch(healthAvailableProvider).value != true) return false;
    // Never asked → the connect screen is about to handle it; already syncing
    // → nothing to offer.
    return settings.healthPromptedAt != null && settings.lastSyncAt == null;
  }
}

/// An outstanding §4.6 degrade decision.
class _DecisionItem extends ConsumerWidget {
  const _DecisionItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return QuietSurface(
      accent: scheme.warning,
      onTap: () => resolveDegradeDecision(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: scheme.warning, size: 20),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text('Your plan needs a decision',
                    style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            'There isn’t a safe way to fit everything into the time left. '
            'Choose how you’d like to adapt.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Space.md),
          FilledButton.tonal(
            onPressed: () => resolveDegradeDecision(context, ref),
            child: const Text('Choose how to adapt'),
          ),
        ],
      ),
    );
  }
}

/// A synced workout the matcher couldn't attach with confidence.
class _ConfirmMatchItem extends ConsumerWidget {
  const _ConfirmMatchItem({required this.run, required this.planned});

  final CompletedRun run;
  final PlannedRun planned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final units = ref.watch(unitsProvider);
    final repo = ref.read(runRepositoryProvider);

    Future<void> answer(Future<void> Function() action, String toast) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await action();
        messenger.showSnackBar(SnackBar(content: Text(toast)));
      } catch (_) {
        messenger.showSnackBar(
            const SnackBar(content: Text('That didn’t save. Try again.')));
      }
    }

    return QuietSurface(
      accent: scheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                    'Is this your ${runTypeLabel(planned.type).toLowerCase()}?',
                    style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            'You ran ${units.distance(run.actualDistanceKm)} on '
            '${formatDateLabel(run.date)}. '
            '${runTypeLabel(planned.type)} on '
            '${formatDateLabel(planned.scheduledDate)} is still open.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Space.md),
          // Themed buttons stretch to infinite width, so each needs a flex
          // parent — never drop one straight into a Row.
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => answer(
                      () => repo.confirmSuggestedMatch(run), 'Matched up.'),
                  child: const Text('Yes, that’s it'),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => answer(
                      () => repo.rejectSuggestedMatch(run.id),
                      'Kept as an extra run.'),
                  child: const Text('No, extra run'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The standing offer of automatic capture.
class _ConnectItem extends ConsumerWidget {
  const _ConnectItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return QuietSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.watch_rounded, color: scheme.onSurfaceVariant,
                  size: 20),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text('Logging runs by hand?',
                    style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Connect ${ref.watch(syncRepositoryProvider).providerName} once '
            'and PaceShift picks up your runs on its own.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Space.md),
          FilledButton.tonal(
            onPressed: () => context.push('/sync'),
            child: const Text('Set up automatic logging'),
          ),
        ],
      ),
    );
  }
}

// ---- Glances -------------------------------------------------------------

class _Glances extends ConsumerWidget {
  const _Glances();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(activePlanProvider).value;
    if (plan == null) return const SizedBox.shrink();
    final t = ref.watch(todayProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: _WeekGlance(today: t)),
        const SizedBox(width: Space.md),
        const Expanded(flex: 2, child: _ReadinessGlance()),
      ],
    );
  }
}

/// Compact readiness glance (mini dial + label).
class _ReadinessGlance extends ConsumerWidget {
  const _ReadinessGlance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final readiness = ref.watch(readinessProvider);
    final score = readiness?.score ?? 0;
    final color = readiness == null
        ? scheme.outline
        : readinessColor(readiness.band, scheme);

    return QuietSurface(
      // A bare 0–100 with no explanation of what it measures or how to move it
      // is a number, not information.
      onTap: () => _explain(context, readiness?.label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Readiness', style: theme.textTheme.titleSmall),
              const SizedBox(width: Space.xs),
              Icon(Icons.info_outline_rounded,
                  size: 14, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration:
                      AppMotion.on(context) ? AppMotion.fill : Duration.zero,
                  curve: AppMotion.standard,
                  builder: (context, t, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: (score / 100) * t,
                        strokeWidth: 5,
                        backgroundColor: scheme.surfaceContainerHighest,
                        color: color,
                      ),
                      Text('${(score * t).round()}',
                          style: theme.textTheme.labelMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(readiness?.label ?? '—',
                    style: theme.textTheme.labelMedium?.copyWith(color: color)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _explain(BuildContext context, String? label) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              Space.screenH, Space.xs, Space.screenH, Space.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('About readiness', style: theme.textTheme.titleLarge),
              const SizedBox(height: Space.md),
              Text(
                'Readiness compares what your plan asked for against what you '
                'actually ran — how much of the recent load you completed, and '
                'how your long runs are progressing.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: Space.md),
              Text(
                'It moves up when you complete runs close to their targets, '
                'and especially when you finish your long runs. Missing a '
                'single easy run barely touches it.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (label != null) ...[
                const SizedBox(height: Space.md),
                Text('Right now: $label', style: theme.textTheme.titleSmall),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A compact strip showing this week's completed vs planned volume.
class _WeekGlance extends ConsumerWidget {
  const _WeekGlance({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final units = ref.watch(unitsProvider);
    final runs = ref.watch(plannedRunsProvider).value ?? const <PlannedRun>[];
    final completed =
        ref.watch(completedRunsProvider).value ?? const <CompletedRun>[];

    // The training week containing today (Mon–Sun).
    final weekStart = previousOrSameWeekday(today, DateTime.monday);
    final weekEnd = addDays(weekStart, 7);
    final weekRuns = runs.where((r) =>
        !r.scheduledDate.isBefore(weekStart) &&
        r.scheduledDate.isBefore(weekEnd) &&
        r.type.isRun);
    final plannedKm =
        weekRuns.fold<double>(0, (s, r) => s + (r.targetDistanceKm ?? 0));
    final doneKm = completed
        .where((c) => !c.date.isBefore(weekStart) && c.date.isBefore(weekEnd))
        .fold<double>(0, (s, c) => s + c.actualDistanceKm);
    final pct = plannedKm <= 0 ? 0.0 : (doneKm / plannedKm).clamp(0.0, 1.0);

    return QuietSurface(
      onTap: () => context.go('/plan'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('This week', style: theme.textTheme.titleSmall),
              const Spacer(),
              CountUpText(
                value: units.toDisplay(doneKm),
                // The unit label came from a hardcoded ' km' here, so this
                // number stayed metric no matter what the athlete chose.
                format: (n) => '${n.round()} / '
                    '${units.distanceValue(plannedKm)} ${units.distanceLabel}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: pct),
              duration: AppMotion.on(context) ? AppMotion.fill : Duration.zero,
              curve: AppMotion.standard,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: Space.sm,
                backgroundColor: scheme.surfaceContainerHighest,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A lazy, Pro-gated AI-composed dashboard section.
///
/// It does NOT call the model on screen load — it composes a briefing only when
/// the athlete asks for one. Sits below the fold on purpose: it is an optional
/// extra, and it used to sit third from the top competing with today's run.
class _CoachBriefing extends ConsumerStatefulWidget {
  const _CoachBriefing();

  @override
  ConsumerState<_CoachBriefing> createState() => _CoachBriefingState();
}

class _CoachBriefingState extends ConsumerState<_CoachBriefing> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (ref.watch(activePlanProvider).value == null) {
      return const SizedBox.shrink();
    }
    return QuietSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: Space.sm),
              Text('Coach’s briefing', style: theme.textTheme.titleMedium),
              const Spacer(),
              // Say it's Pro *before* the tap, not with a paywall afterwards.
              if (!ref.watch(proStatusProvider)) const ProBadge(),
            ],
          ),
          if (!_show)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: Space.sm),
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    if (!await ensurePro(context, ref)) return;
                    setState(() => _show = true);
                  },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Generate'),
                ),
              ),
            )
          else
            const GenUiSurfaceView(composeOnStart: true, showInput: false),
        ],
      ),
    );
  }
}
