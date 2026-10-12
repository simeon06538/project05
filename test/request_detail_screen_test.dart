import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/screens/courier/request_detail_screen.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

final _now = DateTime(2026, 10, 12, 12, 0);

final _order = Order(
  id: 'order-1',
  customerId: 'customer-1',
  pickupLocation: 'Student Union · Grill',
  dropoffLocation: 'Library · Main entrance',
  distanceMiles: 0.4,
  deliveryFeeCents: 300,
  tipCents: 125,
  status: OrderStatus.requested,
  pawPointsOrderNumber: 'PP-4810',
  createdAt: _now.subtract(const Duration(minutes: 12)),
  updatedAt: _now.subtract(const Duration(minutes: 12)),
);

void main() {
  testWidgets('shows fee, tip, total pay and the Paw Points order number', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RequestDetailScreen(order: _order, now: _now),
      ),
    );

    expect(find.text('Student Union · Grill'), findsOneWidget);
    expect(find.text('Library · Main entrance'), findsOneWidget);
    expect(find.text(r'$3.00'), findsOneWidget);
    expect(find.text(r'$1.25'), findsOneWidget);
    expect(find.text(r'$4.25'), findsOneWidget);
    expect(find.text('PP-4810'), findsOneWidget);
    expect(find.text('0.4 mi'), findsOneWidget);
    expect(find.text('12 min ago'), findsOneWidget);
  });

  testWidgets('tapping a request card opens its details and back returns', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero);
    final first = (await service.fetchAvailableRequests()).first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AvailableTab(service: service)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text(first.pickupLocation));
    await tester.pumpAndSettle();
    expect(find.text('Request details'), findsOneWidget);
    expect(find.text(first.pawPointsOrderNumber), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Request details'), findsNothing);
  });
}
