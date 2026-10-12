import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import 'tab_header.dart';

/// Demo earnings balance and history. Real numbers come in K-09.
class EarningsTab extends StatelessWidget {
  const EarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      children: [
        const TabHeader(
          title: 'Earnings',
          pill: 'Demo balance · delivery fee + tips',
        ),
        const SizedBox(height: 20),
        GlassPanel(
          child: Column(
            children: [
              const _SummaryRow(label: 'Demo balance', value: r'$0.00'),
              const SizedBox(height: 10),
              const _SummaryRow(label: 'Completed deliveries', value: '0'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0x33FFFFFF)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total earned', style: textTheme.titleMedium),
                  Text(r'$0.00', style: textTheme.titleMedium),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const GlassPanel(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          child: EmptyState(
            icon: Icons.savings_outlined,
            title: 'No completed deliveries yet',
            subtitle: 'Pay from each delivery is added here.',
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
