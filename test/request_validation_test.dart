import 'package:campus_delivery/screens/customer/request_delivery_screen.dart';
import 'package:campus_delivery/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const RequestDeliveryScreen(orderName: 'Taylor'),
      ),
    );
  }

  Future<void> review(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Review request'));
    await tester.tap(find.text('Review request'));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, int index, String location) async {
    final field = find.byType(DropdownButtonFormField<String>).at(index);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(location).last);
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.ensureVisible(fields.at(1));
    await tester.enterText(fields.at(1), 'Chick-fil-A');
    await tester.ensureVisible(fields.at(2));
    await tester.enterText(fields.at(2), 'PP-123');
    await choose(tester, 1, 'Middleton Library');
  }

  testWidgets('rejects blank and whitespace-only required fields', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, '   ');
    await review(tester);
    expect(find.text('Enter the name on your food order'), findsOneWidget);
    expect(find.text('Enter the pickup restaurant'), findsOneWidget);
    expect(find.text('Enter your Paw Points order number'), findsOneWidget);
    expect(find.text('Choose a drop-off location'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Review your delivery'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects identical locations and rechecks when pickup changes', (
    tester,
  ) async {
    await open(tester);
    await fill(tester);
    await choose(tester, 0, 'Middleton Library');
    await review(tester);
    expect(find.text('Pickup and drop-off must be different'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Review your delivery'), findsNothing);
    await choose(tester, 0, 'LSU Student Union');
    expect(find.text('Pickup and drop-off must be different'), findsNothing);
    await review(tester);
    expect(find.text('Review your delivery'), findsOneWidget);
  });

  testWidgets(
    'blocks an invalid custom tip and accepts correction to the maximum',
    (tester) async {
      await open(tester);
      await fill(tester);
      await tester.ensureVisible(find.text('Custom'));
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      final custom = find.widgetWithText(TextFormField, 'Custom tip');
      await tester.ensureVisible(custom);
      await tester.enterText(custom, '50.01');
      await review(tester);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Review your delivery'), findsNothing);
      expect(
        find.text('Enter \$0–\$50 with up to 2 decimal places'),
        findsOneWidget,
      );
      await tester.enterText(custom, '50');
      await review(tester);
      expect(find.text('Review your delivery'), findsOneWidget);
    },
  );
}
