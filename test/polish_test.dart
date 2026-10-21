import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_delivery/main.dart';
import 'package:campus_delivery/services/mock_courier_service.dart';
import 'package:campus_delivery/theme/app_theme.dart';

void main() {
  testWidgets('tab bar shows an icon for each tab', (tester) async {
    await tester.pumpWidget(
      CampusDeliveryApp(
        showWelcome: false,
        courierService: MockCourierService(latency: Duration.zero),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.list_alt_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delivery_dining), findsWidgets);
    expect(find.byIcon(Icons.savings_outlined), findsOneWidget);
  });

  testWidgets('tabs are announced with their selected state', (tester) async {
    await tester.pumpWidget(
      CampusDeliveryApp(
        showWelcome: false,
        courierService: MockCourierService(latency: Duration.zero),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Available tab, 5 open'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Available tab, 5 open')),
      isSemantics(isSelected: true, isButton: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Earnings tab')),
      isSemantics(isSelected: false, isButton: true),
    );
  });

  test('theme gives shared widgets the purple glass defaults', () {
    final theme = AppTheme.dark;

    expect(theme.progressIndicatorTheme.color, AppColors.accent);
    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(
      theme.filledButtonTheme.style?.backgroundColor?.resolve({}),
      AppColors.accentStrong,
    );
  });
}
