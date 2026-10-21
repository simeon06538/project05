import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/screens/courier/distance_filter.dart';
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

/// Moves the slider as if dragged to [value] (1.75 = Any).
Future<void> _slideTo(WidgetTester tester, double value) async {
  tester.widget<Slider>(find.byType(Slider)).onChanged!(value);
  await tester.pump();
}

void main() {
  test('miles are shown without trailing zeros', () {
    expect(formatMiles(0.25), '0.25');
    expect(formatMiles(0.5), '0.5');
    expect(formatMiles(1.0), '1');
  });

  test('maxMiles keeps requests at or under the limit', () async {
    // Seed distances: 0.4, 0.7, 1.1, 0.9 and 0.3 mi.
    final requests = await MockCourierService(latency: Duration.zero)
        .fetchAvailableRequests();

    expect(applyRequestFilters(requests, maxMiles: 0.5), hasLength(2));
    expect(applyRequestFilters(requests, maxMiles: 0.7), hasLength(3));
    expect(applyRequestFilters(requests, maxMiles: null), hasLength(5));
  });

  testWidgets('starts at Any distance', (tester) async {
    await _pumpTab(tester);

    expect(find.text('Any distance'), findsOneWidget);
    expect(find.text('5 open requests'), findsOneWidget);
  });

  testWidgets('sliding down hides farther requests', (tester) async {
    await _pumpTab(tester);

    await _slideTo(tester, 0.5);

    expect(find.text('Within 0.5 mi'), findsOneWidget);
    expect(find.text('2 of 5 open requests'), findsOneWidget);

    await _slideTo(tester, 1.75);
    expect(find.text('Any distance'), findsOneWidget);
    expect(find.text('5 open requests'), findsOneWidget);
  });

  testWidgets('nothing that close explains why and Show all resets', (
    tester,
  ) async {
    await _pumpTab(tester);

    await _slideTo(tester, 0.25);
    expect(find.text('No requests within 0.25 mi right now.'), findsOneWidget);

    await tester.tap(find.text('Show all'));
    await tester.pump();
    expect(find.text('Any distance'), findsOneWidget);
  });
}
