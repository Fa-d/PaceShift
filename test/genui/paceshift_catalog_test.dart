import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'package:paceshift/data/api/genui_models.dart';
import 'package:paceshift/presentation/genui/paceshift_catalog.dart';

void main() {
  Future<void> pumpSpec(
    WidgetTester tester,
    GenUiSpec spec, {
    void Function(GenUiAction)? onAction,
  }) async {
    final controller = SurfaceController(
      catalogs: [buildPaceShiftCatalog(onAction: onAction ?? (_) {})],
    );
    addTearDown(controller.dispose);
    for (final message in specToMessages(spec, 's0')) {
      controller.handleMessage(message);
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Surface(surfaceContext: controller.contextFor('s0')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders a composed spec into native PaceShift widgets',
      (tester) async {
    const spec = GenUiSpec([
      UiBlock(type: 'section', title: 'This week'),
      UiBlock(
          type: 'metric',
          value: '3h52m',
          label: 'Predicted finish',
          tone: 'positive'),
      UiBlock(
          type: 'run_card',
          runId: 42,
          title: 'Long run',
          subtitle: 'Sun · 18 km',
          status: 'shifted'),
      UiBlock(type: 'text', body: 'You are on track.'),
      UiBlock(
          type: 'action_button',
          label: 'Apply',
          action: 'apply_reshuffle',
          style: 'filled'),
    ]);

    await pumpSpec(tester, spec);

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('3h52m'), findsOneWidget);
    expect(find.text('Predicted finish'), findsOneWidget);
    expect(find.text('Long run'), findsOneWidget);
    expect(find.text('You are on track.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Apply'), findsOneWidget);
  });

  testWidgets('tapping an action button reports the action to the host',
      (tester) async {
    GenUiAction? captured;
    const spec = GenUiSpec([
      UiBlock(
          type: 'action_button',
          label: 'Apply reshuffle',
          action: 'apply_reshuffle',
          style: 'filled',
          confirm: true),
    ]);

    await pumpSpec(tester, spec, onAction: (a) => captured = a);
    await tester.tap(find.byType(FilledButton));

    expect(captured, isNotNull);
    expect(captured!.action, 'apply_reshuffle');
    expect(captured!.confirm, isTrue);
  });

  test('mapper drops unknown block types and keeps child wiring intact', () {
    const spec = GenUiSpec([
      UiBlock(type: 'iframe', body: '<script>'), // not allow-listed
      UiBlock(type: 'text', body: 'ok'),
    ]);
    final messages = specToMessages(spec, 's');
    final update = messages.whereType<UpdateComponents>().single;

    // root + the single valid (text) component — the iframe is dropped.
    expect(update.components.length, 2);
    final root = update.components.firstWhere((c) => c.id == 'root');
    expect(root.properties['children'], ['b1']);
  });
}
