import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

/// K-30: runs Flutter's built-in accessibility guidelines and a large-text
/// check on each courier screen.
Future<MockCourierService> _pumpApp(
  WidgetTester tester, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(1080, 2340); // a common phone
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final service = MockCourierService(latency: Duration.zero);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: CampusDeliveryApp(showWelcome: false, courierService: service),
    ),
  );
  await tester.pump();
  await tester.pump();
  return service;
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).first);
  await tester.pump();
  await tester.pump();
}

Future<void> _meetsGuidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  for (final tab in ['Available', 'My Deliveries', 'Earnings']) {
    testWidgets('$tab tab meets the accessibility guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      final service = await _pumpApp(tester);
      if (tab == 'My Deliveries') {
        final order = (await service.fetchAvailableRequests()).first;
        await service.acceptRequest(order.id, demoCourierId);
      }
      await _openTab(tester, tab);

      await _meetsGuidelines(tester);
      handle.dispose();
    });
  }

  testWidgets('request details meet the accessibility guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final service = await _pumpApp(tester);
    final order = (await service.fetchAvailableRequests()).first;
    await tester.tap(find.text(order.pickupLocation));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await _meetsGuidelines(tester);
    handle.dispose();
  });

  for (final tab in ['Available', 'My Deliveries', 'Earnings']) {
    testWidgets('$tab tab works at 2x text size', (tester) async {
      final service = await _pumpApp(tester, textScale: 2);
      if (tab == 'My Deliveries') {
        final order = (await service.fetchAvailableRequests()).first;
        await service.acceptRequest(order.id, demoCourierId);
        await service.updateStatus(order.id, OrderStatus.pickedUp);
      }
      await _openTab(tester, tab);

      // Any RenderFlex overflow would surface here.
      expect(tester.takeException(), isNull);
    });
  }
}
