import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';

/// Glass "did you hand it over?" check before marking delivered, since
/// that pays out and can't be undone. Resolves to true on confirm.
Future<bool> confirmDelivered(BuildContext context, Order order) async {
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
                'Mark as delivered?',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Only confirm once the food is in the customer\'s hands at '
                '${order.dropoffLocation}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Added to your earnings',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                label: 'Yes, delivered',
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Not yet',
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
