import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/completed_delivery_screen.dart';
import 'package:campus_delivery/screens/courier/customer_rating.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

Future<Order> _deliverFirst(MockCourierService service) async {
  final order = (await service.fetchAvailableRequests()).first;
  await service.acceptRequest(order.id, 'courier-a');
  await service.updateStatus(order.id, OrderStatus.pickedUp);
  return service.updateStatus(order.id, OrderStatus.delivered);
}

void main() {
  test('the mock rates a delivery only once it is delivered', () async {
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;
    final accepted = await service.acceptRequest(order.id, 'courier-a');
    expect(accepted.customerRating, isNull);

    final delivered = await _deliverFirst(
      MockCourierService(latency: Duration.zero),
    );
    expect(delivered.customerRating, inInclusiveRange(4, 5));
  });

  test('the same order always gets the same rating', () async {
    final a = await _deliverFirst(MockCourierService(latency: Duration.zero));
    final b = await _deliverFirst(MockCourierService(latency: Duration.zero));

    expect(a.customerRating, b.customerRating);
    expect(a.customerNote, b.customerNote);
  });

  testWidgets('stars and note are shown and announced', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomerRatingPanel(rating: 4, note: 'Still hot - thank you!'),
        ),
      ),
    );

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    expect(find.text('"Still hot - thank you!"'), findsOneWidget);
    expect(find.bySemanticsLabel('Rated 4 out of 5 stars'), findsOneWidget);
  });

  testWidgets('the delivery summary includes the rating', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final delivered = await _deliverFirst(
      MockCourierService(latency: Duration.zero),
    );

    await tester.pumpWidget(
      MaterialApp(home: CompletedDeliveryScreen(order: delivered)),
    );

    expect(find.text('Customer rating'), findsOneWidget);
    expect(find.text('${delivered.customerRating}.0'), findsOneWidget);
  });
}
