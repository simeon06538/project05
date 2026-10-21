import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

/// Mock with only the requests that have no tip.
class _NoTipsService extends MockCourierService {
  _NoTipsService() : super(latency: Duration.zero);

  @override
  Future<List<Order>> fetchAvailableRequests() async => [
    for (final o in await super.fetchAvailableRequests())
      if (o.tipCents == 0) o,
  ];
}

Future<void> _pumpTab(WidgetTester tester, MockCourierService service) async {
  // A tall phone so several cards fit under the search and filter rows.
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AvailableTab(service: service, courierId: 'courier-a'),
      ),
    ),
  );
  await tester.pump();
}

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  // Seed data: Grill $4.00 0.4 mi, Starbucks $5.50 0.7 mi,
  // Chick-fil-A $4.50 1.1 mi (no tip), Panda Express $7.00 0.9 mi,
  // Subway $4.50 0.3 mi.
  const grill = 'Student Union · Grill';
  const starbucks = 'Bookstore · Starbucks';
  const panda = 'Student Union · Panda Express';
  const subway = 'Student Union · Subway';

  testWidgets('oldest first is selected by default', (tester) async {
    await _pumpTab(tester, MockCourierService(latency: Duration.zero));

    expect(
      tester.getSemantics(find.text('Oldest first')),
      isSemantics(isSelected: true),
    );
    expect(_top(tester, grill), lessThan(_top(tester, starbucks)));
  });

  testWidgets('chips sit side by side, not one per line', (tester) async {
    await _pumpTab(tester, MockCourierService(latency: Duration.zero));

    expect(_top(tester, 'Oldest first'), _top(tester, 'Highest pay'));
    expect(
      tester.getSize(find.text('Oldest first')).width,
      lessThan(tester.getSize(find.byType(ListView)).width / 2),
    );
  });

  testWidgets('Highest pay puts the best-paying request first', (tester) async {
    await _pumpTab(tester, MockCourierService(latency: Duration.zero));

    await tester.tap(find.text('Highest pay'));
    await tester.pump();

    expect(_top(tester, panda), lessThan(_top(tester, starbucks)));
  });

  testWidgets('Closest puts the nearest request first', (tester) async {
    await _pumpTab(tester, MockCourierService(latency: Duration.zero));

    await tester.tap(find.text('Closest'));
    await tester.pump();

    expect(_top(tester, subway), lessThan(_top(tester, grill)));
  });

  testWidgets('With tip hides untipped requests and updates the count', (
    tester,
  ) async {
    await _pumpTab(tester, MockCourierService(latency: Duration.zero));
    expect(find.text('5 open requests'), findsOneWidget);

    await tester.tap(find.text('With tip'));
    await tester.pump();
    expect(find.text('4 of 5 open requests'), findsOneWidget);

    await tester.tap(find.text('With tip'));
    await tester.pump();
    expect(find.text('5 open requests'), findsOneWidget);
  });

  testWidgets('"Show all" clears the tip filter when nothing matches', (
    tester,
  ) async {
    await _pumpTab(tester, _NoTipsService());

    await tester.tap(find.text('With tip'));
    await tester.pump();
    expect(find.text('No requests with a tip right now.'), findsOneWidget);

    await tester.tap(find.text('Show all'));
    await tester.pump();
    expect(find.text('No requests with a tip right now.'), findsNothing);
    expect(find.text('1 open request'), findsOneWidget);
  });
}
