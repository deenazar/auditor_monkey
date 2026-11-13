import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_view.dart';

/// Placeholder for the Transactions screen (built in a later session).
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderView(
      eyebrow: 'Your Activity',
      title: 'Transactions',
      message: 'No transactions yet.',
      illustration: 'empty_transactions',
    );
  }
}
