import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_panel.dart';

/// K-33: two quick checks at the counter before "Mark as picked up" is
/// allowed. Calls [onReadyChanged] with true once both are ticked.
class PickupChecklist extends StatefulWidget {
  const PickupChecklist({
    super.key,
    required this.order,
    required this.onReadyChanged,
  });

  final Order order;
  final ValueChanged<bool> onReadyChanged;

  @override
  State<PickupChecklist> createState() => _PickupChecklistState();
}

class _PickupChecklistState extends State<PickupChecklist> {
  bool _numberMatches = false;
  bool _sealed = false;

  void _update({bool? numberMatches, bool? sealed}) {
    setState(() {
      _numberMatches = numberMatches ?? _numberMatches;
      _sealed = sealed ?? _sealed;
    });
    widget.onReadyChanged(_numberMatches && _sealed);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _numberMatches && _sealed;
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Text(
              'Before pickup',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          _CheckRow(
            label: 'Order number matches ${widget.order.pawPointsOrderNumber}',
            value: _numberMatches,
            onChanged: (v) => _update(numberMatches: v),
          ),
          _CheckRow(
            label: 'Food is sealed and complete',
            value: _sealed,
            onChanged: (v) => _update(sealed: v),
          ),
          if (!ready)
            const Padding(
              padding: EdgeInsets.only(left: 8, top: 2),
              child: Text(
                'Tick both to mark the order as picked up.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: AppColors.accentStrong,
      checkColor: AppColors.textPrimary,
      side: const BorderSide(color: AppColors.accentSoft, width: 1.5),
      title: Text(
        label,
        style: TextStyle(
          color: value ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: value ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
