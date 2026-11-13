import 'package:flutter/material.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../quick_add/presentation/quick_add_sheet.dart';
import '../../quick_add/presentation/widgets/quick_add_toast.dart';
import '../application/transactions_list_providers.dart';
import '../domain/transaction_entry.dart';

/// Log tag of everything the Transactions screens do.
const String transactionsLogTag = 'transactions';

/// How long the "Entry deleted" toast waits for Undo.
const Duration transactionUndoDuration = Duration(seconds: 5);

/// Shows a toast (ink, radius 18) through [messenger]. The Undo action is
/// optional. Taking the messenger (not the context) lets a toast show after
/// the screen that started it has been popped.
void showTransactionToast(
  ScaffoldMessengerState messenger,
  String message, {
  VoidCallback? onUndo,
}) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: QuickAddToastContent(message: message, onUndo: onUndo),
      duration: transactionUndoDuration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.all(AppSpacing.space6),
    ),
  );
}

/// Soft deletes [entry] and shows "Entry deleted" with Undo. Returns `true`
/// when the delete worked. Logs the outcome without any amount, name or note.
Future<bool> deleteEntryWithUndo({
  required TransactionActions actions,
  required ScaffoldMessengerState messenger,
  required AppLogger log,
  required TransactionEntry entry,
}) async {
  final bool deleted = await actions.delete(entry.id);
  if (!deleted) {
    log.warning(transactionsLogTag, 'delete failed');
    showTransactionToast(messenger, 'Could not delete. Please try again.');
    return false;
  }
  log.info(transactionsLogTag, 'entry deleted');
  showTransactionToast(
    messenger,
    'Entry deleted',
    onUndo: () async {
      final bool restored = await actions.undoDelete(entry.id);
      log.info(transactionsLogTag, restored ? 'delete undone' : 'undo failed');
      showTransactionToast(
        messenger,
        restored ? 'Entry restored' : 'Could not undo. Please try again.',
      );
    },
  );
  return true;
}

/// Opens Quick Add in edit mode for [entry]. The row or detail springs back
/// on its own; the saved toast comes from the shell.
Future<void> openEditEntry(
  BuildContext context,
  AppLogger log,
  TransactionEntry entry,
) async {
  log.info(transactionsLogTag, 'edit opened');
  await QuickAddSheet.show(context, edit: entry);
}

/// Opens Quick Add for a new entry (same path as the bottom bar button).
Future<void> openAddEntry(BuildContext context, AppLogger log) async {
  log.info('quick_add', 'sheet opened');
  await QuickAddSheet.show(context);
}

/// The message of a failed save action, or a plain fallback.
String failureMessage(Object error) =>
    error is DataFailure ? error.message : 'Something went wrong. Try again.';
