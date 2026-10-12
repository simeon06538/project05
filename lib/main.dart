import 'package:flutter/material.dart';

import 'screens/courier/courier_home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CampusDeliveryApp());
}

class CampusDeliveryApp extends StatelessWidget {
  const CampusDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // TODO(C-02): replace with the role-selection screen once it exists.
      home: const CourierHomeScreen(),
    );
  }
}
