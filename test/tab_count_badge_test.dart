import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';
import 'package:campus_delivery/widgets/glass_tab_bar.dart';

Finder _badgeOnTabBar(String text) =>
    find.descendant(of: find.byType(GlassTabBar), matching: find.text(text));

Future<MockCourierService> _pumpApp(WidgetTester tester) async {
  // A tall phone so the refresh button is on screen under the search box.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final service = MockCourierService(latency: Duration.zero);
  await tester.pumpWidget(
    CampusDeliveryApp(showWelcome: false, courierService: service),
  );
  await tester.pump();
  await tester.pump();
  return service;
}

void main() {
  testWidgets('tab bar shows a count badge and caps it at 99+', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassTabBar(
            labels: const ['Available', 'Earnings'],
            icons: const [Icons.list_alt_rounded, Icons.savings_outlined],
            badges: const [120, 0],
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(_badgeOnTabBar('99+'), findsOneWidget);
    expect(_badgeOnTabBar('0'), findsNothing);
    expect(find.bySemanticsLabel('Available tab, 120 open'), findsOneWidget);
  });

  testWidgets('Available tab shows how many requests are open', (tester) async {
    await _pumpApp(tester);

    expect(_badgeOnTabBar('5'), findsOneWidget);
  });

  testWidgets('the count follows new and accepted requests', (tester) async {
    final service = await _pumpApp(tester);

    service.addDemoRequest();
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();
    await tester.pump();
    expect(_badgeOnTabBar('6'), findsOneWidget);

    final first = (await service.fetchAvailableRequests()).first;
    await service.acceptRequest(first.id, demoCourierId);
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();
    await tester.pump();
    expect(_badgeOnTabBar('5'), findsOneWidget);
  });

  testWidgets('the badge hides while offline', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Online'));
    await tester.pump();

    expect(_badgeOnTabBar('5'), findsNothing);
  });
}
