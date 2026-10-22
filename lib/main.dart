import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'services/customer_order_service.dart';
import 'services/api_customer_order_service.dart';
import 'services/mock_customer_order_service.dart';

import 'models/user.dart';
import 'screens/welcome_screen.dart';
import 'screens/customer/customer_home_screen.dart';

import 'package:flutter/material.dart';

import 'screens/courier/courier_home_screen.dart';
import 'screens/courier/onboarding_screen.dart';
import 'services/api_courier_service.dart';
import 'services/courier_prefs.dart';
import 'services/courier_service.dart';
import 'services/mock_courier_service.dart';
import 'theme/app_theme.dart';
import 'theme/high_contrast.dart';

/// The courier in the offline mock (K-02); on the server each name is its
/// own courier (K-12).
const demoCourierId = 'courier-demo';
const demoCourierName = 'Alex Morgan';

Future<void> main() async {
  // K-43: load saved settings before the first frame.
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await CourierPrefs.load();
  final customerPreferences = await SharedPreferences.getInstance();
  // K-12: couriers use the server by default, like customers (C-13).
  // flutter run --dart-define=USE_MOCK_COURIER_API=true for the offline demo.
  const useMockCourier = bool.fromEnvironment('USE_MOCK_COURIER_API');
  final CourierService courierService = useMockCourier
      ? _offlineCourierDemo()
      : ApiCourierService(preferences: customerPreferences);
  const useMock = bool.fromEnvironment('USE_MOCK_CUSTOMER_API');
  runApp(
    CampusDeliveryApp(
      courierService: courierService,
      prefs: prefs,
      customerOrderService: useMock
          ? MockCustomerOrderService(preferences: customerPreferences)
          : ApiCustomerOrderService(preferences: customerPreferences),
    ),
  );
}

/// The mock courier service with its demo extras.
MockCourierService _offlineCourierDemo() {
  // New demo requests trickle in so auto-refresh (K-11) has something to show.
  final service = MockCourierService(
    newRequestEvery: const Duration(minutes: 1),
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
  return service;
}

class CampusDeliveryApp extends StatefulWidget {
  const CampusDeliveryApp({
    super.key,
    required this.courierService,
    this.highContrast,
    this.prefs,
    this.showWelcome = true,
    this.customerOrderService,
  });

  final CourierService courierService;
  final CustomerOrderService? customerOrderService;

  /// False only for tests that exercise the courier home directly.
  final bool showWelcome;

  /// K-42: lets tests start in high contrast; the app makes its own.
  final ValueNotifier<bool>? highContrast;

  /// K-43: saved settings; null in tests that don't need them.
  final CourierPrefs? prefs;

  @override
  State<CampusDeliveryApp> createState() => _CampusDeliveryAppState();
}

class _CampusDeliveryAppState extends State<CampusDeliveryApp> {
  late bool _choosingRole = widget.showWelcome;
  late UserRole _role = widget.showWelcome
      ? UserRole.customer
      : UserRole.courier;
  late String _name = widget.prefs?.name ?? '';
  late final _customerService =
      widget.customerOrderService ?? MockCustomerOrderService();

  void _switchRole() => setState(() => _choosingRole = true);

  String get _courierName => _name.trim().isEmpty ? demoCourierName : _name;

  late bool _showIntro = widget.prefs != null && !widget.prefs!.onboardingDone;

  late final _highContrast =
      widget.highContrast ?? ValueNotifier(widget.prefs?.highContrast ?? false);

  @override
  void initState() {
    super.initState();
    _highContrast.addListener(
      () => widget.prefs?.setHighContrast(_highContrast.value),
    );
  }

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
        // C-02: choose a role before entering either demo flow.
        // K-44: the intro comes first, once, when settings are saved.
        home: _choosingRole
            ? WelcomeScreen(
                initialName: _name,
                initialRole: _name.isEmpty ? UserRole.customer : _role,
                onContinue: (name, role) {
                  widget.prefs?.setName(name);
                  setState(() {
                    _name = name;
                    _role = role;
                    _choosingRole = false;
                  });
                },
              )
            : _role == UserRole.customer
            ? CustomerHomeScreen(
                name: _name,
                onSwitchRole: _switchRole,
                orders: const [],
                isSampleData: false,
                orderService: _customerService,
                customerId: 'demo-customer:${_name.trim().toLowerCase()}',
              )
            : _showIntro
            ? OnboardingScreen(
                onDone: () {
                  widget.prefs?.setOnboardingDone(true);
                  setState(() => _showIntro = false);
                },
              )
            : CourierHomeScreen(
                service: widget.courierService,
                courierId: widget.courierService.isServerBacked
                    ? '${ApiCourierService.idPrefix}$_courierName'
                    : demoCourierId,
                courierName: _courierName,
                onSwitchRole: widget.showWelcome ? _switchRole : null,
                prefs: widget.prefs,
              ),
      ),
    );
  }
}
