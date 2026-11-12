import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_view.dart';

/// Placeholder for the Accounts screen (built in a later session).
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderView(
      eyebrow: 'Your Wallet',
      title: 'Accounts',
      message: 'Your accounts will show up here.',
    );
  }
}
