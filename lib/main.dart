import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/courier/courier_home_screen.dart';
import 'services/courier_service.dart';
import 'services/mock_courier_service.dart';
import 'theme/app_theme.dart';

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

class CampusDeliveryApp extends StatelessWidget {
  const CampusDeliveryApp({super.key, required this.courierService});

  final CourierService courierService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // TODO(C-02): replace with the role-selection screen once it exists.
      home: CourierHomeScreen(
        service: courierService,
        courierId: demoCourierId,
        courierName: demoCourierName,
      ),
    );
  }
}
