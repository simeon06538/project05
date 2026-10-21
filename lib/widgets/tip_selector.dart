import 'package:flutter/material.dart';

import 'glass_panel.dart';

/// C-08: optional demo tip. Null means the custom amount is not valid.
class TipSelector extends StatefulWidget {
  const TipSelector({super.key, required this.onChanged});
  final ValueChanged<int?> onChanged;

  @override
  State<TipSelector> createState() => _TipSelectorState();
}

class _TipSelectorState extends State<TipSelector> {
  final _custom = TextEditingController();
  int? _preset = 0;

  int? _customCents() {
    final value = _custom.text.trim();
    if (!RegExp(r'^(\d+(\.\d{1,2})?|\.\d{1,2})$').hasMatch(value)) return null;
    final parts = value.split('.');
    final dollars = int.tryParse(parts[0].isEmpty ? '0' : parts[0]);
    if (dollars == null || dollars > 50) return null;
    final cents =
        dollars * 100 +
        (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
    return cents <= 5000 ? cents : null;
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GlassPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Optional tip', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final amount in [0, 1, 2, 3])
              ChoiceChip(
                label: Text('\$$amount'),
                selected: _preset == amount,
                onSelected: (_) {
                  setState(() => _preset = amount);
                  widget.onChanged(amount * 100);
                },
              ),
            ChoiceChip(
              label: const Text('Custom'),
              selected: _preset == null,
              onSelected: (_) {
                setState(() => _preset = null);
                widget.onChanged(_customCents());
              },
            ),
          ],
        ),
        if (_preset == null) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _custom,
            decoration: InputDecoration(
              labelText: 'Custom tip',
              prefixText: '\$',
              helperText: 'Optional · Maximum \$50.00',
              errorText: _customCents() == null
                  ? 'Enter \$0–\$50 with up to 2 decimal places'
                  : null,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              setState(() {});
              widget.onChanged(_customCents());
            },
          ),
        ],
        const SizedBox(height: 12),
        const Text(
          'The delivery fee and your tip go to the courier’s demo earnings.',
        ),
      ],
    ),
  );
}
