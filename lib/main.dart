import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/courier/courier_home_screen.dart';
import 'services/courier_service.dart';
import 'services/mock_courier_service.dart';
import 'theme/app_theme.dart';
import 'theme/high_contrast.dart';

/// Demo courier used until the login screen (C-02) exists.
const demoCourierId = 'courier-demo';
const demoCourierName = 'Alex Morgan';

void main() {
  // TODO(K-12): swap in the real API service once the server is ready.
  // New demo requests trickle in so auto-refresh (K-11) has something to show.
  final service = MockCourierService(
    newRequestEvery: const Duration(seconds: 30),
  );
  // Demo: another courier grabs the best-paying request (Panda Express)
  // after a minute, to show the "already taken" message (K-13).
  Timer(
    const Duration(minutes: 1),
    () => service.takeByOtherCourier('order-4'),
  );
  // Demo: a week of past deliveries so the earnings chart has data (K-25).
  service.seedHistory(demoCourierId);
  // Demo: open the app with ?demo=offline to see the error state (K-14).
  if (Uri.base.queryParameters['demo'] == 'offline') service.failNextCalls();
  runApp(CampusDeliveryApp(courierService: service));
}

class CampusDeliveryApp extends StatefulWidget {
  const CampusDeliveryApp({
    super.key,
    required this.courierService,
    this.highContrast,
  });

  final CourierService courierService;

  /// K-42: lets tests start in high contrast; the app makes its own.
  final ValueNotifier<bool>? highContrast;

  @override
  State<CampusDeliveryApp> createState() => _CampusDeliveryAppState();
}

class _CampusDeliveryAppState extends State<CampusDeliveryApp> {
  late final _highContrast = widget.highContrast ?? ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return HighContrastScope(
      notifier: _highContrast,
      child: MaterialApp(
        title: 'Campus Delivery',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        // K-42: high contrast also turns on bold text everywhere.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            boldText:
                HighContrastScope.of(context) || MediaQuery.boldTextOf(context),
          ),
          child: child!,
        ),
        // TODO(C-02): replace with the role-selection screen once it exists.
        home: CourierHomeScreen(
          service: widget.courierService,
          courierId: demoCourierId,
          courierName: demoCourierName,
        ),
      ),
    );
  }
}
