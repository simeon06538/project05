import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/screens/courier/request_filters.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Future<MockCourierService> _pumpTab(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final service = MockCourierService(latency: Duration.zero);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AvailableTab(
          service: service,
          courierId: 'courier-a',
          refreshEvery: null,
        ),
      ),
    ),
  );
  await tester.pump();
  return service;
}

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pump();
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  test('restaurantOf takes the part after the building', () async {
    final requests = await MockCourierService(latency: Duration.zero)
        .fetchAvailableRequests();

    expect(restaurantOf(requests.first), 'Grill');
    expect(restaurantCounts(requests).keys, [
      'Chick-fil-A',
      'Grill',
      'Panda Express',
      'Starbucks',
      'Subway',
    ]);
  });

  test('counts add up when a restaurant has several requests', () async {
    final service = MockCourierService(latency: Duration.zero)
      ..addDemoRequest() // Taco Bell
      ..addDemoRequest(); // Grill again
    final counts = restaurantCounts(await service.fetchAvailableRequests());

    expect(counts['Grill'], 2);
    expect(counts['Taco Bell'], 1);
  });

  testWidgets('a restaurant chip filters the list', (tester) async {
    await _pumpTab(tester);

    await _tapChip(tester, 'Starbucks · 1');

    expect(find.text('1 of 5 open requests'), findsOneWidget);
    expect(find.text('Bookstore · Starbucks'), findsOneWidget);
  });

  testWidgets('tapping it again, or All, shows everything', (tester) async {
    await _pumpTab(tester);
    await _tapChip(tester, 'Starbucks · 1');

    await _tapChip(tester, 'Starbucks · 1');
    expect(find.text('5 open requests'), findsOneWidget);

    await _tapChip(tester, 'Subway · 1');
    await _tapChip(tester, 'All');
    expect(find.text('5 open requests'), findsOneWidget);
  });

  testWidgets('combines with the tip filter and explains an empty result', (
    tester,
  ) async {
    await _pumpTab(tester);
    // Chick-fil-A is the only request without a tip.
    await _tapChip(tester, 'Chick-fil-A · 1');
    await _tapChip(tester, 'With tip');

    expect(
      find.text('No requests from Chick-fil-A right now.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Show all'));
    await tester.pump();
    expect(find.text('5 open requests'), findsOneWidget);
  });
}
