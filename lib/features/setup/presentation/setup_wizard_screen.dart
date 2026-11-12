import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_view.dart';

/// PLACEHOLDER (senior-dev). junior-dev replaces this file with the real
/// wizard (J3). Keep the class name and the const constructor: the router
/// uses `const SetupWizardScreen()`.
class SetupWizardScreen extends StatelessWidget {
  const SetupWizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PlaceholderView(
        eyebrow: 'Welcome',
        title: 'Set up your accounts',
        message: 'The setup wizard will show up here.',
      ),
    );
  }
}
