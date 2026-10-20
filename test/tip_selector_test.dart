import 'package:campus_delivery/widgets/tip_selector.dart';
import 'package:campus_delivery/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('defaults to zero and reports each preset in cents', (
    tester,
  ) async {
    int? cents = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: TipSelector(onChanged: (value) => cents = value)),
      ),
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '\$0'))
          .selected,
      isTrue,
    );
    for (final amount in [1, 2, 3, 0]) {
      await tester.tap(find.text('\$$amount'));
      await tester.pumpAndSettle();
      expect(cents, amount * 100);
    }
  });

  testWidgets('custom tips reject invalid amounts and recover with a preset', (
    tester,
  ) async {
    int? cents = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: TipSelector(onChanged: (value) => cents = value)),
      ),
    );
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(cents, isNull);
    for (final value in ['', '-1', '50.01', '1.234', 'abc', 'NaN', '1e2']) {
      await tester.enterText(find.byType(TextFormField), value);
      await tester.pumpAndSettle();
      expect(cents, isNull, reason: value);
      expect(
        find.text('Enter \$0–\$50 with up to 2 decimal places'),
        findsOneWidget,
      );
    }
    final valid = {'0': 0, '.50': 50, '1.15': 115, '2.5': 250, '50.00': 5000};
    for (final entry in valid.entries) {
      await tester.enterText(find.byType(TextFormField), entry.key);
      await tester.pumpAndSettle();
      expect(cents, entry.value);
    }
    await tester.enterText(find.byType(TextFormField), '51');
    await tester.tap(find.text('\$2'));
    await tester.pumpAndSettle();
    expect(cents, 200);
    expect(find.byType(TextFormField), findsNothing);
  });
}
