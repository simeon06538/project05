import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/my_deliveries_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

const _courier = 'courier-a';

Future<(MockCourierService, Order)> _pumpAccepted(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final service = MockCourierService(latency: Duration.zero);
  final order = (await service.fetchAvailableRequests()).first;
  await service.acceptRequest(order.id, _courier);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MyDeliveriesTab(service: service, courierId: _courier),
      ),
    ),
  );
  await tester.pump();
  return (service, order);
}

FilledButton _pickupButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.ancestor(
    of: find.text('Mark as picked up'),
    matching: find.byType(FilledButton),
  ),
);

void main() {
  testWidgets('pickup stays disabled until both checks are ticked', (
    tester,
  ) async {
    final (_, order) = await _pumpAccepted(tester);

    expect(
      find.text('Order number matches ${order.pawPointsOrderNumber}'),
      findsOneWidget,
    );
    expect(_pickupButton(tester).onPressed, isNull);

    await tester.tap(find.text('Food is sealed and complete'));
    await tester.pump();
    expect(_pickupButton(tester).onPressed, isNull);

    await tester.tap(
      find.text('Order number matches ${order.pawPointsOrderNumber}'),
    );
    await tester.pump();
    expect(_pickupButton(tester).onPressed, isNotNull);
    expect(
      find.text('Tick both to mark the order as picked up.'),
      findsNothing,
    );
  });

  testWidgets('unticking a check disables pickup again', (tester) async {
    await _pumpAccepted(tester);
    final boxes = find.byType(Checkbox);
    await tester.tap(boxes.at(0));
    await tester.tap(boxes.at(1));
    await tester.pump();

    await tester.tap(boxes.at(1));
    await tester.pump();

    expect(_pickupButton(tester).onPressed, isNull);
  });

  testWidgets('the checklist is gone after pickup', (tester) async {
    final (_, _) = await _pumpAccepted(tester);
    final boxes = find.byType(Checkbox);
    await tester.tap(boxes.at(0));
    await tester.tap(boxes.at(1));
    await tester.pump();

    await tester.tap(find.text('Mark as picked up'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Before pickup'), findsNothing);
    expect(find.textContaining('Mark as delivered'), findsOneWidget);
  });
}
