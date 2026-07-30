import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/theme.dart';
import 'package:paceshift/domain/models/enums.dart';
import 'package:paceshift/presentation/widgets/common.dart';

/// Every shared surface, rendered in both themes.
///
/// `QuietSurface` shipped with a crash on its very first frame — it handed
/// `Material` both a `shape` and a `borderRadius`, which is an assertion
/// failure, and the whole Today screen came up as a red error box. Nothing
/// caught it because no test had ever built one. These do.
Future<void> _pump(WidgetTester tester, Widget child,
    {Brightness brightness = Brightness.light}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    final name = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('HeroSurface renders in $name', (tester) async {
      await _pump(tester, const HeroSurface(child: Text('hero')),
          brightness: brightness);
      expect(tester.takeException(), isNull);
      expect(find.text('hero'), findsOneWidget);
    });

    testWidgets('QuietSurface renders in $name, plain and accented',
        (tester) async {
      await _pump(
        tester,
        const Column(children: [
          QuietSurface(child: Text('plain')),
          QuietSurface(accent: Colors.orange, child: Text('accented')),
        ]),
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('plain'), findsOneWidget);
      expect(find.text('accented'), findsOneWidget);
    });

    testWidgets('the small parts render in $name', (tester) async {
      await _pump(
        tester,
        Column(children: [
          for (final type in RunType.values) RunTypeBadge(type: type),
          for (final status in RunStatus.values) StatusChip(status: status),
          const IconChip(icon: Icons.bolt_rounded),
          const MetricBlock(value: '12 km', label: 'target'),
          const FeatureRow(
              icon: Icons.flag_rounded, title: 'Title', description: 'Body'),
          ShiftBanner(from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 2)),
          const SurfaceError(message: 'Nope', compact: true),
        ]),
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a tappable QuietSurface actually reports taps', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      QuietSurface(onTap: () => taps++, child: const Text('tap me')),
    );
    await tester.tap(find.text('tap me'));
    expect(taps, 1);
  });

  testWidgets('SurfaceError offers a way out', (tester) async {
    var retries = 0;
    await _pump(
      tester,
      SurfaceError(message: 'Nope', onRetry: () => retries++),
    );
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });
}
