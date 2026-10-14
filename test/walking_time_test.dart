import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/order_widgets.dart';
import 'package:campus_delivery/screens/courier/request_card.dart';
import 'package:campus_delivery/screens/courier/request_detail_screen.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Order _order(double miles) {
  final created = DateTime(2026, 10, 13, 12);
  return Order(
    id: 'order-1',
    customerId: 'customer-1',
    pickupLocation: 'Student Union · Grill',
    dropoffLocation: 'Library · Main entrance',
    distanceMiles: miles,
    deliveryFeeCents: 300,
    tipCents: 0,
    status: OrderStatus.requested,
    pawPointsOrderNumber: 'PP-4810',
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  test('walking time is about 20 minutes per mile, rounded up', () {
    expect(walkingMinutes(0.4), 8);
    expect(walkingMinutes(0.33), 7);
    expect(walkingMinutes(1.1), 22);
    expect(walkingMinutes(0), 1);
  });

  test('long walks are shown in hours and minutes', () {
    expect(walkingLabel(0.4), '8 min walk');
    expect(walkingLabel(3), '1 h walk');
    expect(walkingLabel(3.5), '1 h 10 min walk');
  });

  testWidgets('request card shows the walking time', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RequestCard(order: _order(0.7))),
      ),
    );

    expect(find.text('14 min walk'), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsOneWidget);
  });

  testWidgets('detail screen shows the walking time', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RequestDetailScreen(
          order: _order(1.1),
          service: MockCourierService(latency: Duration.zero),
          courierId: 'courier-a',
          now: DateTime(2026, 10, 13, 12, 5),
        ),
      ),
    );

    expect(find.text('22 min walk'), findsOneWidget);
  });
}
