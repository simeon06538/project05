import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/earnings_stats.dart';

Order _delivered(String id, String dropoff, int feeCents, int tipCents) {
  final time = DateTime(2026, 10, 14, 12);
  return Order(
    id: id,
    customerId: 'customer-1',
    courierId: 'courier-a',
    pickupLocation: 'Student Union · Grill',
    dropoffLocation: dropoff,
    distanceMiles: 0.5,
    deliveryFeeCents: feeCents,
    tipCents: tipCents,
    status: OrderStatus.delivered,
    pawPointsOrderNumber: 'PP-$id',
    createdAt: time,
    updatedAt: time,
    deliveredAt: time,
  );
}

void main() {
  final orders = [
    _delivered('1', 'Library', 300, 100), // $4.00
    _delivered('2', 'Rec Center', 400, 300), // $7.00
    _delivered('3', 'Music Building', 350, 0), // $3.50
  ];

  test('stats add up totals, tips, average and best', () {
    final stats = EarningsStats.from(orders);

    expect(stats.count, 3);
    expect(stats.totalCents, 1450);
    expect(stats.tipsCents, 400);
    expect(stats.averageCents, 483); // $14.50 / 3, rounded
    expect(stats.best?.dropoffLocation, 'Rec Center');
  });

  test('no deliveries means no average and no best', () {
    final stats = EarningsStats.from(const []);

    expect(stats.averageCents, isNull);
    expect(stats.best, isNull);
    expect(stats.tipsCents, 0);
  });

  test('the first of two equal deliveries counts as best', () {
    final stats = EarningsStats.from([
      _delivered('a', 'Library', 300, 100),
      _delivered('b', 'Rec Center', 400, 0),
    ]);

    expect(stats.best?.id, 'a');
  });

  testWidgets('tiles show average, tips and the best delivery', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EarningsStatsRow(stats: EarningsStats.from(orders)),
        ),
      ),
    );

    expect(find.text(r'$4.83'), findsOneWidget);
    expect(find.text(r'$4.00'), findsOneWidget);
    expect(find.text(r'$7.00'), findsOneWidget);
    expect(find.text('Rec Center'), findsOneWidget);
    expect(
      find.bySemanticsLabel(r'Best delivery, $7.00, Rec Center'),
      findsOneWidget,
    );
  });

  testWidgets('tiles show dashes before the first delivery', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EarningsStatsRow(stats: EarningsStats.from(const [])),
        ),
      ),
    );

    expect(find.text('—'), findsNWidgets(2));
    expect(find.text(r'$0.00'), findsOneWidget);
  });
}
