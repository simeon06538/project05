import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/screens/courier/request_filters.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Future<void> _pumpTab(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1800);
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
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

void main() {
  test('query matches pickup or drop-off, ignoring case', () async {
    final requests = await MockCourierService(latency: Duration.zero)
        .fetchAvailableRequests();

    final starbucks = applyRequestFilters(requests, query: 'STARBUCKS');
    expect(starbucks.single.pickupLocation, contains('Starbucks'));

    final library = applyRequestFilters(requests, query: ' library ');
    expect(library.single.dropoffLocation, contains('Library'));

    expect(applyRequestFilters(requests, query: ''), hasLength(5));
    expect(applyRequestFilters(requests, query: 'zzz'), isEmpty);
  });

  testWidgets('typing filters the list and updates the count', (tester) async {
    await _pumpTab(tester);

    await _search(tester, 'panda');

    expect(find.text('1 of 5 open requests'), findsOneWidget);
    expect(find.text('Student Union · Panda Express'), findsOneWidget);
    expect(find.text('Student Union · Grill'), findsNothing);
  });

  testWidgets('Clear search brings every request back', (tester) async {
    await _pumpTab(tester);
    await _search(tester, 'panda');

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(find.text('5 open requests'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  testWidgets('no match explains why and Show all resets', (tester) async {
    await _pumpTab(tester);
    await _search(tester, 'pizza');

    expect(find.text('No requests match "pizza".'), findsOneWidget);
    await tester.tap(find.text('Show all'));
    await tester.pump();

    expect(find.text('5 open requests'), findsOneWidget);
  });
}
