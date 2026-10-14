import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/completed_delivery_screen.dart';
import 'package:campus_delivery/screens/courier/earnings_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

final _now = DateTime(2026, 10, 14, 18, 0);

Order _delivered({required DateTime at}) => Order(
  id: 'order-1',
  customerId: 'customer-1',
  courierId: 'courier-a',
  pickupLocation: 'Student Union · Grill',
  dropoffLocation: 'Library · Main entrance',
  distanceMiles: 0.4,
  deliveryFeeCents: 300,
  tipCents: 125,
  status: OrderStatus.delivered,
  pawPointsOrderNumber: 'PP-4810',
  createdAt: at.subtract(const Duration(minutes: 20)),
  updatedAt: at,
  acceptedAt: at.subtract(const Duration(minutes: 17)),
  pickedUpAt: at.subtract(const Duration(minutes: 9)),
  deliveredAt: at,
);

void main() {
  test('delivery times read as today, yesterday or a date', () {
    expect(
      formatDayTime(DateTime(2026, 10, 14, 15, 5), now: _now),
      'Today, 3:05 PM',
    );
    expect(
      formatDayTime(DateTime(2026, 10, 13, 9, 30), now: _now),
      'Yesterday, 9:30 AM',
    );
    expect(
      formatDayTime(DateTime(2026, 10, 12, 13, 15), now: _now),
      'Mon Oct 12, 1:15 PM',
    );
  });

  testWidgets('summary shows earnings, breakdown, route and timeline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: CompletedDeliveryScreen(
          order: _delivered(at: DateTime(2026, 10, 14, 15, 5)),
          now: _now,
        ),
      ),
    );

    expect(find.text(r'+$4.25'), findsOneWidget);
    expect(find.text('Delivered Today, 3:05 PM'), findsOneWidget);
    expect(find.text(r'$3.00'), findsOneWidget);
    expect(find.text(r'$1.25'), findsOneWidget);
    expect(find.text(r'$4.25'), findsOneWidget);
    expect(find.text('PP-4810'), findsOneWidget);
    expect(find.text('Library · Main entrance'), findsOneWidget);
    expect(find.text('3:05 PM'), findsOneWidget); // Delivered row
  });

  testWidgets('tapping a history item opens its summary and back returns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;
    await service.acceptRequest(order.id, 'courier-a');
    await service.updateStatus(order.id, OrderStatus.pickedUp);
    await service.updateStatus(order.id, OrderStatus.delivered);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EarningsTab(service: service, courierId: 'courier-a'),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.bySemanticsLabel(RegExp('Delivery to .*view details')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delivery summary'), findsOneWidget);
    expect(find.text('+${formatCents(order.totalPayCents)}'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Delivery summary'), findsNothing);
  });
}
