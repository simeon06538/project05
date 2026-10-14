import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/screens/courier/request_filters.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Order _order(double miles, int payCents) {
  final at = DateTime(2026, 10, 14, 12);
  return Order(
    id: 'o-$miles',
    customerId: 'c',
    pickupLocation: 'Student Union · Grill',
    dropoffLocation: 'Library',
    distanceMiles: miles,
    deliveryFeeCents: payCents,
    tipCents: 0,
    status: OrderStatus.requested,
    pawPointsOrderNumber: 'PP-1',
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  test('pay per mile divides total pay by distance', () {
    expect(_order(0.4, 400).payPerMileCents, 1000);
    expect(_order(0.7, 550).payPerMileCents, 786);
    // Tiny trips count as 0.1 mi instead of dividing by almost zero.
    expect(_order(0.02, 300).payPerMileCents, 3000);
  });

  test('Best \$/mi sorts the highest rate first', () async {
    final requests = await MockCourierService(latency: Duration.zero)
        .fetchAvailableRequests();

    final sorted = applyRequestFilters(requests, sort: RequestSort.bestPerMile);

    // Subway $4.50 / 0.3 mi = $15/mi beats Grill $4.00 / 0.4 mi = $10/mi.
    expect(sorted.first.pickupLocation, contains('Subway'));
    expect(sorted[1].pickupLocation, contains('Grill'));
    expect(sorted.last.pickupLocation, contains('Chick-fil-A'));
  });

  testWidgets('cards show pay per mile and the sort chip works', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvailableTab(
            service: MockCourierService(latency: Duration.zero),
            courierId: 'courier-a',
            refreshEvery: null,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(r'$10.00/mi'), findsOneWidget); // Grill

    await tester.tap(find.text(r'Best $/mi'));
    await tester.pump();

    final subway = tester.getTopLeft(find.text('Student Union · Subway')).dy;
    final grill = tester.getTopLeft(find.text('Student Union · Grill')).dy;
    expect(subway, lessThan(grill));
  });
}
