import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/status_stepper.dart';
import 'package:campus_delivery/theme/app_theme.dart';
import 'package:campus_delivery/widgets/primary_button.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group('StatusStepper', () {
    testWidgets('marks Accepted as the current step', (tester) async {
      await _pump(tester, const StatusStepper(status: OrderStatus.accepted));

      expect(find.bySemanticsLabel('Accepted, current step'), findsOneWidget);
      expect(find.bySemanticsLabel('Picked up'), findsOneWidget);
      expect(find.bySemanticsLabel('Delivered'), findsOneWidget);
    });

    testWidgets('moves the current step to Picked up', (tester) async {
      await _pump(tester, const StatusStepper(status: OrderStatus.pickedUp));

      expect(find.bySemanticsLabel('Accepted'), findsOneWidget);
      expect(find.bySemanticsLabel('Picked up, current step'), findsOneWidget);
    });

    test('next step only goes forward', () {
      expect(OrderStatus.accepted.next, OrderStatus.pickedUp);
      expect(OrderStatus.pickedUp.next, OrderStatus.delivered);
      expect(OrderStatus.delivered.next, isNull);
      expect(OrderStatus.requested.next, isNull);
      expect(OrderStatus.cancelled.next, isNull);
    });
  });

  group('PrimaryButton (status and accept actions)', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var presses = 0;
      await _pump(
        tester,
        PrimaryButton(label: 'Mark as picked up', onPressed: () => presses++),
      );

      await tester.tap(find.text('Mark as picked up'));
      expect(presses, 1);
    });

    testWidgets('shows a spinner and ignores taps while loading', (
      tester,
    ) async {
      var presses = 0;
      await _pump(
        tester,
        PrimaryButton(
          label: 'Mark as picked up',
          loading: true,
          onPressed: () => presses++,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Mark as picked up'), findsNothing);
      await tester.tap(find.byType(PrimaryButton));
      expect(presses, 0);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await _pump(
        tester,
        const PrimaryButton(
          label: 'Finish your current delivery first',
          onPressed: null,
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}
