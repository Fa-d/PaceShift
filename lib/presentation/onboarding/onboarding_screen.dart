import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../core/theme.dart';
import '../../domain/models/enums.dart';
import '../../domain/plan_generator/plan_input.dart';
import '../providers/providers.dart';

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
  // Step 0 is the welcome intro; 1..7 are the questions.
  static const int _lastStep = 7;
  int _step = 0;

  // --- Collected inputs ---
  final _nameController = TextEditingController();
  UnitSystem _units = UnitSystem.metric;
  double _raceDistanceKm = 42.2;
  DateTime _raceDate = DateTime.now().add(const Duration(days: 133)); // ~19 weeks
  final _longestRun = TextEditingController(text: '18');
  String? _longestError;
  int _daysPerWeek = 3;
  int _longRunDay = DateTime.saturday;
  bool _hasGoalTime = false;
  int _goalHours = 4;
  int _goalMinutes = 0;

  bool _creating = false;

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
    if (step == 4) {
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

  void _setUnits(UnitSystem u) {
    if (u == _units) return;
    final v = double.tryParse(_longestRun.text.trim());
    setState(() {
      if (v != null && v > 0) {
        final km = _toKm(v); // convert from the *old* unit to km first
        final converted = u == UnitSystem.metric ? km : km / 1.60934;
        _longestRun.text = _trimNum(converted);
      }
      _units = u;
    });
  }

  Future<void> _generate() async {
    setState(() => _creating = true);
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
          const SizedBox(width: 14),
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
          SizedBox(width: 8),
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
          const SizedBox(width: 12),
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
        return _distanceStep(theme);
      case 3:
        return _dateStep(theme);
      case 4:
        return _fitnessStep(theme);
      case 5:
        return _weekStep(theme);
      case 6:
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
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
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
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.ember.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(Icons.directions_run_rounded,
                color: AppTheme.ember, size: 48),
          ),
          const SizedBox(height: 28),
          Text('PaceShift', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Plans that bend, not break.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          const _FeatureRow(
            icon: Icons.flag_rounded,
            text: 'Your race date stays fixed — the anchor never moves.',
          ),
          const SizedBox(height: 14),
          const _FeatureRow(
            icon: Icons.autorenew_rounded,
            text: 'Miss a run? The work is safely redistributed, never crammed.',
          ),
          const SizedBox(height: 14),
          const _FeatureRow(
            icon: Icons.shield_moon_rounded,
            text: 'Science-based progression with built-in safety guardrails.',
          ),
          const Spacer(flex: 3),
          FilledButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('Get started'),
          ),
          const SizedBox(height: 10),
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
      ],
    );
  }

  Widget _distanceStep(ThemeData theme) {
    return _stepScaffold(
      title: 'Which race are you training for?',
      subtitle: 'This sets the shape and peak of your plan.',
      children: [
        _OptionCard(
          icon: Icons.terrain_rounded,
          title: 'Marathon',
          subtitle: '42.2 km · 26.2 mi',
          selected: _raceDistanceKm == 42.2,
          onTap: () => setState(() => _raceDistanceKm = 42.2),
        ),
        const SizedBox(height: 14),
        _OptionCard(
          icon: Icons.directions_run_rounded,
          title: 'Half marathon',
          subtitle: '21.1 km · 13.1 mi',
          selected: _raceDistanceKm == 21.1,
          onTap: () => setState(() => _raceDistanceKm = 21.1),
        ),
      ],
    );
  }

  Widget _dateStep(ThemeData theme) {
    final scheme = theme.colorScheme;
    return _stepScaffold(
      title: 'When’s race day?',
      subtitle: 'Everything counts back from here — taper included.',
      children: [
        InkWell(
          onTap: _pickRaceDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_rounded, color: AppTheme.ember),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '${formatDateLabel(_raceDate)}, ${_raceDate.year}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.edit_calendar_rounded,
                    color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.ember.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.timelapse_rounded,
                  color: AppTheme.ember, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '≈ $_weeksToRace weeks until race day',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fitnessStep(ThemeData theme) {
    return _stepScaffold(
      title: 'How far is your longest recent run?',
      subtitle: 'A rough number is fine — it sets your safe starting point.',
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<UnitSystem>(
            segments: const [
              ButtonSegment(value: UnitSystem.metric, label: Text('km')),
              ButtonSegment(value: UnitSystem.imperial, label: Text('mi')),
            ],
            selected: {_units},
            onSelectionChanged: (s) => _setUnits(s.first),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _longestRun,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.straighten_rounded),
            suffixText: _unitLabel,
            errorText: _longestError,
            hintText: _units == UnitSystem.metric ? 'e.g. 18' : 'e.g. 11',
          ),
          onChanged: (_) {
            if (_longestError != null) setState(() => _longestError = null);
          },
        ),
      ],
    );
  }

  Widget _weekStep(ThemeData theme) {
    return _stepScaffold(
      title: 'How does your training week look?',
      subtitle: 'You can fine-tune both of these any time.',
      children: [
        _GroupLabel('Runs per week', theme),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 3, label: Text('3')),
            ButtonSegment(value: 4, label: Text('4')),
            ButtonSegment(value: 5, label: Text('5')),
          ],
          selected: {_daysPerWeek},
          onSelectionChanged: (s) => setState(() => _daysPerWeek = s.first),
        ),
        const SizedBox(height: 24),
        _GroupLabel('Long-run day', theme),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
      subtitle: 'Set one to unlock pace targets and quality workouts. Leave it '
          'off to train by feel.',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I have a goal finish time'),
          subtitle: const Text('Unlocks pace targets & quality workouts'),
          value: _hasGoalTime,
          onChanged: (v) => setState(() => _hasGoalTime = v),
        ),
        const SizedBox(height: 12),
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
              const SizedBox(width: 12),
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
        const SizedBox(height: 16),
        Text(
          'Your race date is the anchor. Miss a run and PaceShift safely '
          'redistributes the work — it never crams unsafe weeks.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// A bullet on the welcome screen: icon + supporting line.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.ember.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.ember, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.ember.withValues(alpha: 0.10)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.ember : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.ember.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.directions_run_rounded,
                  color: AppTheme.ember, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 2),
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
              color: selected ? AppTheme.ember : scheme.outlineVariant,
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
          const SizedBox(width: 14),
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
