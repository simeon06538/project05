import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/request_card.dart';
import 'package:campus_delivery/theme/app_theme.dart';

Order _order({
  String pickup = 'Student Union · Grill',
  String dropoff = 'Library · Main entrance',
  double miles = 0.4,
  int fee = 300,
  int tip = 100,
}) {
  final created = DateTime(2026, 10, 13, 12);
  return Order(
    id: 'order-1',
    customerId: 'customer-1',
    pickupLocation: pickup,
    dropoffLocation: dropoff,
    distanceMiles: miles,
    deliveryFeeCents: fee,
    tipCents: tip,
    status: OrderStatus.requested,
    pawPointsOrderNumber: 'PP-4810',
    createdAt: created,
    updatedAt: created,
  );
}

Future<void> _pumpCard(
  WidgetTester tester,
  Order order, {
  VoidCallback? onTap,
  double width = 400,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: RequestCard(order: order, onTap: onTap),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows pickup, drop-off, distance and total pay', (tester) async {
    await _pumpCard(tester, _order());

    expect(find.text('Student Union · Grill'), findsOneWidget);
    expect(find.text('Library · Main entrance'), findsOneWidget);
    expect(find.text('0.4 mi'), findsOneWidget);
    expect(find.text(r'$4.00'), findsOneWidget);
    expect(find.text('total pay'), findsOneWidget);
  });

  testWidgets('shows the tip chip only when there is a tip', (tester) async {
    await _pumpCard(tester, _order(tip: 250));
    expect(find.text(r'$2.50 tip'), findsOneWidget);

    await _pumpCard(tester, _order(tip: 0));
    expect(find.textContaining('tip'), findsNothing);
  });

  testWidgets('distance is rounded to one decimal', (tester) async {
    await _pumpCard(tester, _order(miles: 1.25));

    expect(find.text('1.3 mi'), findsOneWidget);
  });

  testWidgets('tapping the card calls onTap', (tester) async {
    var taps = 0;
    await _pumpCard(tester, _order(), onTap: () => taps++);

    await tester.tap(find.text('Library · Main entrance'));
    expect(taps, 1);
  });

  testWidgets('long names and big text fit on a narrow phone', (tester) async {
    await _pumpCard(
      tester,
      _order(
        pickup: 'Student Union · Chick-fil-A (second floor food court)',
        dropoff: 'North Residence Hall · Building C · Room 418',
        miles: 1.4,
        fee: 500,
        tip: 1250,
      ),
      width: 320,
      textScale: 1.5,
    );

    // A RenderFlex overflow would be reported as an exception here.
    expect(tester.takeException(), isNull);
    expect(find.text(r'$17.50'), findsOneWidget);
  });
}
