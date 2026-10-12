import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

void main() {
  testWidgets('Courier home shows three tabs and switches between them', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      CampusDeliveryApp(
        courierService: MockCourierService(latency: Duration.zero),
      ),
    );
    await tester.pump();

    expect(find.text('Available'), findsOneWidget);
    expect(find.text('My Deliveries'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('Available requests'), findsOneWidget);

    await tester.tap(find.text('My Deliveries'));
    await tester.pump();
    expect(find.text('No active delivery'), findsOneWidget);

    await tester.tap(find.text('Earnings'));
    await tester.pump();
    expect(find.text('Demo balance'), findsOneWidget);
  });
}
