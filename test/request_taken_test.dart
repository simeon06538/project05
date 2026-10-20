import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/services/courier_service.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

const _courier = 'courier-a';

/// A mock where every request vanishes (e.g. the customer cancelled)
/// before it can be accepted.
class _CancelledService extends MockCourierService {
  _CancelledService() : super(latency: Duration.zero);

  @override
  Future<Order> acceptRequest(String orderId, String courierId) async =>
      throw OrderNotFoundException(orderId);
}

/// Opens the first request's detail screen and taps Accept, then Accept
/// again in the confirm dialog. [beforeAccept] runs while the detail
/// screen is open, e.g. to let another courier take the order.
Future<Order> _acceptFirst(
  WidgetTester tester,
  MockCourierService service, {
  void Function(Order order)? beforeAccept,
}) async {
  final order = (await service.fetchAvailableRequests()).first;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AvailableTab(
          service: service,
          courierId: _courier,
          refreshEvery: null,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text(order.pickupLocation));
  await tester.pumpAndSettle();

  beforeAccept?.call(order);
  await tester.tap(find.textContaining('Accept delivery'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Accept'));
  await tester.pumpAndSettle();
  return order;
}

void main() {
  testWidgets('explains when another courier accepted first', (tester) async {
    final service = MockCourierService(latency: Duration.zero);
    await _acceptFirst(
      tester,
      service,
      beforeAccept: (order) => service.takeByOtherCourier(order.id),
    );

    expect(find.text('Someone got there first'), findsOneWidget);
    expect(find.textContaining('This request was already'), findsNothing);
  });

  testWidgets('"Back to requests" returns to a refreshed list', (tester) async {
    final service = MockCourierService(latency: Duration.zero);
    final order = await _acceptFirst(
      tester,
      service,
      beforeAccept: (order) => service.takeByOtherCourier(order.id),
    );

    await tester.tap(find.text('Back to requests'));
    await tester.pumpAndSettle();

    expect(find.text('Request details'), findsNothing);
    expect(find.text('4 open requests'), findsOneWidget);
    expect(find.text(order.pickupLocation), findsNothing);
    // The courier didn't end up with the order.
    expect(await service.fetchActiveDelivery(_courier), isNull);
  });

  testWidgets('explains when the request was cancelled', (tester) async {
    await _acceptFirst(tester, _CancelledService());

    expect(find.text('Request no longer available'), findsOneWidget);
    await tester.tap(find.text('Back to requests'));
    await tester.pumpAndSettle();
    expect(find.text('Request details'), findsNothing);
  });
}
