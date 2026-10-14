import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';

/// Glass "did you hand it over?" check before marking delivered, since
/// that pays out and can't be undone. K-34: also takes an optional
/// drop-off note. Resolves to the note ('' if none) on confirm, or null
/// if the courier backs out.
Future<String?> confirmDelivered(BuildContext context, Order order) {
  return showDialog<String>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (context) => _DeliveredDialog(order: order),
  );
}

class _DeliveredDialog extends StatefulWidget {
  const _DeliveredDialog({required this.order});

  final Order order;

  @override
  State<_DeliveredDialog> createState() => _DeliveredDialogState();
}

class _DeliveredDialogState extends State<_DeliveredDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: GlassPanel(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
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
                const SizedBox(height: 16),
                TextField(
                  controller: _note,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Drop-off note (optional)',
                    hintText: 'e.g. Left with the front desk',
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Yes, delivered',
                  onPressed: () => Navigator.of(context).pop(_note.text.trim()),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
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
  }
}
