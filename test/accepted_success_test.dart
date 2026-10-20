import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

/// The full app keeps refreshing in the background, so wait a fixed time
/// for route changes and the success animation instead of pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 800));
  }
}

/// Accepts the first request through the full app and stops on the
/// success dialog.
Future<Order> _acceptFirst(
  WidgetTester tester,
  MockCourierService service,
) async {
  final order = (await service.fetchAvailableRequests()).first;
  await tester.pumpWidget(CampusDeliveryApp(courierService: service));
  await tester.pump();
  // The header, chips and badge push the first card below the small test
  // screen's fold.
  await tester.scrollUntilVisible(
    find.text(order.pickupLocation),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text(order.pickupLocation));
  await _settle(tester);
  await tester.tap(find.text(order.pickupLocation));
  await _settle(tester);
  await tester.tap(find.textContaining('Accept delivery'));
  await _settle(tester);
  await tester.tap(find.text('Accept'));
  await _settle(tester);
  return order;
}

void main() {
  testWidgets('accepting shows the success animation and next step', (
    tester,
  ) async {
    final order = await _acceptFirst(
      tester,
      MockCourierService(latency: Duration.zero),
    );

    expect(find.text('Delivery accepted!'), findsOneWidget);
    expect(find.byType(LottieBuilder), findsOneWidget);
    expect(
      find.textContaining('Head to ${order.pickupLocation}'),
      findsOneWidget,
    );
    expect(find.textContaining(formatCents(order.totalPayCents)), findsWidgets);
  });

  testWidgets('"Start delivery" opens My Deliveries on the new job', (
    tester,
  ) async {
    final order = await _acceptFirst(
      tester,
      MockCourierService(latency: Duration.zero),
    );

    await tester.tap(find.text('Start delivery'));
    await _settle(tester);

    expect(find.text('Delivery accepted!'), findsNothing);
    expect(find.text('Pick up at ${order.pickupLocation}'), findsOneWidget);
  });
}
