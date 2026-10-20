// K-48: screenshot tests for the main courier screens. If a change to the
// UI is intended, regenerate with:
//   flutter test --update-goldens --tags golden
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/achievements.dart';
import 'package:campus_delivery/screens/courier/completed_delivery_screen.dart';
import 'package:campus_delivery/screens/courier/daily_goal_ring.dart';
import 'package:campus_delivery/screens/courier/earnings_stats.dart';
import 'package:campus_delivery/screens/courier/request_card.dart';
import 'package:campus_delivery/screens/courier/request_detail_screen.dart';
import 'package:campus_delivery/screens/courier/weekly_earnings_chart.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';
import 'package:campus_delivery/theme/app_theme.dart';
import 'package:campus_delivery/widgets/app_background.dart';

// Everything uses this fixed clock so the images never change by date.
final _now = DateTime(2026, 10, 14, 15, 0);

Order _order({
  OrderStatus status = OrderStatus.requested,
  int minutesAgo = 12,
  int tip = 100,
}) {
  final created = _now.subtract(Duration(minutes: minutesAgo));
  final delivered = status == OrderStatus.delivered;
  return Order(
    id: 'order-1',
    customerId: 'customer-1',
    courierId: delivered ? 'courier-a' : null,
    pickupLocation: 'Student Union · Grill',
    dropoffLocation: 'Library · Main entrance',
    distanceMiles: 0.4,
    deliveryFeeCents: 300,
    tipCents: tip,
    status: status,
    pawPointsOrderNumber: 'PP-4810',
    createdAt: created,
    updatedAt: created,
    acceptedAt: delivered ? created.add(const Duration(minutes: 2)) : null,
    pickedUpAt: delivered ? created.add(const Duration(minutes: 9)) : null,
    deliveredAt: delivered ? created.add(const Duration(minutes: 18)) : null,
    dropoffNote: delivered ? 'Left with the front desk' : null,
    customerRating: delivered ? 5 : null,
    customerNote: delivered ? 'Still hot - thank you!' : null,
  );
}

/// A phone-sized frame with the app theme and background.
Future<void> _pumpPhone(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: child,
    ),
  );
  await tester.pump();
}

Widget _onBackground(Widget child) => Scaffold(
  body: AppBackground(
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  ),
);

void main() {
  testWidgets('request card', (tester) async {
    await _pumpPhone(
      tester,
      _onBackground(
        Column(
          children: [
            RequestCard(order: _order(minutesAgo: 1), now: _now),
            const SizedBox(height: 12),
            RequestCard(order: _order(minutesAgo: 20, tip: 0), now: _now),
          ],
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('request_cards.png'),
    );
  });

  testWidgets('request details', (tester) async {
    await _pumpPhone(
      tester,
      RequestDetailScreen(
        order: _order(),
        service: MockCourierService(latency: Duration.zero),
        courierId: 'courier-a',
        now: _now,
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('request_details.png'),
    );
  });

  testWidgets('delivery summary', (tester) async {
    await _pumpPhone(
      tester,
      CompletedDeliveryScreen(
        order: _order(status: OrderStatus.delivered),
        now: _now,
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('delivery_summary.png'),
    );
  });

  testWidgets('earnings widgets', (tester) async {
    final week = [
      for (var day = 0; day < 6; day++)
        Order(
          id: 'h$day',
          customerId: 'c',
          courierId: 'courier-a',
          pickupLocation: 'Student Union · Starbucks',
          dropoffLocation: 'Rec Center',
          distanceMiles: 0.3 + day * 0.2,
          deliveryFeeCents: 300 + day * 50,
          tipCents: day.isEven ? 200 : 0,
          status: OrderStatus.delivered,
          pawPointsOrderNumber: 'PP-$day',
          createdAt: _now.subtract(Duration(days: day, hours: 1)),
          updatedAt: _now.subtract(Duration(days: day, hours: 1)),
          deliveredAt: _now.subtract(Duration(days: day, hours: 1)),
        ),
    ];
    await _pumpPhone(
      tester,
      _onBackground(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DailyGoalRing(earnedTodayCents: 500, goalCents: 2000),
            const SizedBox(height: 12),
            WeeklyEarningsChart(completed: week, now: _now),
            const SizedBox(height: 12),
            EarningsStatsRow(stats: EarningsStats.from(week)),
            const SizedBox(height: 12),
            AchievementsPanel(achievements: achievementsFor(week)),
          ],
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('earnings_widgets.png'),
    );
  });
}
