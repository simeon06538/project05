import 'package:campus_delivery/constants/campus_locations.dart';
import 'package:campus_delivery/constants/campus_restaurants.dart';
import 'package:campus_delivery/screens/customer/request_delivery_screen.dart';
import 'package:campus_delivery/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restaurant choices use known pickup buildings and Pentagon halls are labeled', () {
    for (final restaurant in campusRestaurants) {
      expect(
        campusLocations.any(
          (location) => location.id == restaurant.pickupLocationId,
        ),
        isTrue,
        reason: restaurant.name,
      );
    }
    for (final id in [
      'beauregard-hall',
      'jackson-hall',
      'lejeune-hall',
      'taylor-hall',
    ]) {
      expect(
        campusLocations.firstWhere((location) => location.id == id).name,
        startsWith('Pentagon · '),
      );
    }
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const RequestDeliveryScreen(orderName: 'Taylor'),
      ),
    );
    final dropoff = find.byType(DropdownButtonFormField<String>).last;
    await tester.ensureVisible(dropoff);
    await tester.pumpAndSettle();
    await tester.tap(dropoff);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Pentagon · LeJeune Hall'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Pentagon · LeJeune Hall').last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'restaurant dropdown changes pickup and miles, including switching back to Union',
    (tester) async {
      await open(tester);
      final picker = find.byKey(const ValueKey('restaurant-picker'));
      await tester.ensureVisible(picker);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Popeyes'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Popeyes').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .state<FormFieldState<String>>(
              find.byType(DropdownButtonFormField<String>).first,
            )
            .value,
        'the-5',
      );
      expect(
        find.text('Approx. 0.08 miles from The 5 Dining Hall (demo estimate)'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        'Popeyes',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Chick-fil-A');
      await tester.pumpAndSettle();
      expect(
        tester
            .state<FormFieldState<String>>(
              find.byType(DropdownButtonFormField<String>).first,
            )
            .value,
        'union',
      );
      expect(
        find.text('Approx. 0.35 miles from LSU Student Union (demo estimate)'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'typed Popeyes is recognized and an unlisted restaurant can use a manual building',
    (tester) async {
      await open(tester);
      final restaurant = find.byType(TextFormField).at(1);
      await tester.ensureVisible(restaurant);
      await tester.pumpAndSettle();
      await tester.enterText(restaurant, "Popeye's");
      await tester.pumpAndSettle();
      expect(
        tester
            .state<FormFieldState<String>>(
              find.byType(DropdownButtonFormField<String>).first,
            )
            .value,
        'the-5',
      );
      final picker = find.byKey(const ValueKey('restaurant-picker'));
      await tester.ensureVisible(picker);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();
      const other = 'Other · Enter restaurant and pickup building';
      await tester.scrollUntilVisible(
        find.text(other),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(other).last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(restaurant).controller!.text,
        isEmpty,
      );
      await tester.enterText(restaurant, 'Custom campus pickup');
      await tester.pumpAndSettle();
      final pickup = find.byType(DropdownButtonFormField<String>).first;
      await tester.ensureVisible(pickup);
      await tester.pumpAndSettle();
      await tester.tap(pickup);
      await tester.pumpAndSettle();
      if (find.text('LSU Student Union').evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          find.text('LSU Student Union'),
          -150,
          scrollable: find.byType(Scrollable).last,
        );
      }
      await tester.tap(find.text('LSU Student Union').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(restaurant).controller!.text,
        'Custom campus pickup',
      );
      expect(
        find.text('Approx. 0.35 miles from LSU Student Union (demo estimate)'),
        findsOneWidget,
      );
    },
  );
}
