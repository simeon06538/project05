import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/delivery_timeline.dart';
import 'package:campus_delivery/screens/courier/my_deliveries_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

void main() {
  test('clock times use 12-hour format', () {
    expect(formatClock(DateTime(2026, 10, 14, 0, 5)), '12:05 AM');
    expect(formatClock(DateTime(2026, 10, 14, 9, 30)), '9:30 AM');
    expect(formatClock(DateTime(2026, 10, 14, 12, 0)), '12:00 PM');
    expect(formatClock(DateTime(2026, 10, 14, 15, 7)), '3:07 PM');
  });

  test('the mock stamps each delivery step', () async {
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;
    expect(order.acceptedAt, isNull);

    final accepted = await service.acceptRequest(order.id, 'courier-a');
    expect(accepted.acceptedAt, isNotNull);
    expect(accepted.pickedUpAt, isNull);

    final pickedUp = await service.updateStatus(order.id, OrderStatus.pickedUp);
    expect(pickedUp.acceptedAt, accepted.acceptedAt);
    expect(pickedUp.pickedUpAt, isNotNull);

    final delivered = await service.updateStatus(
      order.id,
      OrderStatus.delivered,
    );
    expect(delivered.deliveredAt, isNotNull);
    expect(delivered.timeOf(OrderStatus.requested), order.createdAt);
  });

  testWidgets('timeline shows times for done steps and what comes next', (
    tester,
  ) async {
    final created = DateTime(2026, 10, 14, 15, 0);
    final order = Order(
      id: 'order-1',
      customerId: 'customer-1',
      pickupLocation: 'Student Union · Grill',
      dropoffLocation: 'Library · Main entrance',
      distanceMiles: 0.4,
      deliveryFeeCents: 300,
      tipCents: 100,
      status: OrderStatus.accepted,
      pawPointsOrderNumber: 'PP-4810',
      createdAt: created,
      updatedAt: created,
      acceptedAt: DateTime(2026, 10, 14, 15, 4),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DeliveryTimeline(order: order)),
      ),
    );

    expect(find.bySemanticsLabel('Requested, 3:00 PM'), findsOneWidget);
    expect(find.bySemanticsLabel('Accepted, 3:04 PM'), findsOneWidget);
    expect(find.bySemanticsLabel('Picked up, Next'), findsOneWidget);
    expect(find.bySemanticsLabel('Delivered, Pending'), findsOneWidget);
  });

  testWidgets('past steps without a time show as done (K-12)', (tester) async {
    // A server order loaded after pickup: no accept or pickup times.
    final created = DateTime(2026, 10, 14, 15, 0);
    final order = Order(
      id: '7',
      customerId: '2',
      pickupLocation: 'The 5 · Popeyes',
      dropoffLocation: 'Spruce Hall',
      distanceMiles: 0.6,
      deliveryFeeCents: 350,
      tipCents: 100,
      status: OrderStatus.pickedUp,
      pawPointsOrderNumber: 'PP-7',
      createdAt: created,
      updatedAt: created,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DeliveryTimeline(order: order)),
      ),
    );

    expect(find.bySemanticsLabel('Requested, 3:00 PM'), findsOneWidget);
    expect(find.bySemanticsLabel('Accepted, Done'), findsOneWidget);
    expect(find.bySemanticsLabel('Picked up, Done'), findsOneWidget);
    expect(find.bySemanticsLabel('Delivered, Next'), findsOneWidget);
  });

  testWidgets('active delivery shows the timeline after pickup', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;
    await service.acceptRequest(order.id, 'courier-a');
    await service.updateStatus(order.id, OrderStatus.pickedUp);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyDeliveriesTab(service: service, courierId: 'courier-a'),
        ),
      ),
    );
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Timeline'), 200);
    // Bring the whole timeline on screen so its rows are in the
    // semantics tree.
    await tester.ensureVisible(find.byType(DeliveryTimeline));
    await tester.pump();

    expect(find.text('Timeline'), findsOneWidget);
    // After pickup only Delivered is left, and it's the next step.
    Finder inTimeline(String text) => find.descendant(
      of: find.byType(DeliveryTimeline),
      matching: find.text(text),
    );
    expect(inTimeline('Next'), findsOneWidget);
    expect(inTimeline('Pending'), findsNothing);
  });
}
