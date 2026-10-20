import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';
import 'order_widgets.dart';

/// Glass "are you sure?" dialog before accepting. Resolves to true only
/// when the courier taps Accept.
Future<bool> confirmAccept(BuildContext context, Order order) async {
  final accepted = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accept this delivery?',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 16),
              RouteStops(order: order),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "You'll earn",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    formatCents(order.totalPayCents),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Accept',
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Not now',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return accepted ?? false;
}
