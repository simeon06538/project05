import 'package:campus_delivery/screens/customer/customer_home_screen.dart';
import 'package:campus_delivery/services/sample_customer_orders.dart';
import 'package:campus_delivery/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> home(
    WidgetTester tester, {
    bool empty = false,
    VoidCallback? onRequest,
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: CustomerHomeScreen(
          name: 'Taylor',
          onSwitchRole: () {},
          orders: empty ? [] : sampleCustomerOrders(),
          isSampleData: !empty,
          onRequestDelivery: onRequest,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('separates active and past sample deliveries with fee totals', (
    tester,
  ) async {
    await home(tester);
    expect(find.text('Welcome, Taylor'), findsOneWidget);
    expect(find.textContaining('Sample orders'), findsOneWidget);
    expect(find.text('Waiting for a courier'), findsOneWidget);
    expect(find.text('Delivered'), findsNothing);
    expect(find.text('Delivery total \$3.50'), findsOneWidget);
    await tester.ensureVisible(find.text('Past'));
    await tester.tap(find.text('Past'));
    await tester.pump();
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Waiting for a courier'), findsNothing);
    expect(find.text('Delivery total \$6.00'), findsOneWidget);
  });

  testWidgets('request button opens form with the customer name', (
    tester,
  ) async {
    await home(tester);
    await tester.tap(find.text('Request a Delivery'));
    await tester.pumpAndSettle();
    expect(find.text('Request a delivery'), findsOneWidget);
    final nameField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(nameField.controller!.text, 'Taylor');
    await tester.tap(find.text('Back to deliveries').first);
    await tester.pumpAndSettle();
    expect(find.text('Your deliveries'), findsOneWidget);
  });

  testWidgets('supports the future request form callback', (tester) async {
    var requests = 0;
    await home(tester, onRequest: () => requests++);
    await tester.tap(find.text('Request a Delivery'));
    expect(requests, 1);
  });

  testWidgets('empty lists explain active and past states on a small screen', (
    tester,
  ) async {
    await home(tester, empty: true);
    expect(find.text('No active deliveries'), findsOneWidget);
    await tester.ensureVisible(find.text('Past'));
    await tester.tap(find.text('Past'));
    await tester.pump();
    expect(find.text('No past deliveries'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
