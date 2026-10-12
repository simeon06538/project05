import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

const _courier = 'courier-a';

Future<Order> _openFirstRequest(
  WidgetTester tester,
  MockCourierService service,
) async {
  final first = (await service.fetchAvailableRequests()).first;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AvailableTab(service: service, courierId: _courier),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text(first.pickupLocation));
  await tester.pumpAndSettle();
  return first;
}

Finder get _acceptButton => find.textContaining('Accept delivery');

void main() {
  testWidgets('detail screen shows Accept button with the total pay', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero);
    final order = await _openFirstRequest(tester, service);

    expect(
      find.text('Accept delivery · ${formatCents(order.totalPayCents)}'),
      findsOneWidget,
    );
  });

  testWidgets('"Not now" closes the dialog without accepting', (tester) async {
    final service = MockCourierService(latency: Duration.zero);
    await _openFirstRequest(tester, service);

    await tester.tap(_acceptButton);
    await tester.pumpAndSettle();
    expect(find.text('Accept this delivery?'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Accept this delivery?'), findsNothing);
    expect(find.text('Request details'), findsOneWidget);
    expect(await service.fetchActiveDelivery(_courier), isNull);
  });

  testWidgets('confirming accepts, returns to the list and refreshes it', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero);
    final order = await _openFirstRequest(tester, service);

    await tester.tap(_acceptButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(find.text('Request details'), findsNothing);
    expect(find.text('4 open requests'), findsOneWidget);
    expect(find.textContaining('Delivery accepted'), findsOneWidget);
    expect((await service.fetchActiveDelivery(_courier))?.id, order.id);
  });

  testWidgets('if a delivery was accepted elsewhere, shows why and locks', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero);
    await _openFirstRequest(tester, service);
    // Meanwhile the same courier accepts a different order (e.g. on
    // another device), so this accept will be refused.
    final requests = await service.fetchAvailableRequests();
    await service.acceptRequest(requests.last.id, _courier);

    await tester.tap(_acceptButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(find.text('Request details'), findsOneWidget);
    expect(
      find.text('Finish your current delivery before accepting another.'),
      findsOneWidget,
    );
    expect(find.text('Finish your current delivery first'), findsOneWidget);
  });
}
