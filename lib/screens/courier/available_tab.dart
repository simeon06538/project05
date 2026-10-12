import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import 'tab_header.dart';

/// Open delivery requests. The request list itself comes in K-03.
class AvailableTab extends StatelessWidget {
  const AvailableTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        TabHeader(
          title: 'Available requests',
          pill: 'Pickup, drop-off and pay shown before you accept',
        ),
        SizedBox(height: 20),
        GlassPanel(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          child: EmptyState(
            icon: Icons.delivery_dining,
            title: 'No requests right now',
            subtitle: 'New delivery requests will show up here.',
          ),
        ),
      ],
    );
  }
}
