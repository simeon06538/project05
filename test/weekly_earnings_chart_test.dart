import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/weekly_earnings_chart.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

// A Wednesday, so the last 7 days run Thu..Wed.
final _now = DateTime(2026, 10, 14, 18);

Order _deliveredDaysAgo(int days, int feeCents, int tipCents) {
  final delivered = _now.subtract(Duration(days: days, hours: 1));
  return Order(
    id: 'order-$days-$feeCents',
    customerId: 'customer-1',
    courierId: 'courier-a',
    pickupLocation: 'Student Union · Grill',
    dropoffLocation: 'Library · Main entrance',
    distanceMiles: 0.4,
    deliveryFeeCents: feeCents,
    tipCents: tipCents,
    status: OrderStatus.delivered,
    pawPointsOrderNumber: 'PP-4810',
    createdAt: delivered,
    updatedAt: delivered,
    deliveredAt: delivered,
  );
}

void main() {
  test('daily totals bucket deliveries into the last 7 days', () {
    final totals = dailyTotalsCents([
      _deliveredDaysAgo(0, 300, 100), // today
      _deliveredDaysAgo(0, 350, 0), // today
      _deliveredDaysAgo(2, 400, 50),
      _deliveredDaysAgo(6, 300, 0), // oldest bar
      _deliveredDaysAgo(7, 999, 0), // too old, ignored
    ], _now);

    expect(totals, [300, 0, 0, 0, 450, 0, 750]);
  });

  testWidgets('chart shows the week total and today by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyEarningsChart(
            completed: [
              _deliveredDaysAgo(0, 300, 100),
              _deliveredDaysAgo(2, 400, 50),
            ],
            now: _now,
          ),
        ),
      ),
    );

    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text(r'$8.50'), findsOneWidget);
    expect(find.text(r'Today · $4.00'), findsOneWidget);
    // Day labels for Thu..Tue plus Today.
    expect(find.text('Thu'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
  });

  testWidgets('tapping a bar shows that day', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyEarningsChart(
            completed: [_deliveredDaysAgo(2, 400, 50)],
            now: _now,
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel(r'Mon, $4.50'));
    await tester.pump();

    expect(find.text(r'Mon · $4.50'), findsOneWidget);
  });

  test(
    'seedHistory gives the demo courier a week of paid deliveries',
    () async {
      final service = MockCourierService(latency: Duration.zero)
        ..seedHistory('courier-demo');

      final earnings = await service.fetchEarnings('courier-demo');
      final totals = dailyTotalsCents(
        earnings.completedDeliveries,
        DateTime.now(),
      );

      expect(earnings.completedDeliveries, hasLength(8));
      expect(earnings.balanceCents, totals.fold(0, (a, b) => a + b));
      // Seeded history never adds open requests.
      expect(await service.fetchAvailableRequests(), hasLength(5));
    },
  );
}
