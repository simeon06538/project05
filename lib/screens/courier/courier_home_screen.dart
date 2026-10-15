import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/courier_prefs.dart';
import '../../services/courier_service.dart';
import '../../services/haptics.dart';
import '../../services/mock_courier_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_tab_bar.dart';
import 'available_tab.dart';
import 'courier_header.dart';
import 'settings_screen.dart';
import 'still_there_dialog.dart';
import 'earnings_tab.dart';
import 'my_deliveries_tab.dart';

/// K-01: Courier home with three tabs - Available, My Deliveries, Earnings.
class CourierHomeScreen extends StatefulWidget {
  const CourierHomeScreen({
    super.key,
    required this.service,
    required this.courierId,
    this.courierName = 'Courier',
    this.prefs,
    this.idleTimeout = const Duration(minutes: 20),
    this.stillThereGrace = const Duration(seconds: 60),
  });

  final CourierService service;

  /// The signed-in courier. Comes from the login screen once C-02 exists.
  final String courierId;

  /// Shown in the header; also from the login screen once C-02 exists.
  final String courierName;

  /// K-43: saved settings; null in tests that don't need them.
  final CourierPrefs? prefs;

  /// K-45: how long without a tap before asking "Still there?" (null turns
  /// it off), and how long the courier then has to answer.
  final Duration? idleTimeout;
  final Duration stillThereGrace;

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
  late bool _online = widget.prefs?.online ?? true;
  int _openCount = 0;

  /// K-31: editable in Settings (from the login screen once C-02 exists).
  late String _name = widget.prefs?.name ?? widget.courierName;

  /// K-41: daily earnings goal, $20 to start.
  late int _dailyGoalCents = widget.prefs?.dailyGoalCents ?? 2000;

  void _setOnline(bool online) {
    setState(() => _online = online);
    widget.prefs?.setOnline(online);
    _resetIdle();
  }

  // K-45: idle check while online.
  Timer? _idleTimer;
  bool _askingStillThere = false;

  @override
  void initState() {
    super.initState();
    _resetIdle();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  /// Restarts the idle countdown; called on every tap and online change.
  void _resetIdle() {
    _idleTimer?.cancel();
    final timeout = widget.idleTimeout;
    if (!_online || timeout == null || _askingStillThere) return;
    _idleTimer = Timer(timeout, _askStillThere);
  }

  Future<void> _askStillThere() async {
    if (!mounted || !_online) return;
    _askingStillThere = true;
    final stay = await askStillThere(context, grace: widget.stillThereGrace);
    _askingStillThere = false;
    if (!mounted) return;
    if (stay) {
      _resetIdle();
      return;
    }
    _setOnline(false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("You're offline. Go online when you're ready again."),
      ),
    );
  }

  /// Bumped on "Reset demo data" so every tab rebuilds and reloads.
  int _resetGeneration = 0;

  void _openSettings() {
    final service = widget.service;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          name: _name,
          onNameChanged: (name) {
            setState(() => _name = name);
            widget.prefs?.setName(name);
          },
          dailyGoalCents: _dailyGoalCents,
          onDailyGoalChanged: (cents) => setState(() {
            _dailyGoalCents = cents;
            widget.prefs?.setDailyGoalCents(cents);
          }),
          onResetDemo: service is MockCourierService
              ? () {
                  service.resetDemo(withHistoryFor: widget.courierId);
                  setState(() {
                    _resetGeneration++;
                    _openCount = 0;
                    _selectedTab = 0;
                  });
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // K-45: any tap counts as activity.
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetIdle(),
        child: AppBackground(
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
                        name: _name,
                        onOpenSettings: _openSettings,
                        online: _online,
                        onOnlineChanged: (on) {
                          Haptics.toggle();
                          _setOnline(on);
                        },
                      ),
                      const SizedBox(height: 16),
                      GlassTabBar(
                        labels: _tabLabels,
                        icons: _tabIcons,
                        // K-29: open requests, hidden while offline.
                        badges: [_online ? _openCount : null, null, null],
                        selectedIndex: _selectedTab,
                        onSelected: (i) => setState(() => _selectedTab = i),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        // IndexedStack keeps each tab's scroll position.
                        child: IndexedStack(
                          index: _selectedTab,
                          children: [
                            for (final (i, tab) in [
                              AvailableTab(
                                service: widget.service,
                                courierId: widget.courierId,
                                onViewActiveDelivery: () =>
                                    setState(() => _selectedTab = 1),
                                isVisible: _selectedTab == 0,
                                isOnline: _online,
                                onCountChanged: (count) {
                                  if (count != _openCount) {
                                    setState(() => _openCount = count);
                                  }
                                },
                                onGoOnline: () => _setOnline(true),
                              ),
                              MyDeliveriesTab(
                                service: widget.service,
                                courierId: widget.courierId,
                                isVisible: _selectedTab == 1,
                              ),
                              EarningsTab(
                                service: widget.service,
                                courierId: widget.courierId,
                                dailyGoalCents: _dailyGoalCents,
                                isVisible: _selectedTab == 2,
                              ),
                            ].indexed)
                              // Hidden tabs stay alive but pause their
                              // animations (e.g. looping empty states).
                              TickerMode(
                                key: ValueKey((_resetGeneration, i)),
                                enabled: i == _selectedTab,
                                child: tab,
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
      ),
    );
  }
}
