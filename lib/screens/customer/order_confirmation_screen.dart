import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../services/customer_order_service.dart';
import '../../services/api_customer_order_service.dart';

import '../../models/delivery_request_draft.dart';
import '../../models/order.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';

/// C-11: reviews a validated draft. Persistence is added with C-12/C-13.
class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.draft,
    this.orderService,
    this.customerId = 'customer-demo',
  });
  final DeliveryRequestDraft draft;
  final CustomerOrderService? orderService;
  final String customerId;

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  DeliveryRequestDraft get draft => widget.draft;
  bool _saving = false;

  Future<void> _confirm(BuildContext context) async {
    if (_saving) return;
    final service = widget.orderService;
    if (service == null) {
      _confirmPreview(context);
      return;
    }
    setState(() => _saving = true);
    try {
      final order = await service.createOrder(widget.customerId, draft);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            service.isServerBacked
                ? 'Delivery request sent'
                : 'Demo request saved',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Lottie.asset(
                  'assets/lottie/success.json',
                  repeat: false,
                ),
              ),
              Text(
                service.isServerBacked
                    ? 'Your request is saved on the server and available for a courier to accept. No real money was transferred.'
                    : 'Your request is saved on this device and will appear in Active deliveries. This demo is not connected to couriers yet. No money was transferred.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('View deliveries'),
            ),
          ],
        ),
      );
      if (context.mounted) Navigator.pop(context, order);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is CustomerApiException
                  ? error.message
                  : 'Could not save your demo request. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _confirmPreview(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Demo confirmation preview'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: Lottie.asset('assets/lottie/success.json', repeat: false),
            ),
            const Text(
              'You completed the confirmation preview. No order was saved or sent to a courier, and no money was transferred.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to review'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget detail(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
    Widget price(String label, int cents) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(formatCents(cents)),
        ],
      ),
    );
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton.icon(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit details'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Review your delivery',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Check these details against your LSU Dining order before confirming.',
                    ),
                    const SizedBox(height: 20),
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          detail('Name on the food order', draft.orderName),
                          detail('Pickup restaurant', draft.restaurant),
                          detail('Pickup location', draft.pickup.name),
                          detail('Paw Points order number', draft.orderNumber),
                          const Divider(),
                          detail('Drop-off location', draft.dropoff.name),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Delivery estimate',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Approx. ${draft.distanceMiles.toStringAsFixed(2)} miles from ${draft.pickup.name} (demo estimate)',
                          ),
                          price('Delivery fee', draft.feeCents),
                          price('Tip', draft.tipCents),
                          const Divider(),
                          price('Estimated delivery total', draft.totalCents),
                          const SizedBox(height: 8),
                          const Text(
                            'Food is already paid separately with Paw Points. This total covers delivery only.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.orderService == null
                          ? 'Preview only · Confirmation does not save or send an order yet.'
                          : widget.orderService!.isServerBacked
                          ? 'Confirmation sends this request to the delivery server. No real payment is made.'
                          : 'Demo orders are saved on this device. No real payment is made.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Confirm demo request',
                      loading: _saving,
                      onPressed: () => _confirm(context),
                    ),
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
    );
  }
}
