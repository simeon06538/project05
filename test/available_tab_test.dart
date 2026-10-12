import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/courier/available_tab.dart';
import 'package:campus_delivery/services/courier_service.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

/// Returns no open requests, to check the empty state.
class _EmptyService extends MockCourierService {
  _EmptyService() : super(latency: Duration.zero);

  @override
  Future<List<Order>> fetchAvailableRequests() async => [];
}

Future<void> _pumpTab(WidgetTester tester, CourierService service) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AvailableTab(service: service, courierId: 'courier-a'),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a card for each open request with pay and distance', (
    tester,
  ) async {
    final service = MockCourierService(latency: Duration.zero);
    final requests = await service.fetchAvailableRequests();
    await _pumpTab(tester, service);
    await tester.pump();

    expect(find.text('${requests.length} open requests'), findsOneWidget);
    final first = requests.first;
    expect(find.text(first.pickupLocation), findsOneWidget);
    expect(find.text(first.dropoffLocation), findsOneWidget);
    expect(find.text(formatCents(first.totalPayCents)), findsWidgets);
    expect(
      find.text('${first.distanceMiles.toStringAsFixed(1)} mi'),
      findsWidgets,
    );
  });

  testWidgets('shows the empty state when there are no requests', (
    tester,
  ) async {
    await _pumpTab(tester, _EmptyService());
    await tester.pump();

    expect(find.text('No requests right now'), findsOneWidget);
  });

  testWidgets('shows a spinner while loading', (tester) async {
    await _pumpTab(
      tester,
      MockCourierService(latency: const Duration(milliseconds: 400)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
