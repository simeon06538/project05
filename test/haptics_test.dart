import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pickup_checklist.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/screens/courier/my_deliveries_tab.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';

/// Records every haptic request the app sends to the phone, as
/// `HapticFeedback.vibrate:type` (`HapticFeedback.vibrate:null` for a
/// plain vibration).
List<String> _recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method.startsWith('HapticFeedback')) {
        calls.add('${call.method}:${call.arguments}');
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

void main() {
  testWidgets('going online or offline gives a selection click', (
    tester,
  ) async {
    final calls = _recordHaptics(tester);
    await tester.pumpWidget(
      CampusDeliveryApp(
        showWelcome: false,
        courierService: MockCourierService(latency: Duration.zero),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Online'));
    await tester.pump();

    expect(calls, ['HapticFeedback.vibrate:HapticFeedbackType.selectionClick']);
  });

  testWidgets('picking up is a light tap, delivering a heavy one', (
    tester,
  ) async {
    final calls = _recordHaptics(tester);
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;
    await service.acceptRequest(order.id, 'courier-a');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyDeliveriesTab(service: service, courierId: 'courier-a'),
        ),
      ),
    );
    await tester.pump();

    await completePickupChecklist(tester);

    await tester.scrollUntilVisible(find.text('Mark as picked up'), 200);
    await tester.ensureVisible(find.text('Mark as picked up'));
    await tester.pump();
    await tester.tap(find.text('Mark as picked up'));
    await tester.pump();
    await tester.pump();
    expect(calls, ['HapticFeedback.vibrate:HapticFeedbackType.lightImpact']);

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
        .clearSnackBars();
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Mark as delivered'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, delivered'));
    await tester.pump();
    await tester.pump();

    expect(calls.last, 'HapticFeedback.vibrate:HapticFeedbackType.heavyImpact');
  });

  testWidgets('a failed status update vibrates', (tester) async {
    final calls = _recordHaptics(tester);
    final service = MockCourierService(latency: Duration.zero);
    final order = (await service.fetchAvailableRequests()).first;
    await service.acceptRequest(order.id, 'courier-a');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyDeliveriesTab(service: service, courierId: 'courier-a'),
        ),
      ),
    );
    await tester.pump();

    service.failNextCalls();
    await completePickupChecklist(tester);
    await tester.scrollUntilVisible(find.text('Mark as picked up'), 200);
    await tester.ensureVisible(find.text('Mark as picked up'));
    await tester.pump();
    await tester.tap(find.text('Mark as picked up'));
    await tester.pump();
    await tester.pump();

    expect(calls, ['HapticFeedback.vibrate:null']);
  });
}
