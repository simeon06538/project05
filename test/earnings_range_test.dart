import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/earnings_stats.dart';
import 'package:campus_delivery/screens/courier/earnings_tab.dart';
import 'package:campus_delivery/screens/courier/request_sort_bar.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

final _now = DateTime(2026, 10, 14, 18);

Order _deliveredDaysAgo(int days) {
  final at = _now.subtract(Duration(days: days, hours: 1));
  return Order(
    id: 'order-$days',
    customerId: 'c',
    courierId: 'courier-a',
    pickupLocation: 'Student Union · Grill',
    dropoffLocation: 'Library $days',
    distanceMiles: 0.4,
    deliveryFeeCents: 300,
    tipCents: 100,
    status: OrderStatus.delivered,
    pawPointsOrderNumber: 'PP-$days',
    createdAt: at,
    updatedAt: at,
    deliveredAt: at,
  );
}

void main() {
  final orders = [
    _deliveredDaysAgo(0),
    _deliveredDaysAgo(3),
    _deliveredDaysAgo(9),
  ];

  test('ranges cover today, the last 7 days, or everything', () {
    expect(filterByRange(orders, EarningsRange.today, _now), hasLength(1));
    expect(filterByRange(orders, EarningsRange.week, _now), hasLength(2));
    expect(filterByRange(orders, EarningsRange.all, _now), hasLength(3));
  });

  testWidgets('switching range updates the stats and the history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // A week of demo history: 8 deliveries, none of them today.
    final service = MockCourierService(latency: Duration.zero)
      ..seedHistory('courier-a', now: _now);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EarningsTab(
            service: service,
            courierId: 'courier-a',
            now: _now,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Completed deliveries · 8'), findsOneWidget);

    // The chart also has a 'Today' label, so tap the range chip.
    await tester.tap(find.widgetWithText(FilterPill, 'Today'));
    await tester.pump();
    expect(find.text('Completed deliveries · 0'), findsOneWidget);
    expect(find.text('No deliveries today yet.'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2)); // no average, no best

    await tester.tap(find.text('See all time'));
    await tester.pump();
    expect(find.text('Completed deliveries · 8'), findsOneWidget);
  });
}
