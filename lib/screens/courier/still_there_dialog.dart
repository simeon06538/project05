import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';

/// K-45: asks an idle courier whether they're still taking requests.
/// Resolves to true for "I'm here", or false if [grace] runs out or they
/// choose to go offline.
Future<bool> askStillThere(
  BuildContext context, {
  required Duration grace,
}) async {
  final stay = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x99000000),
    builder: (_) => _StillThereDialog(grace: grace),
  );
  return stay ?? false;
}

class _StillThereDialog extends StatefulWidget {
  const _StillThereDialog({required this.grace});

  final Duration grace;

  @override
  State<_StillThereDialog> createState() => _StillThereDialogState();
}

class _StillThereDialogState extends State<_StillThereDialog> {
  late int _secondsLeft = widget.grace.inSeconds;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _countdown?.cancel();
        Navigator.of(context).pop(false);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
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
                'Still there?',
                style: textTheme.titleMedium?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'You haven\'t tapped anything in a while. To keep requests '
                'fair for other couriers, we\'ll set you offline in '
                '$_secondsLeft s.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: "I'm here",
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: const Text('Go offline'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
