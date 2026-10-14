import 'package:flutter/material.dart';

import '../../services/courier_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_tab_bar.dart';
import 'available_tab.dart';
import 'courier_header.dart';
import 'earnings_tab.dart';
import 'my_deliveries_tab.dart';

/// K-01: Courier home with three tabs - Available, My Deliveries, Earnings.
class CourierHomeScreen extends StatefulWidget {
  const CourierHomeScreen({
    super.key,
    required this.service,
    required this.courierId,
    this.courierName = 'Courier',
  });

  final CourierService service;

  /// The signed-in courier. Comes from the login screen once C-02 exists.
  final String courierId;

  /// Shown in the header; also from the login screen once C-02 exists.
  final String courierName;

  @override
  State<CourierHomeScreen> createState() => _CourierHomeScreenState();
}

class _CourierHomeScreenState extends State<CourierHomeScreen> {
  static const _tabLabels = ['Available', 'My Deliveries', 'Earnings'];
  static const _tabIcons = [
    Icons.list_alt_rounded,
    Icons.delivery_dining,
    Icons.savings_outlined,
  ];

  int _selectedTab = 0;
  bool _online = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              // Keeps a phone-sized column when run on web/desktop.
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CourierHeader(
                      name: widget.courierName,
                      online: _online,
                      onOnlineChanged: (on) => setState(() => _online = on),
                    ),
                    const SizedBox(height: 16),
                    GlassTabBar(
                      labels: _tabLabels,
                      icons: _tabIcons,
                      selectedIndex: _selectedTab,
                      onSelected: (i) => setState(() => _selectedTab = i),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      // IndexedStack keeps each tab's scroll position.
                      child: IndexedStack(
                        index: _selectedTab,
                        children: [
                          AvailableTab(
                            service: widget.service,
                            courierId: widget.courierId,
                            onViewActiveDelivery: () =>
                                setState(() => _selectedTab = 1),
                            isVisible: _selectedTab == 0,
                            isOnline: _online,
                            onGoOnline: () => setState(() => _online = true),
                          ),
                          MyDeliveriesTab(
                            service: widget.service,
                            courierId: widget.courierId,
                            isVisible: _selectedTab == 1,
                          ),
                          EarningsTab(
                            service: widget.service,
                            courierId: widget.courierId,
                            isVisible: _selectedTab == 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Class prototype · No money is transferred',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
