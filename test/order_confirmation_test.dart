import 'package:campus_delivery/screens/customer/request_delivery_screen.dart';
import 'package:campus_delivery/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'reviews trimmed details, preserves edits and confirms only a preview',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const RequestDeliveryScreen(orderName: '  Taylor  '),
        ),
      );
      final fields = find.byType(TextFormField);
      await tester.ensureVisible(fields.at(1));
      await tester.enterText(fields.at(1), '  Chick-fil-A  ');
      await tester.ensureVisible(fields.at(2));
      await tester.enterText(fields.at(2), '  PP-123  ');
      final dropoff = find.byType(DropdownButtonFormField<String>).last;
      await tester.ensureVisible(dropoff);
      await tester.tap(dropoff);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Middleton Library').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(r'$2'));
      await tester.tap(find.text(r'$2'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Review request'));
      await tester.tap(find.text('Review request'));
      await tester.pumpAndSettle();
      expect(find.text('Review your delivery'), findsOneWidget);
      expect(find.text('Taylor'), findsOneWidget);
      expect(find.text('Chick-fil-A'), findsOneWidget);
      expect(find.text('PP-123'), findsOneWidget);
      expect(find.text('LSU Student Union'), findsOneWidget);
      expect(find.text('Middleton Library'), findsOneWidget);
      expect(find.text(r'$4.50'), findsOneWidget);
      await tester.tap(find.text('Edit details'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(fields.at(1)).controller!.text,
        '  Chick-fil-A  ',
      );
      await tester.ensureVisible(fields.at(1));
      await tester.enterText(fields.at(1), 'Sonic');
      await tester.ensureVisible(find.text('Review request'));
      await tester.tap(find.text('Review request'));
      await tester.pumpAndSettle();
      expect(find.text('Sonic'), findsOneWidget);
      expect(find.text(r'$4.50'), findsOneWidget);
      await tester.ensureVisible(find.text('Confirm demo request'));
      await tester.tap(find.text('Confirm demo request'));
      await tester.pumpAndSettle();
      expect(find.text('Demo confirmation preview'), findsOneWidget);
      expect(find.textContaining('No order was saved or sent'), findsOneWidget);
      await tester.tap(find.text('Back to review'));
      await tester.pumpAndSettle();
      expect(find.text('Review your delivery'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
