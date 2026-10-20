import 'dart:io';

import 'package:campus_delivery/constants/campus_locations.dart';
import 'package:campus_delivery/screens/customer/request_delivery_screen.dart';
import 'package:campus_delivery/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preview destinations match the existing server locations', () {
    final seed = File('server/src/seed-data.js').readAsStringSync();
    final rows = RegExp(
      r"\{ id: '([^']+)', name: '([^']+)', distanceFromUnionMiles: ([\d.]+) \}",
    ).allMatches(seed);
    expect(campusLocations.length, 12);
    expect(
      campusLocations
          .map(
            (location) => [
              location.id,
              location.name,
              location.distanceFromUnionMiles,
            ],
          )
          .toList(),
      rows.map((row) => [row[1], row[2], double.parse(row[3]!)]).toList(),
    );
  });

  testWidgets('edits order details and locations without losing typed values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const RequestDeliveryScreen(orderName: 'Taylor'),
      ),
    );
    await tester.pump();
    final fields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      'Taylor',
    );
    await tester.enterText(fields.at(0), 'Sam');
    await tester.enterText(fields.at(1), 'Chick-fil-A');
    await tester.ensureVisible(fields.at(2));
    await tester.enterText(fields.at(2), 'PP-123');
    final dropoff = find.byType(DropdownButtonFormField<String>).last;
    await tester.ensureVisible(dropoff);
    await tester.tap(dropoff);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Middleton Library').last);
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(fields.at(0)).controller!.text, 'Sam');
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      'Chick-fil-A',
    );
    expect(
      tester.widget<TextFormField>(fields.at(2)).controller!.text,
      'PP-123',
    );
    expect(find.text('Middleton Library'), findsWidgets);
    await tester.ensureVisible(
      find.text('Form preview only · No delivery request is sent'),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'estimate updates for destination and tip, hiding invalid totals',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const RequestDeliveryScreen(orderName: 'Taylor'),
        ),
      );
      await tester.pump();
      expect(
        find.text('Choose a drop-off location to calculate your fee.'),
        findsOneWidget,
      );
      final dropoff = find.byType(DropdownButtonFormField<String>).last;
      await tester.ensureVisible(dropoff);
      await tester.tap(dropoff);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Middleton Library').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Estimated delivery total'));
      expect(find.text('\$2.50'), findsNWidgets(2));
      await tester.ensureVisible(find.text('\$1'));
      await tester.tap(find.text('\$1'));
      await tester.pump();
      expect(find.text('\$3.50'), findsOneWidget);
      await tester.tap(find.text('Custom'));
      await tester.pump();
      final custom = find.widgetWithText(TextFormField, 'Custom tip');
      await tester.ensureVisible(custom);
      await tester.enterText(custom, '50.00');
      await tester.pump();
      expect(find.text('\$52.50'), findsOneWidget);
      await tester.enterText(custom, '50.01');
      await tester.pump();
      expect(find.text('\$52.50'), findsNothing);
      expect(find.text('Enter a valid tip'), findsOneWidget);
      await tester.ensureVisible(find.text(r'$2'));
      await tester.tap(find.text(r'$2'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(dropoff);
      await tester.tap(dropoff);
      await tester.pumpAndSettle();
      await tester.tap(find.text('West Campus Apartments').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Estimated delivery total'));
      expect(find.text(r'$4.00'), findsOneWidget);
      expect(find.text(r'$6.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
