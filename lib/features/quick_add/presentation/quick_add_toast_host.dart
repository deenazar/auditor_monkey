import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../shared/theme/app_motion.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../application/quick_add_state.dart';
import '../application/quick_add_undo.dart';

/// Shows the "saved" toast through the shell's [ScaffoldMessenger]: it
/// floats above the nav bar for [AppMotion.toastDuration] with Undo.
/// Undo soft deletes the entry and shows "Entry removed".
///
/// Wave 2: the content becomes the `QuickAddToast` widget; the messenger,
/// duration and Undo wiring stay.
void showSavedToast(
  BuildContext context,
  SavedEntry saved, {
  required QuickAddUndo undo,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String label = switch (saved.type) {
    TransactionType.expense => 'Expense',
    TransactionType.income => 'Income',
    TransactionType.transfer => 'Transfer',
  };
  _show(
    messenger,
    context,
    '$label saved · ${formatPaise(saved.amount)}',
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () async {
        final bool removed = await undo(saved.id);
        messenger.hideCurrentSnackBar();
        if (!context.mounted) return;
        _show(
          messenger,
          context,
          removed ? 'Entry removed' : 'Could not undo. Please try again.',
        );
      },
    ),
  );
}

void _show(
  ScaffoldMessengerState messenger,
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: AppMotion.toastDuration,
      action: action,
    ),
    snackBarAnimationStyle: AnimationStyle(
      duration: AppMotion.resolve(context, AppMotion.durationMedium),
      reverseDuration: AppMotion.resolve(context, AppMotion.durationFast),
      curve: AppMotion.curveEnter,
      reverseCurve: AppMotion.curveExit,
    ),
  );
}
