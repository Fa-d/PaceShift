import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceshift/core/theme.dart';
import 'package:paceshift/data/db/app_database.dart';
import 'package:paceshift/presentation/onboarding/onboarding_screen.dart';
import 'package:paceshift/presentation/providers/providers.dart';

void main() {
  testWidgets('wizard walks every step and generates a plan', (tester) async {
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

    // Welcome step.
    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Step 1: name.
    expect(find.text('First, what should we call you?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Fahad');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: distance.
    expect(find.text('Which race are you training for?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3: race date.
    expect(find.text('When’s race day?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 4: fitness.
    expect(find.text('How far is your longest recent run?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 5: week.
    expect(find.text('How does your training week look?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 6: goal.
    expect(find.text('Do you have a goal finish time?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 7: review + generate.
    expect(find.text('Generate my plan'), findsOneWidget);
    await tester.tap(find.text('Generate my plan'));
    await tester.pumpAndSettle();

    // A plan + its runs should now exist, and the name/units persisted.
    final plan = await PlanDao(db).getActivePlan();
    expect(plan, isNotNull);
    final settings = await SettingsDao(db).getSettings();
    expect(settings?.userName, 'Fahad');
  });
}
