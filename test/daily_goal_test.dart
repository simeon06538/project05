import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/screens/courier/settings_screen.dart';
import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/daily_goal_ring.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Future<void> _pumpRing(WidgetTester tester, int earned, int goal) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyGoalRing(earnedTodayCents: earned, goalCents: goal),
        ),
      ),
    );

void main() {
  testWidgets('shows progress and what is left', (tester) async {
    await _pumpRing(tester, 500, 2000);

    expect(find.text('25%'), findsOneWidget);
    expect(find.text(r'$5.00 of $20.00'), findsOneWidget);
    expect(find.text(r'$15.00 to go'), findsOneWidget);
    expect(
      find.bySemanticsLabel(r"Today's goal, $5.00 of $20.00, 25 percent"),
      findsOneWidget,
    );
  });

  testWidgets('caps at 100% once the goal is reached', (tester) async {
    await _pumpRing(tester, 2600, 2000);

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Goal reached - nice work!'), findsOneWidget);
  });

  testWidgets('a goal picked in Settings shows on Earnings with today\'s pay', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first; // $4.00
    await service.acceptRequest(order.id, demoCourierId);
    await service.updateStatus(order.id, OrderStatus.pickedUp);
    await service.updateStatus(order.id, OrderStatus.delivered);
    await tester.pumpWidget(CampusDeliveryApp(courierService: service));
    await tester.pump();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.scrollUntilVisible(
      find.text(r'$40.00'),
      200,
      // Settings' own list, not the home screen underneath it.
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text(r'$40.00'));
    await tester.pump();
    await tester.tap(find.text(r'$40.00'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Earnings').first);
    await tester.pump();
    await tester.pump();

    expect(find.text(r'$4.00 of $40.00'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
  });
}
