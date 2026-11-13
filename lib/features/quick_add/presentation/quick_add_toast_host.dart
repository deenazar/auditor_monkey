import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../shared/theme/app_motion.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../application/quick_add_state.dart';
import '../application/quick_add_undo.dart';
import 'widgets/quick_add_toast.dart';

/// Shows the "saved" toast through the shell's [ScaffoldMessenger]: it
/// floats above the nav bar for [AppMotion.toastDuration] with Undo.
/// Undo soft deletes the entry and shows "Entry removed".
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
  if (saved.edited) {
    // An edit has no Undo: the old values are gone once saved.
    _show(messenger, context, 'Changes saved', showCheck: true);
    return;
  }
  _show(
    messenger,
    context,
    '$label saved · ${formatPaise(saved.amount)}',
    showCheck: true,
    onUndo: () async {
      final bool removed = await undo(saved.id);
      messenger.hideCurrentSnackBar();
      if (!context.mounted) return;
      _show(
        messenger,
        context,
        removed ? 'Entry removed' : 'Could not undo. Please try again.',
      );
    },
  );
}

void _show(
  ScaffoldMessengerState messenger,
  BuildContext context,
  String message, {
  VoidCallback? onUndo,
  bool showCheck = false,
}) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    buildQuickAddToast(message: message, onUndo: onUndo, showCheck: showCheck),
    snackBarAnimationStyle: AnimationStyle(
      duration: AppMotion.resolve(context, AppMotion.durationMedium),
      reverseDuration: AppMotion.resolve(context, AppMotion.durationFast),
      curve: AppMotion.curveEnter,
      reverseCurve: AppMotion.curveExit,
    ),
  );
}
