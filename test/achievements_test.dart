import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/achievements.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Map<String, bool> _unlocked(List<Order> completed) => {
  for (final a in achievementsFor(completed)) a.title: a.unlocked,
};

void main() {
  test('nothing is unlocked before the first delivery', () {
    expect(_unlocked(const []).values, everyElement(isFalse));
  });

  test('the demo history unlocks the right badges', () async {
    // 8 deliveries, $40.50 total, a $3.00 tip and trips over a mile.
    final service = MockCourierService(latency: Duration.zero)
      ..seedHistory('courier-a');
    final completed = (await service.fetchEarnings('courier-a'))
        .completedDeliveries;

    expect(_unlocked(completed), {
      'First delivery': true,
      '5 deliveries': true,
      '10 deliveries': false,
      r'$50 earned': false,
      'Big tip': true,
      'Long haul': true,
    });
  });

  testWidgets('panel counts unlocked badges and explains locked ones', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero)
      ..seedHistory('courier-a');
    final completed = (await service.fetchEarnings('courier-a'))
        .completedDeliveries;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AchievementsPanel(achievements: achievementsFor(completed)),
          ),
        ),
      ),
    );

    expect(find.text('Achievements · 4 of 6'), findsOneWidget);
    expect(find.text('8 of 10 done'), findsOneWidget);
    expect(find.text(r'$40.50 of $50.00'), findsOneWidget);
    expect(find.bySemanticsLabel('First delivery, unlocked'), findsOneWidget);
    expect(
      find.bySemanticsLabel('10 deliveries, locked. 8 of 10 done'),
      findsOneWidget,
    );
  });
}
