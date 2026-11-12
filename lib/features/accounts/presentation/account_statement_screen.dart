import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_view.dart';

/// PLACEHOLDER (senior-dev). junior-dev replaces this file with the real
/// statement screen (J5). Keep the class name and the constructor: the
/// router uses `AccountStatementScreen(accountId: id)`. The id comes from
/// the URL and may be malformed; the screen must show the "not found"
/// state for that (the provider throws `NotFoundFailure`).
class AccountStatementScreen extends StatelessWidget {
  const AccountStatementScreen({required this.accountId, super.key});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return const PlaceholderView(
      eyebrow: 'Account',
      title: 'Statement',
      message: 'The account statement will show up here.',
    );
  }
}
