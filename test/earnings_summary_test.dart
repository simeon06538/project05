import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/earnings_stats.dart';
import 'package:campus_delivery/screens/courier/earnings_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Order _delivered(String dropoff, int fee, int tip) {
  final at = DateTime(2026, 10, 14, 12);
  return Order(
    id: dropoff,
    customerId: 'c',
    courierId: 'courier-a',
    pickupLocation: 'Student Union · Grill',
    dropoffLocation: dropoff,
    distanceMiles: 0.5,
    deliveryFeeCents: fee,
    tipCents: tip,
    status: OrderStatus.delivered,
    pawPointsOrderNumber: 'PP-1',
    createdAt: at,
    updatedAt: at,
    deliveredAt: at,
  );
}

void main() {
  test('summary lists count, earnings, tips, average, best and balance', () {
    final text = earningsSummaryText(
      range: EarningsRange.week,
      inRange: [
        _delivered('Library', 300, 100),
        _delivered('Rec Center', 400, 300),
      ],
      balanceCents: 4050,
    );

    expect(
      text,
      'Campus Delivery earnings · This week\n'
      'Deliveries: 2\n'
      'Earned: \$11.00 (tips \$4.00)\n'
      'Average: \$5.50 per delivery\n'
      'Best: \$7.00 to Rec Center\n'
      'Demo balance: \$40.50',
    );
  });

  test('an empty range leaves out average and best', () {
    final text = earningsSummaryText(
      range: EarningsRange.today,
      inRange: const [],
      balanceCents: 0,
    );

    expect(text, isNot(contains('Average')));
    expect(text, isNot(contains('Best')));
    expect(text, contains('Deliveries: 0'));
  });

  testWidgets('Copy summary puts the text on the clipboard', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final service = MockCourierService(latency: Duration.zero)
      ..seedHistory('courier-a');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EarningsTab(service: service, courierId: 'courier-a'),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Copy summary'));
    await tester.pump();

    expect(copied, startsWith('Campus Delivery earnings · All time'));
    expect(copied, contains('Deliveries: 8'));
    expect(find.text('Earnings summary copied'), findsOneWidget);
  });
}
