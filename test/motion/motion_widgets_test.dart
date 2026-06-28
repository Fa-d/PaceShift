import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/presentation/widgets/count_up_text.dart';
import 'package:paceshift/presentation/widgets/pressable.dart';

void main() {
  testWidgets('CountUpText settles on the formatted final value',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CountUpText(value: 42, format: (n) => '${n.round()} km'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('42 km'), findsOneWidget);
  });

  testWidgets('CountUpText renders final value instantly under reduced motion',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: CountUpText(value: 7, format: (n) => '${n.round()}'),
            ),
          ),
        ),
      ),
    );
    // No settle needed — value is immediate.
    await tester.pump();
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('Pressable forwards taps to its child', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Pressable(
              child: GestureDetector(
                onTap: () => tapped = true,
                child: Container(width: 120, height: 60, color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(Pressable));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
