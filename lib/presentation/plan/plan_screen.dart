import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/design.dart';
import '../../core/errors.dart';
import '../../core/motion.dart';
import '../../domain/models/planned_run.dart';
import '../../domain/models/training_plan.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';
import 'plan_filter.dart';
import 'widgets/month_heatmap.dart';
import 'widgets/plan_filter_bar.dart';
import 'widgets/plan_hero.dart';
import 'widgets/week_block.dart';

/// Plan screen redesign: race countdown, volume ramp, phase, week-by-week
/// completion and an intensity-heatmap month view. See
/// `~/.claude/plans/the-plan-pages-ui-modular-raven.md`.
enum _PlanView { week, month }

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

/// Context shown in the pinned bar once the hero has scrolled away.
typedef _HeaderInfo = ({int week, int totalWeeks, int daysLeft});

class _PlanScreenState extends ConsumerState<PlanScreen> {
  _PlanView _view = _PlanView.week;
  PlanFilter _filter = const PlanFilter();

  final ScrollController _controller = ScrollController();
  // 0 at the top, 1 once the hero has scrolled away — drives the pinned bar's
  // crossfading title and the Today FAB. A ValueNotifier so neither needs a
  // per-frame rebuild of the whole screen.
  final ValueNotifier<double> _collapse = ValueNotifier(0);
  final Map<int, GlobalKey> _weekKeys = {};
  bool _jumped = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    _collapse.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    // The hero is the first scrolling sliver; this only has to be close.
    const heroExtent = 320;
    _collapse.value =
        (_controller.offset / heroExtent).clamp(0.0, 1.0);
  }

  /// Land a week at the top of the scroll. Animated for the FAB / ramp tap;
  /// instant otherwise.
  void _revealTop(int week, {required bool animate}) {
    final ctx = _weekKeys[week]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.0,
      duration:
          animate && AppMotion.on(context) ? AppMotion.medium : Duration.zero,
      curve: AppMotion.standard,
    );
  }

  /// On open only: bring the current week into view with the *minimal* scroll.
  /// A current week that already sits on screen — e.g. week 1 of a fresh plan,
  /// just below the hero — is left in place so the hero stays visible, instead
  /// of being dragged to the top. `Scrollable.ensureVisible` always forces an
  /// alignment, so this reaches for `RenderAbstractViewport` directly to check
  /// whether the week is already fully within the viewport.
  void _revealCurrentMinimally(int week) {
    if (!_controller.hasClients) return;
    final ctx = _weekKeys[week]?.currentContext;
    final ro = ctx?.findRenderObject();
    if (ctx == null || ro == null) return;
    final viewport = RenderAbstractViewport.of(ro);
    final position = _controller.position;
    final top = viewport.getOffsetToReveal(ro, 0.0).offset;
    final bottom = viewport.getOffsetToReveal(ro, 1.0).offset;
    // Already fully within the viewport — leave it where it is.
    if (position.pixels <= top &&
        bottom <= position.pixels + position.viewportDimension) {
      return;
    }
    final target = (position.pixels < top ? top : bottom)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    _controller.jumpTo(target);
  }

  /// Ramp tap: switch to the week view (if needed) then jump to the week.
  void _goToWeek(int week) {
    if (_view != _PlanView.week) {
      setState(() => _view = _PlanView.week);
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _revealTop(week, animate: true));
    } else {
      _revealTop(week, animate: true);
    }
  }

  Map<int, List<PlannedRun>> _groupByWeek(List<PlannedRun> runs) {
    final byWeek = <int, List<PlannedRun>>{};
    for (final r in runs) {
      byWeek.putIfAbsent(r.weekIndex, () => []).add(r);
    }
    for (final w in byWeek.values) {
      w.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    }
    return byWeek;
  }

  @override
  Widget build(BuildContext context) {
    final runsAsync = ref.watch(plannedRunsProvider);

    return Scaffold(
      body: SafeArea(
        child: runsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // Never `'$e'` — that rendered a DriftWrappedException, SQL and all,
          // in the middle of the screen.
          error: (e, _) => SurfaceError(
            message: friendlyError(e,
                fallback: 'We couldn’t open your plan just now.'),
            onRetry: () => ref.invalidate(plannedRunsProvider),
          ),
          data: (runs) {
            if (runs.isEmpty) {
              return const EmptyState(
                icon: Icons.event_note_rounded,
                title: 'No plan yet',
                message: 'Generate a plan to see your schedule here.',
              );
            }
            final plan = ref.watch(activePlanProvider).value;
            if (plan == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final today = ref.watch(todayProvider);
            final currentWeek = planWeekClamped(plan.startDate, today);
            final planInfo = (
              week: currentWeek,
              totalWeeks: plan.totalWeeks,
              daysLeft: daysBetween(today, plan.raceDate),
            );

            // Open anchored on the current week, once.
            if (!_jumped && _view == _PlanView.week) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_weekKeys[currentWeek]?.currentContext != null) {
                  _jumped = true;
                  _revealCurrentMinimally(currentWeek);
                }
              });
            }

            final scaler = MediaQuery.textScalerOf(context);
            final headerExtent = scaler.scale(60).clamp(56.0, 144.0);

            return Stack(
              children: [
                CustomScrollView(
                  controller: _controller,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PlanHeaderDelegate(
                        extent: headerExtent,
                        collapse: _collapse,
                        view: _view,
                        onViewChanged: (v) {
                          if (AppMotion.on(context)) {
                            HapticFeedback.selectionClick();
                          }
                          setState(() => _view = v);
                        },
                        info: planInfo,
                      ),
                    ),
                    if (_view == _PlanView.week) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              Space.screenH, Space.sm, Space.screenH, 0),
                          child: PlanHero(onJumpToWeek: _goToWeek),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: Space.md),
                          child: PlanFilterBar(
                            filter: _filter,
                            onChanged: (f) => setState(() => _filter = f),
                            showRunsOnly:
                                runs.any((r) => !r.type.isRun),
                          ),
                        ),
                      ),
                    ],
                    SliverToBoxAdapter(
                      child: PageTransitionSwitcher(
                        duration: AppMotion.medium,
                        transitionBuilder: (child, primary, secondary) =>
                            SharedAxisTransition(
                          animation: primary,
                          secondaryAnimation: secondary,
                          transitionType: SharedAxisTransitionType.horizontal,
                          fillColor: Colors.transparent,
                          child: child,
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(_view),
                          child: _view == _PlanView.week
                              ? _weekList(runs, plan, today, currentWeek)
                              : MonthHeatmap(runs: runs, plan: plan),
                        ),
                      ),
                    ),
                    const SliverPadding(
                        padding: EdgeInsets.only(bottom: Space.screenBottom)),
                  ],
                ),
                // Today FAB: week view only, once the hero has scrolled away.
                if (_view == _PlanView.week)
                  Positioned(
                    right: Space.lg,
                    bottom: Space.lg,
                    child: ValueListenableBuilder<double>(
                      valueListenable: _collapse,
                      builder: (context, c, child) =>
                          c > 0.85 ? child! : const SizedBox.shrink(),
                      child: FloatingActionButton.extended(
                        onPressed: () =>
                            _revealTop(currentWeek, animate: true),
                        icon: const Icon(Icons.my_location_rounded),
                        label: const Text('Today'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _weekList(List<PlannedRun> runs, TrainingPlan plan, DateTime today,
      int currentWeek) {
    final byWeek = _groupByWeek(runs);
    final visibleByWeek = _groupByWeek(_filter.apply(runs, today));
    final visibleWeeks = visibleByWeek.keys.toList()..sort();

    if (visibleWeeks.isEmpty) {
      return SizedBox(
        height: 440,
        child: EmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'No runs match',
          message: 'Try widening your filters to see more of the plan.',
          action: FilledButton.tonal(
            onPressed: () => setState(() => _filter = const PlanFilter()),
            child: const Text('Clear filters'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Space.screenH, Space.sm, Space.screenH, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final week in visibleWeeks)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.lg),
              child: WeekBlock(
                key: _weekKeys.putIfAbsent(week, () => GlobalKey()),
                week: week,
                plan: plan,
                allWeekRuns: byWeek[week]!,
                visibleRuns: visibleByWeek[week]!,
                isCurrent: week == currentWeek,
              ),
            ),
        ],
      ),
    );
  }
}

/// The pinned, slim top bar. The title crossfades `Plan` →
/// `Week N of M · Dd` as the hero scrolls away.
class _PlanHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PlanHeaderDelegate({
    required this.extent,
    required this.collapse,
    required this.view,
    required this.onViewChanged,
    required this.info,
  });

  final double extent;
  final ValueNotifier<double> collapse;
  final _PlanView view;
  final ValueChanged<_PlanView> onViewChanged;
  final _HeaderInfo info;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  String get _collapsedTitle {
    final d = info.daysLeft;
    if (d < 0) return 'Race complete';
    if (d == 0) return 'Week ${info.week} of ${info.totalWeeks} · race day';
    return 'Week ${info.week} of ${info.totalWeeks} · ${d}d';
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: Space.screenH),
      alignment: Alignment.center,
      child: Row(
        children: [
          Flexible(
            child: ValueListenableBuilder<double>(
              valueListenable: collapse,
              builder: (context, c, _) {
                final collapsed = c > 0.5;
                return AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: collapsed
                      ? Text(_collapsedTitle,
                          key: const ValueKey('collapsed'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium)
                      : Text('Plan',
                          key: const ValueKey('expanded'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineMedium),
                );
              },
            ),
          ),
          const SizedBox(width: Space.sm),
          SegmentedButton<_PlanView>(
            segments: const [
              ButtonSegment(
                  value: _PlanView.week, icon: Icon(Icons.view_week_rounded)),
              ButtonSegment(
                  value: _PlanView.month,
                  icon: Icon(Icons.calendar_month_rounded)),
            ],
            selected: {view},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onViewChanged(s.first),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_PlanHeaderDelegate oldDelegate) =>
      extent != oldDelegate.extent ||
      view != oldDelegate.view ||
      info != oldDelegate.info;
}
