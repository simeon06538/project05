import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';
import 'package:campus_delivery/services/mock_customer_order_service.dart';
import 'package:campus_delivery/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpFlow(WidgetTester tester) async {
  // Empty states loop their animation, so wait bounded frames rather than settle.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets(
    'confirm once, retain across roles, and permanently delete without archiving',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = MockCustomerOrderService(
        preferences: prefs,
        seedExamples: false,
      );
      const owner = 'demo-customer:taylor';
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        CampusDeliveryApp(
          courierService: MockCourierService(latency: Duration.zero),
          customerOrderService: service,
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Taylor');
      await tester.ensureVisible(find.text('Continue'));
      await pumpFlow(tester);
      await tester.tap(find.text('Continue'));
      await pumpFlow(tester);
      await tester.tap(find.text('Request a Delivery'));
      await pumpFlow(tester);
      final fields = find.byType(TextFormField);
      await tester.ensureVisible(fields.at(1));
      await pumpFlow(tester);
      await tester.enterText(fields.at(1), 'Sonic');
      await tester.ensureVisible(fields.at(2));
      await pumpFlow(tester);
      await tester.enterText(fields.at(2), 'PP-NEW');
      final dropoff = find.byType(DropdownButtonFormField<String>).last;
      await tester.ensureVisible(dropoff);
      await pumpFlow(tester);
      await tester.tap(dropoff);
      await pumpFlow(tester);
      await tester.tap(find.text('Middleton Library').last);
      await pumpFlow(tester);
      await tester.ensureVisible(find.text('Review request'));
      await pumpFlow(tester);
      await tester.tap(find.text('Review request'));
      await pumpFlow(tester);
      await tester.ensureVisible(find.text('Confirm demo request'));
      await pumpFlow(tester);
      final confirm = find.byType(PrimaryButton);
      final confirmAction = tester.widget<PrimaryButton>(confirm).onPressed!;
      confirmAction();
      confirmAction();
      await pumpFlow(tester);
      expect(find.text('Demo request saved'), findsOneWidget);
      expect((await service.fetchOrders(owner)).length, 1);
      await tester.tap(find.text('View deliveries'));
      await pumpFlow(tester);
      expect(find.text('Paw Points order: PP-NEW'), findsOneWidget);
      await tester.ensureVisible(find.text('Switch role'));
      await pumpFlow(tester);
      await tester.tap(find.text('Switch role'));
      await pumpFlow(tester);
      await tester.tap(find.text('Courier'));
      await tester.tap(find.text('Continue'));
      await pumpFlow(tester);
      await tester.tap(find.text('Switch role'));
      await pumpFlow(tester);
      await tester.tap(find.text('Customer'));
      await tester.tap(find.text('Continue'));
      await pumpFlow(tester);
      expect(find.text('Paw Points order: PP-NEW'), findsOneWidget);
      await tester.ensureVisible(find.text('Delete request'));
      await pumpFlow(tester);
      await tester.tap(find.text('Delete request'));
      await pumpFlow(tester);
      await tester.tap(find.text('Keep request'));
      await pumpFlow(tester);
      expect(
        (await service.fetchOrders(owner)).single.status,
        OrderStatus.requested,
      );
      await tester.tap(find.text('Delete request'));
      await pumpFlow(tester);
      await tester.tap(find.text('Delete request').last);
      await pumpFlow(tester);
      expect(find.text('Paw Points order: PP-NEW'), findsNothing);
      await tester.ensureVisible(find.text('Past'));
      await pumpFlow(tester);
      await tester.tap(find.text('Past'));
      await tester.pump();
      expect(find.text('No past deliveries'), findsOneWidget);
      final restored = MockCustomerOrderService(
        preferences: prefs,
        seedExamples: false,
      );
      expect(await restored.fetchOrders(owner), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
