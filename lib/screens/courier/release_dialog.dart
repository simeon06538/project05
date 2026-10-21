import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';

/// K-28: "are you sure?" before giving a delivery back. Resolves to true
/// only when the courier confirms.
Future<bool> confirmRelease(BuildContext context, Order order) async {
  final confirmed = await showDialog<bool>(
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
                'Release this delivery?',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'It goes back to the list for other couriers, and you '
                'won\'t be paid the ${formatCents(order.totalPayCents)}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Keep delivery',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Release',
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
  return confirmed ?? false;
}
