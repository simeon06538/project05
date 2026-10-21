import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

const _courier = 'courier-a';

/// A mock service where [courierId] already has an active delivery.
Future<MockCourierService> _busyService([String courierId = _courier]) async {
  final service = MockCourierService(latency: Duration.zero);
  final requests = await service.fetchAvailableRequests();
  await service.acceptRequest(requests.first.id, courierId);
  return service;
}

void main() {
  testWidgets('no banner when the courier is free', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvailableTab(
            service: MockCourierService(latency: Duration.zero),
            courierId: _courier,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Delivery in progress'), findsNothing);
  });

  testWidgets('banner shows the active delivery route', (tester) async {
    final service = await _busyService();
    final active = (await service.fetchActiveDelivery(_courier))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvailableTab(service: service, courierId: _courier),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Delivery in progress'), findsOneWidget);
    expect(
      find.text('${active.pickupLocation} to ${active.dropoffLocation}'),
      findsOneWidget,
    );
  });

  testWidgets('accept button is locked while a delivery is active', (
    tester,
  ) async {
    final service = await _busyService();
    final open = (await service.fetchAvailableRequests()).first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvailableTab(service: service, courierId: _courier),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text(open.pickupLocation));
    await tester.pumpAndSettle();

    expect(find.text('Finish your current delivery first'), findsOneWidget);
    await tester.tap(find.text('Finish your current delivery first'));
    await tester.pumpAndSettle();
    expect(find.text('Accept this delivery?'), findsNothing);
  });

  testWidgets('"View" on the banner switches to My Deliveries', (tester) async {
    await tester.pumpWidget(
      CampusDeliveryApp(
        showWelcome: false,
        courierService: await _busyService(demoCourierId),
      ),
    );
    await tester.pump();
    expect(find.text('Delivery in progress'), findsOneWidget);

    await tester.tap(find.text('View'));
    await tester.pump();
    expect(find.text('My deliveries'), findsOneWidget);
    expect(find.text('Available requests'), findsNothing);
  });
}
