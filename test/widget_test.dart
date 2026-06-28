import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/core/theme.dart';

void main() {
  testWidgets('app theme builds a Material app', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const SizedBox.shrink()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
