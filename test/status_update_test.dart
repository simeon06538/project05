import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/my_deliveries_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

const _courier = 'courier-a';

/// Accepts the first open request and shows the My Deliveries tab.
Future<(MockCourierService, Order)> _pumpAccepted(WidgetTester tester) async {
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

Finder get _deliverButton => find.textContaining('Mark as delivered');

Future<void> _tapButton(WidgetTester tester, Finder finder) async {
  // The previous step's floating snackbar can sit over the button.
  ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(finder, 200);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an accepted delivery only offers "Mark as picked up"', (
    tester,
  ) async {
    await _pumpAccepted(tester);

    await tester.scrollUntilVisible(find.text('Mark as picked up'), 200);
    expect(find.text('Mark as picked up'), findsOneWidget);
    expect(_deliverButton, findsNothing);
  });

  testWidgets('picking up moves to the drop-off step', (tester) async {
    final (service, order) = await _pumpAccepted(tester);

    await _tapButton(tester, find.text('Mark as picked up'));

    expect(
      (await service.fetchActiveDelivery(_courier))?.status,
      OrderStatus.pickedUp,
    );
    expect(
      find.text('Mark as delivered · ${formatCents(order.totalPayCents)}'),
      findsOneWidget,
    );
    expect(find.text('Mark as picked up'), findsNothing);
    expect(find.textContaining('now head to'), findsOneWidget);
  });

  testWidgets('"Not yet" keeps the delivery active', (tester) async {
    final (service, _) = await _pumpAccepted(tester);
    await _tapButton(tester, find.text('Mark as picked up'));

    await _tapButton(tester, _deliverButton);
    expect(find.text('Mark as delivered?'), findsOneWidget);
    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();

    expect(find.text('Mark as delivered?'), findsNothing);
    expect(
      (await service.fetchActiveDelivery(_courier))?.status,
      OrderStatus.pickedUp,
    );
  });

  testWidgets('delivering pays the courier and clears the active delivery', (
    tester,
  ) async {
    final (service, order) = await _pumpAccepted(tester);
    await _tapButton(tester, find.text('Mark as picked up'));

    await _tapButton(tester, _deliverButton);
    await tester.tap(find.text('Yes, delivered'));
    // The empty state's Lottie loops forever, so don't wait to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('No active delivery'), findsOneWidget);
    expect(find.textContaining('added to your earnings'), findsOneWidget);
    expect(await service.fetchActiveDelivery(_courier), isNull);
    expect(
      (await service.fetchEarnings(_courier)).balanceCents,
      order.totalPayCents,
    );
  });
}
