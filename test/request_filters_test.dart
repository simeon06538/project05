import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/request_filters.dart';

final _start = DateTime(2026, 10, 12, 12);

Order _order(
  String id, {
  required int minute,
  int pay = 300,
  int tip = 0,
  double miles = 0.5,
}) {
  final created = _start.add(Duration(minutes: minute));
  return Order(
    id: id,
    customerId: 'c',
    pickupLocation: 'Pickup $id',
    dropoffLocation: 'Drop $id',
    distanceMiles: miles,
    deliveryFeeCents: pay,
    tipCents: tip,
    status: OrderStatus.requested,
    pawPointsOrderNumber: 'PP-$id',
    createdAt: created,
    updatedAt: created,
  );
}

List<String> _ids(List<Order> orders) => [for (final o in orders) o.id];

void main() {
  final a = _order('a', minute: 0, pay: 300, tip: 100, miles: 0.9);
  final b = _order('b', minute: 1, pay: 450, tip: 0, miles: 0.3);
  final c = _order('c', minute: 2, pay: 300, tip: 200, miles: 0.6);
  final d = _order('d', minute: 3, pay: 350, tip: 50, miles: 0.3);
  final requests = [c, a, d, b];

  test('oldest first is the default', () {
    expect(_ids(applyRequestFilters(requests)), ['a', 'b', 'c', 'd']);
  });

  test('highest pay sorts by fee + tip, oldest first on ties', () {
    // Totals: a 400, b 450, c 500, d 400.
    expect(_ids(applyRequestFilters(requests, sort: RequestSort.highestPay)), [
      'c',
      'b',
      'a',
      'd',
    ]);
  });

  test('closest sorts by distance, oldest first on ties', () {
    expect(_ids(applyRequestFilters(requests, sort: RequestSort.closest)), [
      'b',
      'd',
      'c',
      'a',
    ]);
  });

  test('tips only drops requests without a tip', () {
    expect(_ids(applyRequestFilters(requests, tipsOnly: true)), [
      'a',
      'c',
      'd',
    ]);
  });

  test('filters and sorting combine', () {
    expect(
      _ids(
        applyRequestFilters(
          requests,
          sort: RequestSort.closest,
          tipsOnly: true,
        ),
      ),
      ['d', 'c', 'a'],
    );
  });

  test('does not change the list it was given', () {
    applyRequestFilters(requests, sort: RequestSort.highestPay);
    expect(_ids(requests), ['c', 'a', 'd', 'b']);
  });
}
