import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/courier_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';
import 'accept_dialog.dart';
import 'order_widgets.dart';

/// K-04: full breakdown of one request before the courier accepts it.
/// K-05: "Accept delivery" button with a confirm dialog. Pops with the
/// accepted [Order] on success.
class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({
    super.key,
    required this.order,
    required this.service,
    required this.courierId,
    this.now,
  });

  final Order order;
  final CourierService service;
  final String courierId;

  /// Overridable clock so tests get a stable "x min ago".
  final DateTime? now;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _accepting = false;

  Future<void> _accept() async {
    final order = widget.order;
    if (!await confirmAccept(context, order) || !mounted) return;

    setState(() => _accepting = true);
    try {
      final accepted = await widget.service.acceptRequest(
        order.id,
        widget.courierId,
      );
      if (mounted) Navigator.of(context).pop(accepted);
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      // K-06 / K-13 replace this with friendlier handling per error type.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // Header stays pinned so Back is always reachable.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        _BackButton(onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Request details',
                            style: textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        GlassPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RouteStops(order: order),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  InfoChip(
                                    icon: Icons.straighten,
                                    text:
                                        '${order.distanceMiles.toStringAsFixed(1)} mi',
                                  ),
                                  InfoChip(
                                    icon: Icons.schedule,
                                    text: _requestedAgo(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionLabel('Your pay'),
                        GlassPanel(
                          child: Column(
                            children: [
                              _MoneyRow(
                                label: 'Delivery fee',
                                cents: order.deliveryFeeCents,
                              ),
                              const SizedBox(height: 10),
                              _MoneyRow(label: 'Tip', cents: order.tipCents),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  height: 1,
                                  color: Color(0x33FFFFFF),
                                ),
                              ),
                              _MoneyRow(
                                label: 'Total pay',
                                cents: order.totalPayCents,
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          r'Fee is based on distance from the Union: $2.00 + $0.50 '
                          r'per 0.25 mi, up to $6.00.',
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        _SectionLabel('Order'),
                        GlassPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Paw Points order #',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    order.pawPointsOrderNumber,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withAlpha(90),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Food already paid with Paw Points',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Show this order number at the pickup counter.',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: PrimaryButton(
                      label:
                          'Accept delivery · ${formatCents(order.totalPayCents)}',
                      loading: _accepting,
                      onPressed: _accept,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _requestedAgo() {
    final minutes = (widget.now ?? DateTime.now())
        .difference(widget.order.createdAt)
        .inMinutes;
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '$minutes min ago';
    return '${minutes ~/ 60} h ago';
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        onTap: onTap,
        child: const GlassPanel(
          padding: EdgeInsets.all(10),
          borderRadius: 14,
          child: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.cents,
    this.bold = false,
  });

  final String label;
  final int cents;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: bold ? AppColors.textPrimary : AppColors.textSecondary,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      fontSize: bold ? 17 : 15,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          formatCents(cents),
          style: style.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
