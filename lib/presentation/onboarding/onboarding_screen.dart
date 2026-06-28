import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../core/theme.dart';
import '../../domain/plan_generator/plan_input.dart';
import '../providers/providers.dart';

/// Collects race details and generates the training plan (spec §8.1).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _raceDate = DateTime.now().add(const Duration(days: 133)); // ~19 weeks
  double _raceDistanceKm = 42.2;
  final _longestRun = TextEditingController(text: '18');
  int _daysPerWeek = 3;
  int _longRunDay = DateTime.saturday;
  bool _hasGoalTime = false;
  int _goalHours = 4;
  int _goalMinutes = 0;
  bool _creating = false;

  @override
  void dispose() {
    _longestRun.dispose();
    super.dispose();
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

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _creating = true);
    final input = PlanInput(
      raceDate: _raceDate,
      raceDistanceKm: _raceDistanceKm,
      currentLongestRunKm: double.parse(_longestRun.text.trim()),
      daysPerWeek: _daysPerWeek,
      preferredLongRunDay: _longRunDay,
      goalFinishSec:
          _hasGoalTime ? (_goalHours * 3600 + _goalMinutes * 60) : null,
    );
    try {
      await ref.read(settingsRepositoryProvider).ensureDefaults();
      await ref.read(planRepositoryProvider).createPlanFromInput(input);
      // Router redirect picks up the active plan and moves to Today.
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.ember.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.directions_run_rounded,
                        color: AppTheme.ember, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PaceShift', style: theme.textTheme.headlineMedium),
                        Text('Let’s build your plan',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _label('Race date', theme),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickRaceDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.event_rounded)),
                  child: Text('${formatDateLabel(_raceDate)}, ${_raceDate.year}'),
                ),
              ),
              const SizedBox(height: 20),
              _label('Race distance', theme),
              const SizedBox(height: 8),
              SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 42.2, label: Text('Marathon')),
                  ButtonSegment(value: 21.1, label: Text('Half')),
                ],
                selected: {_raceDistanceKm},
                onSelectionChanged: (s) =>
                    setState(() => _raceDistanceKm = s.first),
              ),
              const SizedBox(height: 20),
              _label('Current longest run (km)', theme),
              const SizedBox(height: 8),
              TextFormField(
                controller: _longestRun,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.straighten_rounded)),
                validator: (v) {
                  final d = double.tryParse((v ?? '').trim());
                  if (d == null || d <= 0) return 'Enter your longest recent run';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _label('Runs per week', theme),
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
              const SizedBox(height: 20),
              _label('Long-run day', theme),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (var d = 1; d <= 7; d++)
                    ChoiceChip(
                      label: Text(weekdayName(d)),
                      selected: _longRunDay == d,
                      onSelected: (_) => setState(() => _longRunDay = d),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I have a goal finish time'),
                subtitle: const Text('Unlocks pace targets & quality workouts'),
                value: _hasGoalTime,
                onChanged: (v) => setState(() => _hasGoalTime = v),
              ),
              if (_hasGoalTime)
                Row(
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
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _creating ? null : _generate,
                icon: _creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_creating ? 'Building…' : 'Generate my plan'),
              ),
              const SizedBox(height: 12),
              Text(
                'Your race date is the anchor. Miss a run and PaceShift safely '
                'redistributes the work — it never crams unsafe weeks.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, ThemeData theme) => Text(
        text,
        style: theme.textTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      );
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
