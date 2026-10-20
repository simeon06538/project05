import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/order_widgets.dart';
import 'package:campus_delivery/screens/courier/request_card.dart';

final _now = DateTime(2026, 10, 14, 12);

Order _orderAged(Duration age) => Order(
  id: 'order-1',
  customerId: 'customer-1',
  pickupLocation: 'Student Union · Grill',
  dropoffLocation: 'Library · Main entrance',
  distanceMiles: 0.4,
  deliveryFeeCents: 300,
  tipCents: 0,
  status: OrderStatus.requested,
  pawPointsOrderNumber: 'PP-4810',
  createdAt: _now.subtract(age),
  updatedAt: _now.subtract(age),
);

Future<void> _pumpCard(WidgetTester tester, Duration age) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: RequestCard(order: _orderAged(age), now: _now),
    ),
  ),
);

void main() {
  test('requests under 2 minutes old are new', () {
    expect(
      requestAge(_orderAged(const Duration(seconds: 30)), now: _now),
      RequestAge.fresh,
    );
    expect(
      requestAge(_orderAged(const Duration(minutes: 2)), now: _now),
      RequestAge.normal,
    );
  });

  test('requests over 15 minutes old are waiting', () {
    expect(
      requestAge(_orderAged(const Duration(minutes: 15)), now: _now),
      RequestAge.normal,
    );
    expect(
      requestAge(_orderAged(const Duration(minutes: 16)), now: _now),
      RequestAge.waiting,
    );
  });

  testWidgets('card shows a New badge for a fresh request', (tester) async {
    await _pumpCard(tester, const Duration(minutes: 1));

    expect(find.text('New'), findsOneWidget);
    expect(find.text('Waiting a while'), findsNothing);
  });

  testWidgets('card shows Waiting a while for an old request', (tester) async {
    await _pumpCard(tester, const Duration(minutes: 20));

    expect(find.text('Waiting a while'), findsOneWidget);
    expect(find.text('New'), findsNothing);
  });

  testWidgets('card shows no badge in between', (tester) async {
    await _pumpCard(tester, const Duration(minutes: 8));

    expect(find.text('New'), findsNothing);
    expect(find.text('Waiting a while'), findsNothing);
  });
}
