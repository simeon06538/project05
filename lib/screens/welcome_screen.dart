import 'package:flutter/material.dart';

import '../models/user.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';
import '../widgets/glass_tab_bar.dart';
import '../widgets/primary_button.dart';

/// C-02: local demo entry; this does not authenticate a server account.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onContinue,
    this.initialName = '',
    this.initialRole = UserRole.customer,
  });

  final void Function(String name, UserRole role) onContinue;
  final String initialName;
  final UserRole initialRole;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late UserRole _role = widget.initialRole;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _continue() {
    if (_form.currentState!.validate()) {
      widget.onContinue(_name.text.trim(), _role);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.delivery_dining, size: 64),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome to Campus Delivery',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'What would you like to do today?',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    GlassPanel(
                      child: TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Your name',
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        maxLength: 100,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter your name to continue'
                            : null,
                        onFieldSubmitted: (_) => _continue(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassTabBar(
                      labels: const ['Customer', 'Courier'],
                      icons: const [
                        Icons.shopping_bag_outlined,
                        Icons.delivery_dining,
                      ],
                      selectedIndex: _role.index,
                      onSelected: (index) =>
                          setState(() => _role = UserRole.values[index]),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _role == UserRole.customer
                          ? 'Get your campus food delivered. Food is paid separately with Paw Points.'
                          : 'Accept delivery requests and earn a demo delivery fee plus tips.',
                    ),
                    const SizedBox(height: 12),
                    const Text('You can switch roles later using Switch role.'),
                    const SizedBox(height: 8),
                    const Text(
                      'Use the same name to reopen your saved demo requests.',
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(label: 'Continue', onPressed: _continue),
                    const SizedBox(height: 16),
                    const Text(
                      'Class demo · No password or real payments',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
