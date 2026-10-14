import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/screens/courier/courier_header.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

void main() {
  test('initials use the first letters of up to two words', () {
    expect(initialsFor('Alex Morgan'), 'AM');
    expect(initialsFor('maria de la cruz'), 'MD');
    expect(initialsFor('Cher'), 'C');
    expect(initialsFor('  '), '?');
  });

  test('greeting follows the time of day', () {
    expect(greetingFor(DateTime(2026, 10, 13, 8)), 'Good morning');
    expect(greetingFor(DateTime(2026, 10, 13, 12)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 10, 13, 16, 59)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 10, 13, 17)), 'Good evening');
  });

  testWidgets('header shows avatar initials, greeting and name', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourierHeader(
            name: 'Alex Morgan',
            now: DateTime(2026, 10, 13, 9),
          ),
        ),
      ),
    );

    expect(find.text('AM'), findsOneWidget);
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('Courier'), findsOneWidget);
  });

  testWidgets('home screen shows the demo courier header', (tester) async {
    await tester.pumpWidget(
      CampusDeliveryApp(
        courierService: MockCourierService(latency: Duration.zero),
      ),
    );
    await tester.pump();

    expect(find.text(demoCourierName), findsOneWidget);
  });
}
