import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/my_deliveries_tab.dart';
import 'package:campus_delivery/screens/courier/status_stepper.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

const _courier = 'courier-a';

Future<void> _pumpTab(WidgetTester tester, MockCourierService service) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MyDeliveriesTab(service: service, courierId: _courier),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the empty state with no active delivery', (tester) async {
    await _pumpTab(tester, MockCourierService(latency: Duration.zero));

    expect(find.text('No active delivery'), findsOneWidget);
  });

  testWidgets('shows progress, pickup instructions and pay once accepted', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;
    await service.acceptRequest(order.id, _courier);
    await _pumpTab(tester, service);

    // The progress bar (the timeline below repeats these names).
    Finder inStepper(String text) => find.descendant(
      of: find.byType(StatusStepper),
      matching: find.text(text),
    );
    expect(inStepper('Accepted'), findsOneWidget);
    expect(inStepper('Picked up'), findsOneWidget);
    expect(inStepper('Delivered'), findsOneWidget);
    expect(find.text('Pick up at ${order.pickupLocation}'), findsOneWidget);
    expect(
      find.text('Show order ${order.pawPointsOrderNumber} at the counter.'),
      findsOneWidget,
    );
    expect(find.text(formatCents(order.totalPayCents)), findsOneWidget);
  });

  testWidgets('after pickup, the next step is the drop-off', (tester) async {
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;
    await service.acceptRequest(order.id, _courier);
    await service.updateStatus(order.id, OrderStatus.pickedUp);
    await _pumpTab(tester, service);

    expect(find.text('Drop off at ${order.dropoffLocation}'), findsOneWidget);
    expect(find.text('Hand the food to the customer.'), findsOneWidget);
  });

  testWidgets('a delivery accepted on Available shows up under View', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;
    await tester.pumpWidget(CampusDeliveryApp(courierService: service));
    await tester.pump();

    // Accept while the app is open, then come back to the Available tab
    // so it reloads and shows the banner.
    await service.acceptRequest(order.id, demoCourierId);
    await tester.tap(find.text('Earnings'));
    await tester.pump();
    await tester.tap(find.text('Available'));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('View'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Pick up at ${order.pickupLocation}'), findsOneWidget);
  });
}
