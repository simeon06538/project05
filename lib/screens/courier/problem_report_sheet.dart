import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';

/// What the courier chose in the problem sheet.
typedef ProblemReport = ({DeliveryProblem problem, String details});

/// K-51: bottom sheet to pick what went wrong with [order]. Resolves to
/// the report, or null if the courier closes it.
Future<ProblemReport?> showProblemReportSheet(
  BuildContext context,
  Order order,
) {
  return showModalBottomSheet<ProblemReport>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProblemSheet(order: order),
  );
}

class _ProblemSheet extends StatefulWidget {
  const _ProblemSheet({required this.order});

  final Order order;

  @override
  State<_ProblemSheet> createState() => _ProblemSheetState();
}

class _ProblemSheetState extends State<_ProblemSheet> {
  DeliveryProblem? _choice;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = DeliveryProblem.optionsFor(widget.order.status);
    final textTheme = Theme.of(context).textTheme;
    final choice = _choice;
    return Padding(
      // Lift the sheet above the keyboard while typing details.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GlassPanel(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Report a problem',
                      style: textTheme.titleMedium?.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<DeliveryProblem>(
                      groupValue: choice,
                      onChanged: (value) => setState(() => _choice = value),
                      child: Column(
                        children: [
                          for (final option in options)
                            RadioListTile<DeliveryProblem>(
                              value: option,
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.accentSoft,
                              title: Text(
                                option.label,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: option.cancelsOrder
                                  ? Text(
                                      'Cancels the order. No pay, no penalty.',
                                      style: textTheme.bodySmall,
                                    )
                                  : null,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _details,
                      maxLength: 120,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Details (optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: choice?.cancelsOrder ?? false
                          ? 'Cancel order'
                          : 'Send report',
                      onPressed: choice == null
                          ? null
                          : () => Navigator.of(context)
                                .pop((problem: choice, details: _details.text)),
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
