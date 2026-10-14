import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../models/order.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';

/// K-19: celebratory check-mark animation right after a delivery is
/// accepted, with where to go first.
Future<void> showAcceptedSuccess(BuildContext context, Order order) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
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
            children: [
              Lottie.asset(
                'assets/lottie/success.json',
                width: 140,
                height: 140,
                repeat: false,
              ),
              Text(
                'Delivery accepted!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Head to ${order.pickupLocation} and show order '
                '${order.pawPointsOrderNumber}. You\'ll earn '
                '${formatCents(order.totalPayCents)}.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Start delivery',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
