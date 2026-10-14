import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';
import '../../models/order.dart';
import 'courier_header.dart';
import 'daily_goal_ring.dart';
import 'detail_widgets.dart';
import 'request_sort_bar.dart';

/// K-31: change the display name and reset the demo data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.name,
    required this.onNameChanged,
    this.onResetDemo,
    this.dailyGoalCents,
    this.onDailyGoalChanged,
  });

  final String name;
  final ValueChanged<String> onNameChanged;

  /// Only offered while the app runs on the demo (mock) service.
  final VoidCallback? onResetDemo;

  /// K-41: current daily goal and where to send a new one.
  final int? dailyGoalCents;
  final ValueChanged<int>? onDailyGoalChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _maxNameLength = 30;

  late final _nameController = TextEditingController(text: widget.name);
  late String _savedName = widget.name;
  late int? _goalCents = widget.dailyGoalCents;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _draft => _nameController.text.trim();
  bool get _canSave => _draft.isNotEmpty && _draft != _savedName;

  void _saveName() {
    FocusScope.of(context).unfocus();
    widget.onNameChanged(_draft);
    setState(() => _savedName = _draft);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Name updated to $_draft')));
  }

  Future<void> _resetDemo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundTop,
        title: const Text('Reset demo data?'),
        content: const Text(
          'Open requests, your active delivery and earnings go back to how '
          'the demo started.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    widget.onResetDemo!();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Demo data reset')));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // Header stays pinned so Back is always reachable.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        GlassBackButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        Text('Settings', style: textTheme.headlineSmall),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        const SectionLabel('Profile'),
                        GlassPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Live preview of how the header will look.
                              CourierHeader(
                                name: _draft.isEmpty ? '?' : _draft,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _nameController,
                                maxLength: _maxNameLength,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Display name',
                                  errorText: _draft.isEmpty
                                      ? 'Enter a name customers will see'
                                      : null,
                                ),
                                onSubmitted: (_) {
                                  if (_canSave) _saveName();
                                },
                              ),
                              const SizedBox(height: 8),
                              PrimaryButton(
                                label: 'Save name',
                                onPressed: _canSave ? _saveName : null,
                              ),
                            ],
                          ),
                        ),
                        if (widget.onDailyGoalChanged != null) ...[
                          const SizedBox(height: 20),
                          const SectionLabel('Daily goal'),
                          GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'How much do you want to earn each day?',
                                  style: textTheme.bodyMedium,
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    for (final cents in dailyGoalOptionsCents)
                                      FilterPill(
                                        label: formatCents(cents),
                                        selected: cents == _goalCents,
                                        onTap: () {
                                          setState(() => _goalCents = cents);
                                          widget.onDailyGoalChanged!(cents);
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (widget.onResetDemo != null) ...[
                          const SizedBox(height: 20),
                          const SectionLabel('Demo'),
                          GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Start the class demo over with the original '
                                  'requests and earnings.',
                                  style: textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _resetDemo,
                                  icon: const Icon(Icons.restart_alt_rounded),
                                  label: const Text('Reset demo data'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          'Campus Delivery · class prototype · no money is '
                          'transferred.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
