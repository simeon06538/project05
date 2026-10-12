import 'package:flutter/material.dart';

import 'screens/courier/courier_home_screen.dart';
import 'services/courier_service.dart';
import 'services/mock_courier_service.dart';
import 'theme/app_theme.dart';

/// Demo courier used until the login screen (C-02) exists.
const demoCourierId = 'courier-demo';

void main() {
  // TODO(K-12): swap in the real API service once the server is ready.
  // New demo requests trickle in so auto-refresh (K-11) has something to show.
  runApp(
    CampusDeliveryApp(
      courierService: MockCourierService(
        newRequestEvery: const Duration(seconds: 30),
      ),
    ),
  );
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
      ),
    );
  }
}
