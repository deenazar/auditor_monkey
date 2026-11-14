import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/transaction_filter.dart';
import 'save_filter_field.dart';

/// Asks for a chip name in a small dialog and saves [filter] as a chip.
Future<void> showSaveFilterDialog(
  BuildContext context,
  TransactionFilter filter,
) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      backgroundColor: AppColors.background,
      title: const Text('Save as chip'),
      content: SizedBox(
        width: 320,
        child: SaveFilterField(
          filter: filter,
          onSaved: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  );
}
