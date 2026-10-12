import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import 'tab_header.dart';

/// The courier's accepted delivery. Filled in by K-07 / K-08.
class MyDeliveriesTab extends StatelessWidget {
  const MyDeliveriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        TabHeader(
          title: 'My deliveries',
          pill: 'One active delivery at a time',
        ),
        SizedBox(height: 20),
        GlassPanel(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          child: EmptyState(
            icon: Icons.route,
            title: 'No active delivery',
            subtitle: 'Accept a request to start delivering.',
          ),
        ),
      ],
    );
  }
}
