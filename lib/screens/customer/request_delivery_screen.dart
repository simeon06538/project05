import 'package:flutter/material.dart';

import '../../services/customer_order_service.dart';

import '../../constants/campus_locations.dart';
import '../../models/order.dart';
import '../../models/delivery_request_draft.dart';
import 'order_confirmation_screen.dart';
import '../../services/pricing.dart';
import '../../widgets/tip_selector.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';

/// C-04: local form preview. No orders are submitted from this screen yet.
class RequestDeliveryScreen extends StatefulWidget {
  const RequestDeliveryScreen({
    super.key,
    required this.orderName,
    this.orderService,
    this.customerId = 'customer-demo',
  });
  final String orderName;
  final CustomerOrderService? orderService;
  final String customerId;

  @override
  State<RequestDeliveryScreen> createState() => _RequestDeliveryScreenState();
}

class _RequestDeliveryScreenState extends State<RequestDeliveryScreen> {
  late final _name = TextEditingController(text: widget.orderName);
  final _restaurant = TextEditingController();
  final _orderNumber = TextEditingController();
  String? _pickup = 'union';
  String? _dropoff;
  int? _tipCents = 0;
  final _form = GlobalKey<FormState>();
  final _nameKey = GlobalKey<FormFieldState<String>>();
  final _pickupKey = GlobalKey<FormFieldState<String>>();
  final _restaurantKey = GlobalKey<FormFieldState<String>>();
  final _orderNumberKey = GlobalKey<FormFieldState<String>>();
  final _dropoffKey = GlobalKey<FormFieldState<String>>();
  final _tipKey = GlobalKey();
  bool _attemptedReview = false;

  String? _required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  Future<void> _review() async {
    FocusScope.of(context).unfocus();
    setState(() => _attemptedReview = true);
    final valid = _form.currentState!.validate();
    if (!valid || _tipCents == null) {
      final errors = [
        _nameKey,
        _pickupKey,
        _restaurantKey,
        _orderNumberKey,
        _dropoffKey,
      ].where((key) => key.currentState?.hasError ?? false);
      final target = errors.isNotEmpty
          ? errors.first.currentContext
          : _tipKey.currentContext;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && target != null && target.mounted) {
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 250),
            alignment: 0.15,
          );
        }
      });
      return;
    }
    final draft = DeliveryRequestDraft(
      orderName: _name.text.trim(),
      restaurant: _restaurant.text.trim(),
      orderNumber: _orderNumber.text.trim(),
      pickup: campusLocations.firstWhere((location) => location.id == _pickup),
      dropoff: campusLocations.firstWhere(
        (location) => location.id == _dropoff,
      ),
      tipCents: _tipCents!,
    );
    final order = await Navigator.of(context).push<Order>(
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          draft: draft,
          orderService: widget.orderService,
          customerId: widget.customerId,
        ),
      ),
    );
    if (mounted && order != null) Navigator.pop(context, order);
  }

  @override
  void dispose() {
    _name.dispose();
    _restaurant.dispose();
    _orderNumber.dispose();
    super.dispose();
  }

  Widget _locationField({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required GlobalKey<FormFieldState<String>> fieldKey,
    required FormFieldValidator<String> validator,
  }) => DropdownButtonFormField<String>(
    key: fieldKey,
    validator: validator,
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    isExpanded: true,
    items: [
      for (final location in campusLocations)
        DropdownMenuItem(
          value: location.id,
          child: Text(location.name, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: onChanged,
  );

  Widget _priceSummary() {
    final destination = _dropoff == null
        ? null
        : campusLocations.firstWhere((location) => location.id == _dropoff);
    final fee = destination == null
        ? null
        : deliveryFeeCents(destination.distanceFromUnionMiles);
    final total = fee == null || _tipCents == null ? null : fee + _tipCents!;
    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Delivery estimate',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (destination == null)
            const Text('Choose a drop-off location to calculate your fee.')
          else
            Text(
              '${destination.distanceFromUnionMiles.toStringAsFixed(2)} miles from the Union',
            ),
          line('Delivery fee', fee == null ? '—' : formatCents(fee)),
          line(
            'Tip',
            _tipCents == null ? 'Enter a valid tip' : formatCents(_tipCents!),
          ),
          const Divider(),
          line(
            'Estimated delivery total',
            total == null ? '—' : formatCents(total),
          ),
          const SizedBox(height: 8),
          const Text(
            'Food is paid separately with Paw Points. The server confirms the final delivery fee.',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackground(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                autovalidateMode: _attemptedReview
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to deliveries'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Request a delivery',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Already ordered? Use the details from your LSU Dining order. Food is paid separately with Paw Points.',
                    ),
                    const SizedBox(height: 20),
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Pickup details',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: _nameKey,
                            validator: (value) => _required(
                              value,
                              'Enter the name on your food order',
                            ),
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Name on the food order',
                              helperText: 'Match the name used in LSU Dining.',
                            ),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            maxLength: 100,
                          ),
                          const SizedBox(height: 16),
                          _locationField(
                            label: 'Pickup location',
                            fieldKey: _pickupKey,
                            validator: (value) =>
                                _required(value, 'Choose a pickup location'),
                            value: _pickup,
                            onChanged: (value) =>
                                setState(() => _pickup = value),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: _restaurantKey,
                            validator: (value) =>
                                _required(value, 'Enter the pickup restaurant'),
                            controller: _restaurant,
                            decoration: const InputDecoration(
                              labelText: 'Pickup restaurant',
                              hintText: 'e.g. Chick-fil-A',
                              helperText: 'Enter the restaurant at your pickup location.',
                            ),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: _orderNumberKey,
                            validator: (value) => _required(
                              value,
                              'Enter your Paw Points order number',
                            ),
                            controller: _orderNumber,
                            decoration: const InputDecoration(
                              labelText: 'Paw Points order number',
                              hintText: 'e.g. PP-10442',
                            ),
                            textInputAction: TextInputAction.done,
                            maxLength: 40,
                            autocorrect: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Deliver to',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          _locationField(
                            label: 'Drop-off location',
                            fieldKey: _dropoffKey,
                            validator: (value) =>
                                _required(
                                  value,
                                  'Choose a drop-off location',
                                ) ??
                                (value == _pickup
                                    ? 'Pickup and drop-off must be different'
                                    : null),
                            value: _dropoff,
                            onChanged: (value) =>
                                setState(() => _dropoff = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TipSelector(
                      key: _tipKey,
                      onChanged: (cents) => setState(() => _tipCents = cents),
                    ),
                    const SizedBox(height: 16),
                    _priceSummary(),
                    const SizedBox(height: 24),
                    Text(
                      widget.orderService == null
                          ? 'Form preview only · No delivery request is sent'
                          : 'Review your details before saving a demo request.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(label: 'Review request', onPressed: _review),
                    const SizedBox(height: 12),
                    const Text(
                      'Class prototype · No money is transferred',
                      textAlign: TextAlign.center,
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
