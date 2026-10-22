import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void phoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('requires a name and opens customer mode without a password', (
    tester,
  ) async {
    phoneSize(tester);
    await tester.pumpWidget(
      CampusDeliveryApp(
        courierService: MockCourierService(latency: Duration.zero),
      ),
    );
    expect(find.text('Welcome to Campus Delivery'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter your name to continue'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '  Taylor  ');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Welcome, Taylor'), findsOneWidget);
    expect(find.text('Customer mode'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('switches both ways while preserving name and courier delivery', (
    tester,
  ) async {
    phoneSize(tester);
    final service = MockCourierService(latency: Duration.zero);
    final requests = await service.fetchAvailableRequests();
    await service.acceptRequest(requests.first.id, demoCourierId);
    await tester.pumpWidget(CampusDeliveryApp(courierService: service));
    await tester.enterText(find.byType(TextFormField), 'Taylor');
    await tester.tap(find.text('Courier'));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump();
    expect(find.text('My Deliveries'), findsOneWidget);
    expect(find.text('Taylor'), findsOneWidget);
    await tester.tap(find.text('Switch role'));
    await tester.pump();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Taylor',
    );
    await tester.tap(find.text('Customer'));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Customer mode'), findsOneWidget);
    expect(
      (await service.fetchActiveDelivery(demoCourierId))!.id,
      requests.first.id,
    );
    await tester.tap(find.text('Switch role'));
    await tester.pump();
    await tester.tap(find.text('Courier'));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump();
    expect(find.text('My Deliveries'), findsOneWidget);
    expect(
      (await service.fetchActiveDelivery(demoCourierId))!.id,
      requests.first.id,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
