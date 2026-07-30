import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_utils.dart';
import '../../core/design.dart';
import '../../core/errors.dart';
import '../../core/formatting.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/planned_run.dart';
import '../../domain/plan_generator/plan_input.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';
import 'widgets/settings_section.dart';

/// Change the plan after onboarding — or start over.
///
/// Everything here was previously write-once. `createPlanFromInput` had a
/// single call site (the last step of the onboarding wizard) and the router
/// sent `/onboarding` straight to `/today` the moment a plan existed, so race
/// date, distance, days per week, long-run day, goal time and even the
/// athlete's name were fixed in the first sixty seconds of using the app and
/// could never be changed again. A cancelled race, an injury, or simply
/// picking the wrong day had no recourse short of reinstalling.
class EditPlanScreen extends ConsumerStatefulWidget {
  const EditPlanScreen({super.key});

  @override
  ConsumerState<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends ConsumerState<EditPlanScreen> {
  final _name = TextEditingController();
  DateTime? _raceDate;
  double? _raceDistanceKm;
  int? _daysPerWeek;
  int? _longRunDay;
  bool? _hasGoal;
  int _goalHours = 4;
  int _goalMinutes = 0;

  bool _loaded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Seeds the form from the live plan the first time it resolves.
  void _seed(List<PlannedRun> runs) {
    if (_loaded) return;
    final plan = ref.read(activePlanProvider).value;
    if (plan == null) return;
    _loaded = true;
    _raceDate = plan.raceDate;
    _raceDistanceKm = plan.raceDistanceKm;
    _longRunDay = plan.longRunDay;
    _name.text = ref.read(settingsProvider).value?.userName ?? '';
    // Days per week isn't stored on the plan, so read it back off the runs the
    // generator produced — the busiest ordinary week is the honest answer.
    _daysPerWeek = _inferDaysPerWeek(runs);
    // A goal time shows up as pace targets on the generated runs.
    _hasGoal = runs.any((r) => r.targetPaceSecPerKm != null);
  }

  static int _inferDaysPerWeek(List<PlannedRun> runs) {
    final byWeek = <int, int>{};
    for (final r in runs.where((r) => r.type.isRun)) {
      byWeek[r.weekIndex] = (byWeek[r.weekIndex] ?? 0) + 1;
    }
    if (byWeek.isEmpty) return 3;
    final busiest = byWeek.values.reduce((a, b) => a > b ? a : b);
    return busiest.clamp(3, 5);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final runsAsync = ref.watch(plannedRunsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your plan')),
      body: runsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => SurfaceError(
          message: friendlyError(e, fallback: 'We couldn’t load your plan.'),
          onRetry: () => ref.invalidate(plannedRunsProvider),
        ),
        data: (runs) {
          _seed(runs);
          if (!_loaded) {
            return const EmptyState(
                icon: Icons.event_note_rounded, title: 'No plan yet');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                Space.screenH, Space.md, Space.screenH, Space.screenBottom),
            children: [
              SettingsSection(
                title: 'You',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xl),
              SettingsSection(
                title: 'Race',
                children: [
                  SettingsTile(
                    leading: Icons.event_rounded,
                    title: 'Race day',
                    trailing: Text(
                        '${formatDateLabel(_raceDate!)}, ${_raceDate!.year}'),
                    onTap: _pickDate,
                  ),
                  SettingsTile(
                    leading: Icons.terrain_rounded,
                    title: 'Distance',
                    trailing: SegmentedButton<double>(
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 21.1, label: Text('Half')),
                        ButtonSegment(value: 42.2, label: Text('Full')),
                      ],
                      selected: {_raceDistanceKm!},
                      onSelectionChanged: (s) =>
                          setState(() => _raceDistanceKm = s.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xl),
              SettingsSection(
                title: 'Your week',
                children: [
                  SettingsTile(
                    leading: Icons.calendar_view_week_rounded,
                    title: 'Runs per week',
                    trailing: SegmentedButton<int>(
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 3, label: Text('3')),
                        ButtonSegment(value: 4, label: Text('4')),
                        ButtonSegment(value: 5, label: Text('5')),
                      ],
                      selected: {_daysPerWeek!},
                      onSelectionChanged: (s) =>
                          setState(() => _daysPerWeek = s.first),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Space.lg, Space.md, Space.lg, Space.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Long-run day', style: theme.textTheme.bodyLarge),
                        const SizedBox(height: Space.sm),
                        Wrap(
                          spacing: Space.sm,
                          runSpacing: Space.sm,
                          children: [
                            for (var d = 1; d <= 7; d++)
                              ChoiceChip(
                                label: Text(weekdayName(d)),
                                selected: _longRunDay == d,
                                onSelected: (_) =>
                                    setState(() => _longRunDay = d),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xl),
              SettingsSection(
                title: 'Goal time',
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: Space.lg, vertical: Space.xs),
                    title: const Text('Train to a finish time'),
                    subtitle: const Text('Adds pace targets and quality '
                        'sessions'),
                    value: _hasGoal!,
                    onChanged: (v) => setState(() => _hasGoal = v),
                  ),
                  if (_hasGoal!)
                    SettingsTile(
                      leading: Icons.timer_outlined,
                      title: 'Target',
                      trailing: Text('${_goalHours}h '
                          '${_goalMinutes.toString().padLeft(2, '0')}m'),
                      onTap: _pickGoal,
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: Space.lg),
                SurfaceError(message: _error!, compact: true),
              ],
              const SizedBox(height: Space.xl),
              FilledButton.icon(
                onPressed: _saving ? null : _confirmAndSave,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_rounded),
                label: const Text('Rebuild my plan'),
              ),
              const SizedBox(height: Space.sm),
              Text(
                'Changing any of these rebuilds your remaining weeks. Runs '
                'you’ve already completed are kept.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: Space.xxl),
              SettingsSection(
                children: [
                  SettingsTile(
                    leading: Icons.restart_alt_rounded,
                    title: 'Start over',
                    subtitle: 'Delete this plan and answer the questions again',
                    titleColor: theme.colorScheme.danger,
                    onTap: _confirmDelete,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _raceDate!.isAfter(now.add(const Duration(days: 28)))
          ? _raceDate!
          : now.add(const Duration(days: 28)),
      firstDate: now.add(const Duration(days: 28)),
      lastDate: now.add(const Duration(days: 730)),
      helpText: 'Select your race date',
    );
    if (picked != null) setState(() => _raceDate = picked);
  }

  Future<void> _pickGoal() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _goalHours, minute: _goalMinutes),
      helpText: 'Target finish time (h:mm)',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _goalHours = picked.hour;
        _goalMinutes = picked.minute;
      });
    }
  }

  /// Rebuilding rewrites every future week, so it asks first — and says
  /// exactly how much history survives.
  Future<void> _confirmAndSave() async {
    final repo = ref.read(planRepositoryProvider);
    final kept = await repo.completedRunCount();
    if (!mounted) return;

    final weeks = ((_raceDate!.difference(today()).inDays) / 7).ceil();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rebuild your plan?'),
        content: Text(
          'This rebuilds your remaining $weeks week${weeks == 1 ? '' : 's'} '
          'around the new details. '
          '${kept == 0 ? 'You have no logged runs yet.' : 'Your $kept logged '
              'run${kept == 1 ? '' : 's'} will be kept.'}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Rebuild')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final current = await settingsRepo.getSettings();
      await settingsRepo.update(current.copyWith(userName: _name.text.trim()));

      // The generator needs a starting fitness figure; the athlete's longest
      // completed run is a better answer than anything we could ask them to
      // retype, and falls back to the plan's own opening long run.
      final longest = await _startingFitnessKm();
      await repo.regeneratePlan(PlanInput(
        raceDate: _raceDate!,
        raceDistanceKm: _raceDistanceKm!,
        currentLongestRunKm: longest,
        daysPerWeek: _daysPerWeek!,
        preferredLongRunDay: _longRunDay!,
        goalFinishSec:
            _hasGoal! ? (_goalHours * 3600 + _goalMinutes * 60) : null,
      ));
      if (!mounted) return;
      messenger.showSnackBar(
          const SnackBar(content: Text('Plan rebuilt around your changes.')));
      // `context.pop()`, not `Navigator.pop` — this is a go_router page, and
      // the plan change also bumps the router's refreshListenable.
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            friendlyError(e, fallback: 'We couldn’t rebuild your plan.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<double> _startingFitnessKm() async {
    final completed = ref.read(completedRunsProvider).value ?? const [];
    final longestDone =
        completed.fold<double>(0, (m, c) => c.actualDistanceKm > m
            ? c.actualDistanceKm
            : m);
    if (longestDone > 0) return longestDone;
    final runs = ref.read(plannedRunsProvider).value ?? const <PlannedRun>[];
    final firstLong = runs
        .where((r) => r.type == RunType.long)
        .fold<double>(0, (m, r) => m == 0 ? (r.targetDistanceKm ?? 0) : m);
    return firstLong > 0 ? firstLong : 10;
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start over?'),
        content: const Text(
            'This deletes your current plan and takes you back to the setup '
            'questions. Runs you’ve already logged are kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete plan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(planRepositoryProvider).deleteActivePlan();
    // The router's redirect sees there is no active plan and returns the
    // athlete to onboarding on its own.
  }
}
