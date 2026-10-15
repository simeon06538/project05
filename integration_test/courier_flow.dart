import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

/// K-49: the whole courier journey, shared by the on-device integration
/// test and a normal `flutter test` run: accept a request, tick the pickup
/// checklist, mark it picked up and delivered with a note, then see the
/// pay on Earnings.
Future<void> runCourierFlow(WidgetTester tester) async {
  final service = MockCourierService(latency: Duration.zero);
  final order = (await service.fetchAvailableRequests()).first;
  await tester.pumpWidget(CampusDeliveryApp(courierService: service));
  await _settle(tester);

  // Available -> request details.
  await _tapText(tester, order.pickupLocation);
  expect(find.text('Request details'), findsOneWidget);

  // Accept, confirm, and leave the success screen.
  await _tap(tester, find.textContaining('Accept delivery'));
  await _tapText(tester, 'Accept');
  expect(find.text('Delivery accepted!'), findsOneWidget);
  await _tapText(tester, 'Start delivery');
  expect(find.text('Pick up at ${order.pickupLocation}'), findsOneWidget);

  // Pickup checklist, then picked up.
  final boxes = find.byType(Checkbox);
  await _tap(tester, boxes.at(0));
  await _tap(tester, boxes.at(1));
  await _tapText(tester, 'Mark as picked up');
  expect(
    (await service.fetchActiveDelivery(demoCourierId))?.status,
    OrderStatus.pickedUp,
  );

  // Delivered, with a drop-off note.
  ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
      .clearSnackBars();
  await _settle(tester);
  await _tap(tester, find.textContaining('Mark as delivered'));
  await tester.enterText(find.byType(TextField).last, 'Handed to the customer');
  await _tapText(tester, 'Yes, delivered');
  expect(find.text('No active delivery'), findsOneWidget);

  // Paid: the balance and history on Earnings.
  await _tap(tester, find.text('Earnings').first);
  final earnings = await service.fetchEarnings(demoCourierId);
  expect(earnings.balanceCents, order.totalPayCents);
  expect(
    earnings.completedDeliveries.single.dropoffNote,
    'Handed to the customer',
  );
  await tester.scrollUntilVisible(
    find.text('+${formatCents(order.totalPayCents)}'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  expect(find.text('+${formatCents(order.totalPayCents)}'), findsOneWidget);
}

/// Waits for route changes, dialogs and short animations. Looping Lottie
/// animations never "settle", so this waits a fixed time instead.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await _tap(tester, finder.first);
}
