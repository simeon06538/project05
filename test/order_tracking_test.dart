import 'dart:async';

import 'package:campus_delivery/models/delivery_request_draft.dart';
import 'package:campus_delivery/models/order.dart';
import 'package:campus_delivery/screens/customer/customer_home_screen.dart';
import 'package:campus_delivery/screens/customer/order_tracking_screen.dart';
import 'package:campus_delivery/services/customer_order_service.dart';
import 'package:campus_delivery/services/sample_customer_orders.dart';
import 'package:campus_delivery/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TrackingService extends CustomerOrderService {
  Order? current = sampleCustomerOrders().first;
  bool fail = false;
  Completer<List<Order>>? pending;
  final customers = <String>[];
  @override
  Future<List<Order>> fetchOrders(String customerId) async {
    customers.add(customerId);
    if (pending != null) return pending!.future;
    if (fail) throw StateError('offline');
    return current == null ? [] : [current!];
  }

  @override
  Future<Order> createOrder(String customerId, DeliveryRequestDraft draft) =>
      throw UnimplementedError();
  @override
  Future<void> deleteOrder(String customerId, String orderId) =>
      throw UnimplementedError();
}

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
  }

  testWidgets(
    'customer refresh keeps loaded deliveries on failure and retry recovers',
    (tester) async {
      phone(tester);
      final service = _TrackingService();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: CustomerHomeScreen(
            name: 'Taylor',
            onSwitchRole: () {},
            orders: const [],
            orderService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Waiting for a courier'), findsOneWidget);
      service.fail = true;
      await tester.ensureVisible(find.text('Refresh deliveries'));
      await tester.tap(find.text('Refresh deliveries'));
      await tester.pumpAndSettle();
      expect(find.text('Waiting for a courier'), findsOneWidget);
      expect(
        find.textContaining('Showing your last loaded deliveries'),
        findsOneWidget,
      );
      service.fail = false;
      service.current = service.current!.copyWith(status: OrderStatus.accepted);
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Showing your last loaded deliveries'),
        findsNothing,
      );
      expect(find.text('Waiting for a courier'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'polls active deliveries, pauses in background, and stops on completion',
    (tester) async {
      phone(tester);
      final service = _TrackingService();
      await tester.pumpWidget(
        MaterialApp(
          home: OrderTrackingScreen(
            order: service.current!,
            customerId: 'customer-demo',
            orderService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.customers.length, 1);
      service.current = service.current!.copyWith(status: OrderStatus.accepted);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(service.customers.length, 2);
      expect(find.textContaining('A courier has accepted'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 15));
      expect(service.customers.length, 2);
      service.current = service.current!.copyWith(
        status: OrderStatus.delivered,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(service.customers.length, 3);
      await tester.pump(const Duration(seconds: 15));
      expect(service.customers.length, 3);
      expect(find.textContaining('Your delivery is complete'), findsOneWidget);
    },
  );

  Future<void> refresh(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Refresh status'));
    await tester.tap(find.text('Refresh status'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'refresh advances the four customer steps and handles cancellation',
    (tester) async {
      phone(tester);
      final semantics = tester.ensureSemantics();
      try {
        final service = _TrackingService();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: OrderTrackingScreen(
              order: service.current!,
              customerId: 'customer-demo',
              orderService: service,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final labels = {
          OrderStatus.requested: 'Requested',
          OrderStatus.accepted: 'Accepted',
          OrderStatus.pickedUp: 'Picked up',
          OrderStatus.delivered: 'Delivered',
        };
        for (final entry in labels.entries) {
          service.current = service.current!.copyWith(status: entry.key);
          await refresh(tester);
          expect(
            find.bySemanticsLabel('${entry.value}, current step'),
            findsOneWidget,
          );
        }
        expect(
          find.textContaining('Your delivery is complete'),
          findsOneWidget,
        );
        expect(find.text(r'$3.50'), findsOneWidget);
        expect(find.text('PP-4810'), findsOneWidget);
        service.current = service.current!.copyWith(
          status: OrderStatus.cancelled,
        );
        await refresh(tester);
        expect(find.text('This delivery was cancelled.'), findsOneWidget);
        expect(find.text('Current'), findsNothing);
        expect(service.customers.every((id) => id == 'customer-demo'), isTrue);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'refresh failure retains the last status; retry and missing order recover',
    (tester) async {
      phone(tester);
      final service = _TrackingService();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: OrderTrackingScreen(
            order: service.current!,
            customerId: 'customer-demo',
            orderService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      service.fail = true;
      await refresh(tester);
      expect(
        find.text('Could not refresh this delivery. Please try again.'),
        findsOneWidget,
      );
      expect(
        find.text('Waiting for a courier to accept your request.'),
        findsOneWidget,
      );
      service.fail = false;
      service.current = service.current!.copyWith(status: OrderStatus.accepted);
      await refresh(tester);
      expect(
        find.text('Could not refresh this delivery. Please try again.'),
        findsNothing,
      );
      expect(find.textContaining('A courier has accepted'), findsOneWidget);
      service.current = null;
      await refresh(tester);
      expect(find.text('Request no longer available'), findsOneWidget);
      expect(find.textContaining('A courier has accepted'), findsNothing);
    },
  );

  testWidgets(
    'leaving during an in-flight refresh does not update disposed state',
    (tester) async {
      final service = _TrackingService()..pending = Completer<List<Order>>();
      await tester.pumpWidget(
        MaterialApp(
          home: OrderTrackingScreen(
            order: service.current!,
            customerId: 'customer-demo',
            orderService: service,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Refreshing status…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      service.pending!.complete([service.current!]);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'active card opens tracking and returning after fulfillment shows Past',
    (tester) async {
      phone(tester);
      final service = _TrackingService();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: CustomerHomeScreen(
            name: 'Taylor',
            onSwitchRole: () {},
            orders: const [],
            orderService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Waiting for a courier'));
      await tester.tap(find.text('Waiting for a courier'));
      await tester.pumpAndSettle();
      expect(find.text('Track delivery'), findsOneWidget);
      service.current = service.current!.copyWith(
        status: OrderStatus.delivered,
      );
      await refresh(tester);
      await tester.ensureVisible(find.text('Back to deliveries'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to deliveries'));
      await tester.pumpAndSettle();
      expect(find.text('Track delivery'), findsNothing);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Waiting for a courier'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
