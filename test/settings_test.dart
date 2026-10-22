import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/settings_screen.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

/// Full app on a tall phone so Settings and the tabs fit without scrolling.
Future<MockCourierService> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final service = MockCourierService(latency: Duration.zero);
  await tester.pumpWidget(
    CampusDeliveryApp(showWelcome: false, courierService: service),
  );
  await tester.pump();
  await tester.pump();
  return service;
}

/// Route changes and dialogs, without waiting on looping animations.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await _settle(tester);
}

void main() {
  test(
    'resetDemo restores the starting requests and clears earnings',
    () async {
      final service = MockCourierService(latency: Duration.zero);
      final order = (await service.fetchAvailableRequests()).first;
      await service.acceptRequest(order.id, 'courier-a');
      await service.updateStatus(order.id, OrderStatus.pickedUp);
      await service.updateStatus(order.id, OrderStatus.delivered);
      service.addDemoRequest();

      service.resetDemo();

      expect(await service.fetchAvailableRequests(), hasLength(5));
      expect(await service.fetchActiveDelivery('courier-a'), isNull);
      expect((await service.fetchEarnings('courier-a')).balanceCents, 0);
    },
  );

  test('resetDemo can bring back the demo history', () async {
    final service = MockCourierService(latency: Duration.zero)
      ..resetDemo(withHistoryFor: 'courier-a');

    expect(
      (await service.fetchEarnings('courier-a')).completedDeliveries,
      hasLength(8),
    );
  });

  testWidgets('Save is disabled until the name actually changes', (
    tester,
  ) async {
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          name: 'Alex Morgan',
          onNameChanged: (name) => saved = name,
        ),
      ),
    );

    FilledButton saveButton() =>
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(saveButton().onPressed, isNull);
    expect(find.text('Enter a name customers will see'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  Sam Lee ');
    await tester.pump();
    await tester.tap(find.text('Save name'));
    await tester.pump();
    expect(saved, 'Sam Lee');
    // No reset option without a demo service.
    expect(find.text('Reset demo data'), findsNothing);
  });

  testWidgets('a new name shows in the header after going back', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openSettings(tester);

    await tester.enterText(find.byType(TextField), 'Sam Lee');
    await tester.pump();
    await tester.tap(find.text('Save name'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await _settle(tester);

    expect(find.text('Sam Lee'), findsOneWidget);
    expect(find.text('SL'), findsOneWidget);
  });

  testWidgets('Reset demo data brings back the original requests', (
    tester,
  ) async {
    final service = await _pumpApp(tester);
    final order = (await service.fetchAvailableRequests()).first;
    await service.acceptRequest(order.id, demoCourierId);

    await _openSettings(tester);
    // Below the Daily goal section (K-41).
    await tester.scrollUntilVisible(
      find.text('Reset demo data'),
      200,
      // Settings' own list, not the home screen underneath it.
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Reset demo data'));
    await tester.pump();
    await tester.tap(find.text('Reset demo data'));
    await _settle(tester);
    await tester.tap(find.text('Reset'));
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await _settle(tester);

    expect(await service.fetchActiveDelivery(demoCourierId), isNull);
    expect(find.text('5 open requests'), findsOneWidget);
    expect(find.text('Delivery in progress'), findsNothing);
  });
}
