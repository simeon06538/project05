import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';

/// K-47: the customer's star rating and thank-you note for a delivery.
class CustomerRatingPanel extends StatelessWidget {
  const CustomerRatingPanel({super.key, required this.rating, this.note});

  final int rating;
  final String? note;

  static const _starGold = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Rated $rating out of 5 stars',
            excludeSemantics: true,
            child: Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 26,
                    color: i <= rating ? _starGold : AppColors.textMuted,
                  ),
                const SizedBox(width: 8),
                Text(
                  '$rating.0',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (note case final note?) ...[
            const SizedBox(height: 8),
            Text(
              '"$note"',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
