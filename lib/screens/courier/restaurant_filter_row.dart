import 'package:flutter/material.dart';

import 'request_sort_bar.dart';

/// K-36: "All" plus one chip per restaurant with open requests, in a row
/// that scrolls sideways so it never takes more than one line.
class RestaurantFilterRow extends StatelessWidget {
  const RestaurantFilterRow({
    super.key,
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  /// Restaurant name to number of open requests, already sorted.
  final Map<String, int> counts;
  final String? selected;

  /// Called with the restaurant, or null for "All".
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterPill(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final MapEntry(key: name, value: count) in counts.entries) ...[
            const SizedBox(width: 8),
            FilterPill(
              label: '$name · $count',
              icon: Icons.storefront_outlined,
              selected: selected == name,
              // Tapping the selected restaurant again goes back to All.
              onTap: () => onSelected(selected == name ? null : name),
            ),
          ],
        ],
      ),
    );
  }
}
