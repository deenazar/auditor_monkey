import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transactions/domain/transaction_entry.dart';

/// The entry the Quick Add sheet is about to edit, or `null` to add a new
/// one. `QuickAddSheet.show(context, edit: entry)` sets it before the sheet
/// opens and clears it when the sheet closes; the notifier and the data
/// provider read it once when they build.
class QuickAddEditNotifier extends Notifier<TransactionEntry?> {
  @override
  TransactionEntry? build() => null;

  void begin(TransactionEntry entry) => state = entry;

  /// Clears only when [entry] is still the one being edited.
  void end(TransactionEntry entry) {
    if (identical(state, entry)) state = null;
  }
}

final NotifierProvider<QuickAddEditNotifier, TransactionEntry?>
quickAddEditProvider =
    NotifierProvider<QuickAddEditNotifier, TransactionEntry?>(
      QuickAddEditNotifier.new,
    );
