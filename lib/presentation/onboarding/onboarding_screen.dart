import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design.dart';
import '../../core/errors.dart';
import '../../core/formatting.dart';
import '../../domain/models/enums.dart';
import '../../domain/plan_generator/plan_input.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';

/// First-run experience: a welcoming intro followed by a guided, one-question-
/// per-step wizard that collects race details and generates the plan (spec §8.1).
///
/// All inputs map to [PlanInput]; the chosen units and display name are also
/// persisted to settings. The engine/generator contract is unchanged.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Step 0 is the welcome intro; 1..5 are the questions.
  //
  // This was eight steps, several of which asked a single pre-answered
  // question. Race distance and race date belong together (both are "the
  // race"), as do current fitness and weekly shape (both are "your running").
  static const int _lastStep = 5;
  int _step = 0;

  // --- Collected inputs ---
  final _nameController = TextEditingController();
  UnitSystem _units = UnitSystem.metric;
  double _raceDistanceKm = 42.2;
  DateTime _raceDate = DateTime.now().add(const Duration(days: 133)); // ~19 weeks
  final _longestRun = TextEditingController(text: '18');
  /// Canonical kilometre value behind [_longestRun], so unit toggling is
  /// lossless no matter how many times it happens.
  double? _longestKm = 18;
  String? _longestError;
  int _daysPerWeek = 3;
  int _longRunDay = DateTime.saturday;
  bool _hasGoalTime = false;
  int _goalHours = 4;
  int _goalMinutes = 0;

  bool _creating = false;
  String? _generateError;

  @override
  void dispose() {
    _nameController.dispose();
    _longestRun.dispose();
    super.dispose();
  }

  String get _unitLabel => _units == UnitSystem.metric ? 'km' : 'mi';
  int get _weeksToRace =>
      (_raceDate.difference(DateTime.now()).inDays / 7).round();

  double _toKm(double v) => _units == UnitSystem.metric ? v : v * 1.60934;

  String _trimNum(double d) {
    final r = (d * 10).round() / 10;
    return r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1);
  }

  // ---- Navigation ----

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  void _next() {
    if (!_validateStep(_step)) return;
    if (_step == _lastStep) {
      _generate();
      return;
    }
    setState(() => _step++);
  }

  bool _validateStep(int step) {
    if (step == 3) {
      final d = double.tryParse(_longestRun.text.trim());
      if (d == null || d <= 0) {
        setState(() => _longestError = 'Enter your longest recent run');
        return false;
      }
      setState(() => _longestError = null);
    }
    return true;
  }

  Future<void> _pickRaceDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _raceDate,
      firstDate: now.add(const Duration(days: 28)),
      lastDate: now.add(const Duration(days: 730)),
      helpText: 'Select your race date',
    );
    if (picked != null) setState(() => _raceDate = picked);
  }

  /// Toggling units re-renders the same underlying distance.
  ///
  /// This used to round-trip the *text* through kilometres and back on every
  /// toggle, trimming to one decimal each way — so flipping km → mi → km
  /// quietly changed the number the athlete had typed.
  void _setUnits(UnitSystem u) {
    if (u == _units) return;
    final typed = double.tryParse(_longestRun.text.trim());
    if (typed != null && typed > 0) _longestKm = _toKm(typed);
    setState(() {
      _units = u;
      final km = _longestKm;
      if (km != null) {
        _longestRun.text =
            _trimNum(u == UnitSystem.metric ? km : km / 1.60934);
      }
    });
  }

  Future<void> _generate() async {
    setState(() {
      _creating = true;
      _generateError = null;
    });
    final input = PlanInput(
      raceDate: _raceDate,
      raceDistanceKm: _raceDistanceKm,
      currentLongestRunKm: _toKm(double.parse(_longestRun.text.trim())),
      daysPerWeek: _daysPerWeek,
      preferredLongRunDay: _longRunDay,
      goalFinishSec:
          _hasGoalTime ? (_goalHours * 3600 + _goalMinutes * 60) : null,
    );
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final current = await settingsRepo.getSettings();
      await settingsRepo.update(current.copyWith(
        units: _units,
        userName: _nameController.text.trim(),
      ));
      await ref.read(planRepositoryProvider).createPlanFromInput(input);
      // Router redirect picks up the active plan and moves to Today.
    } catch (e) {
      // Without this the wizard dead-ended on the review step: the spinner
      // stopped, no plan appeared, and nothing explained why.
      if (mounted) {
        setState(() => _generateError = friendlyError(e,
            fallback: 'We couldn’t build your plan. Please try again.'));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_step > 0) _topBar(theme),
            // Keyed by step so the subtree is rebuilt fresh on each change,
            // which re-triggers the per-step flutter_animate entrance. (An
            // AnimatedSwitcher's centering Stack is deliberately avoided here:
            // wrapping a scrollable step body in it feeds unbounded width back
            // up into the sibling bottom bar.)
            Expanded(
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: _buildStep(theme, _step),
              ),
            ),
            if (_step > 0) _bottomBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _topBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _creating ? null : _back,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _step / _lastStep),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          Text(
            '$_step of $_lastStep',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(ThemeData theme) {
    final isLast = _step == _lastStep;
    final Widget continueChild;
    if (isLast && _creating) {
      continueChild = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (isLast) {
      continueChild = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 20),
          SizedBox(width: Space.sm),
          Text('Generate my plan'),
        ],
      );
    } else {
      continueChild = const Text('Continue');
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      // Both buttons are flex children: the app theme's button minimumSize is
      // Size.fromHeight(52) (minWidth == infinity for full-width CTAs), so a
      // non-flex button measured at unbounded width by a Row would throw.
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: _creating ? null : _back,
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            flex: 5,
            child: FilledButton(
              onPressed: _creating ? null : _next,
              child: continueChild,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(ThemeData theme, int step) {
    switch (step) {
      case 0:
        return _welcomeStep(theme);
      case 1:
        return _nameStep(theme);
      case 2:
        return _raceStep(theme);
      case 3:
        return _runningStep(theme);
      case 4:
        return _goalStep(theme);
      default:
        return _reviewStep(theme);
    }
  }

  /// Scrollable body shared by the question steps: a header plus controls,
  /// each entrance-animated with a gentle staggered fade + rise.
  Widget _stepScaffold({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Space.sm),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Space.xl),
          ...children,
        ]
            .animate(interval: 55.ms)
            .fadeIn(duration: 300.ms, curve: Curves.easeOut)
            .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }

  // ---- Steps ----

  Widget _welcomeStep(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        children: <Widget>[
          const Spacer(flex: 2),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.secondary,
              borderRadius: BorderRadius.circular(26),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/brand/paceshift_mark.svg',
              width: 60,
              height: 60,
            ),
          ),
          const SizedBox(height: Space.xl),
          Text('PaceShift', style: theme.textTheme.displaySmall),
          const SizedBox(height: Space.sm),
          Text(
            'Plans that bend, not break.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Space.xl),
          const FeatureRow(
            icon: Icons.flag_rounded,
            title: 'Your race date never moves',
            description: 'It is the anchor everything else bends around.',
          ),
          const FeatureRow(
            icon: Icons.autorenew_rounded,
            title: 'Miss a run and nothing breaks',
            description: 'The work is spread safely across your week, '
                'never crammed back in.',
          ),
          const FeatureRow(
            icon: Icons.shield_moon_rounded,
            title: 'Built-in safety guardrails',
            description: 'Science-based progression that won’t let you '
                'over-reach.',
          ),
          const Spacer(flex: 3),
          FilledButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('Get started'),
          ),
          const SizedBox(height: Space.sm),
          Text(
            'Takes about a minute',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ]
            .animate(interval: 70.ms)
            .fadeIn(duration: 360.ms, curve: Curves.easeOut)
            .slideY(begin: 0.14, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _nameStep(ThemeData theme) {
    return _stepScaffold(
      title: 'First, what should we call you?',
      subtitle: 'We’ll use it to personalize your coaching. Optional — skip if '
          'you’d rather not.',
      children: [
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofocus: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.person_rounded),
            hintText: 'Your name',
          ),
          onSubmitted: (_) => _next(),
        ),
        const SizedBox(height: Space.sm),
        // The copy said "skip if you'd rather not" and then offered no way to
        // skip — the only button was "Continue".
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              _nameController.clear();
              _next();
            },
            child: const Text('Skip this'),
          ),
        ),
      ],
    );
  }

  /// "The race": distance and date. Both answer the same question — *what*
  /// are you training for — and both were pre-answered, so asking them on
  /// separate full screens was two taps of ceremony for no decision.
  Widget _raceStep(ThemeData theme) {
    final scheme = theme.colorScheme;
    return _stepScaffold(
      title: 'What are you training for?',
      subtitle: 'Your race date becomes the anchor everything counts back '
          'from — taper included.',
      children: [
        _OptionCard(
          icon: Icons.terrain_rounded,
          title: 'Marathon',
          subtitle: '42.2 km · 26.2 mi',
          selected: _raceDistanceKm == 42.2,
          onTap: () => setState(() => _raceDistanceKm = 42.2),
        ),
        const SizedBox(height: Space.md),
        _OptionCard(
          icon: Icons.directions_run_rounded,
          title: 'Half marathon',
          subtitle: '21.1 km · 13.1 mi',
          selected: _raceDistanceKm == 21.1,
          onTap: () => setState(() => _raceDistanceKm = 21.1),
        ),
        const SizedBox(height: Space.xl),
        _GroupLabel('Race day', theme),
        const SizedBox(height: Space.sm),
        InkWell(
          onTap: _pickRaceDate,
          borderRadius: AppRadius.mdAll,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.lg, vertical: Space.xl),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              children: [
                Icon(Icons.event_rounded, color: scheme.primary),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    '${formatDateLabel(_raceDate)}, ${_raceDate.year}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Icon(Icons.edit_calendar_rounded,
                    color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        Text(
          '≈ $_weeksToRace weeks to build up.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// "Your running": where you are now and what a normal week looks like.
  Widget _runningStep(ThemeData theme) {
    return _stepScaffold(
      title: 'Tell us about your running',
      subtitle: 'A rough answer is fine — you can change all of this later.',
      children: [
        _GroupLabel('Longest recent run', theme),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _longestRun,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.straighten_rounded),
                  suffixText: _unitLabel,
                  errorText: _longestError,
                  hintText: _units == UnitSystem.metric ? 'e.g. 18' : 'e.g. 11',
                ),
                onChanged: (v) {
                  final parsed = double.tryParse(v.trim());
                  if (parsed != null && parsed > 0) _longestKm = _toKm(parsed);
                  if (_longestError != null) {
                    setState(() => _longestError = null);
                  }
                },
              ),
            ),
            const SizedBox(width: Space.md),
            SegmentedButton<UnitSystem>(
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: UnitSystem.metric, label: Text('km')),
                ButtonSegment(value: UnitSystem.imperial, label: Text('mi')),
              ],
              selected: {_units},
              onSelectionChanged: (s) => _setUnits(s.first),
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        _GroupLabel('Runs per week', theme),
        const SizedBox(height: Space.sm),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 3, label: Text('3')),
            ButtonSegment(value: 4, label: Text('4')),
            ButtonSegment(value: 5, label: Text('5')),
          ],
          selected: {_daysPerWeek},
          onSelectionChanged: (s) => setState(() => _daysPerWeek = s.first),
        ),
        const SizedBox(height: Space.xl),
        _GroupLabel('Long-run day', theme),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (var d = 1; d <= 7; d++)
              ChoiceChip(
                label: Text(weekdayName(d)),
                selected: _longRunDay == d,
                onSelected: (_) => setState(() => _longRunDay = d),
              ),
          ],
        ),
      ],
    );
  }

  Widget _goalStep(ThemeData theme) {
    return _stepScaffold(
      title: 'Do you have a goal finish time?',
      subtitle: 'Set one and your runs get pace targets and quality sessions. '
          'Leave it off to train by feel.',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I have a goal finish time'),
          subtitle: const Text('Adds pace targets & quality sessions'),
          value: _hasGoalTime,
          onChanged: (v) => setState(() => _hasGoalTime = v),
        ),
        const SizedBox(height: Space.md),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _hasGoalTime
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Row(
            children: [
              Expanded(
                child: _GoalStepper(
                  label: 'Hours',
                  value: _goalHours,
                  min: 2,
                  max: 7,
                  onChanged: (v) => setState(() => _goalHours = v),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: _GoalStepper(
                  label: 'Minutes',
                  value: _goalMinutes,
                  min: 0,
                  max: 59,
                  step: 5,
                  onChanged: (v) => setState(() => _goalMinutes = v),
                ),
              ),
            ],
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _reviewStep(ThemeData theme) {
    final scheme = theme.colorScheme;
    final name = _nameController.text.trim();
    final goalLabel = _hasGoalTime
        ? '${_goalHours}h ${_goalMinutes.toString().padLeft(2, '0')}m'
        : 'By feel';
    return _stepScaffold(
      title: name.isEmpty ? 'Ready to build your plan' : 'All set, $name',
      subtitle: 'Quick check — tap Back to change anything.',
      children: [
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Column(
            children: [
              _SummaryRow(
                icon: Icons.emoji_events_rounded,
                label: 'Race',
                value: _raceDistanceKm == 42.2 ? 'Marathon' : 'Half marathon',
              ),
              _SummaryRow(
                icon: Icons.event_rounded,
                label: 'Race day',
                value: '${formatDateLabel(_raceDate)}, ${_raceDate.year}'
                    '  ·  ≈$_weeksToRace wks',
              ),
              _SummaryRow(
                icon: Icons.straighten_rounded,
                label: 'Longest run',
                value: '${_longestRun.text.trim()} $_unitLabel',
              ),
              _SummaryRow(
                icon: Icons.calendar_view_week_rounded,
                label: 'Schedule',
                value: '$_daysPerWeek runs/wk · long on '
                    '${weekdayName(_longRunDay)}',
              ),
              _SummaryRow(
                icon: Icons.speed_rounded,
                label: 'Goal time',
                value: goalLabel,
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        Text(
          'Your race date is the anchor. Miss a run and PaceShift safely '
          'spreads the work — it never crams unsafe weeks.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (_generateError != null) ...[
          const SizedBox(height: Space.lg),
          SurfaceError(message: _generateError!, compact: true),
        ],
      ],
    );
  }
}

/// A large, tappable selection card used for the race-distance choice.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.10)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              // Was hardcoded to `directions_run`, so the `icon` parameter was
              // accepted and silently ignored — every option card showed the
              // same glyph regardless of what it represented.
              child: Icon(icon, color: scheme.primary, size: 26),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: Space.xs),
                  Text(subtitle,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small bold label that introduces a control group.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text, this.theme);

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style:
            theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      );
}

/// A single line in the review summary: icon, label, value.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: Space.md),
          Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small −/＋ stepper for the goal-time hours/minutes.
class _GoalStepper extends StatelessWidget {
  const _GoalStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: value > min ? () => onChanged(value - step) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Column(
            children: [
              Text('$value',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + step) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
