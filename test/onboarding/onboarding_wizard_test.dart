import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceshift/core/theme.dart';
import 'package:paceshift/data/db/app_database.dart';
import 'package:paceshift/presentation/onboarding/onboarding_screen.dart';
import 'package:paceshift/presentation/providers/providers.dart';

Future<AppDatabase> _pumpWizard(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const OnboardingScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

void main() {
  testWidgets('wizard walks every step and generates a plan', (tester) async {
    final db = await _pumpWizard(tester);

    // Welcome.
    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // 1: name.
    expect(find.text('First, what should we call you?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Fahad');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 2: the race — distance and date together.
    expect(find.text('What are you training for?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 3: your running — current fitness and weekly shape together.
    expect(find.text('Tell us about your running'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 4: goal time.
    expect(find.text('Do you have a goal finish time?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 5: review + generate.
    expect(find.text('Generate my plan'), findsOneWidget);
    await tester.tap(find.text('Generate my plan'));
    await tester.pumpAndSettle();

    final plan = await PlanDao(db).getActivePlan();
    expect(plan, isNotNull);
    final settings = await SettingsDao(db).getSettings();
    expect(settings?.userName, 'Fahad');
  });

  testWidgets('the wizard is six screens, not nine', (tester) async {
    await _pumpWizard(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // The counter is the athlete's promise about how long this takes. It read
    // "1 of 7" — and the real first run was nine screens, because a forced
    // health-permission step waited on the far side of "Generate my plan".
    expect(find.text('1 of 5'), findsOneWidget);
  });

  testWidgets('the optional name step can actually be skipped', (tester) async {
    final db = await _pumpWizard(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // The copy always said "skip if you'd rather not" and then offered only a
    // "Continue" button.
    expect(find.text('Skip this'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Fahad');
    await tester.tap(find.text('Skip this'));
    await tester.pumpAndSettle();

    expect(find.text('What are you training for?'), findsOneWidget);

    // Skipping clears the name rather than quietly keeping what was typed.
    for (final label in ['Continue', 'Continue', 'Continue']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Generate my plan'));
    await tester.pumpAndSettle();

    expect((await SettingsDao(db).getSettings())?.userName, '');
  });
}
