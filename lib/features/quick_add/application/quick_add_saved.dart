import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'quick_add_state.dart';

/// The entry Quick Add just saved, handed to the app shell so it can show
/// the toast with Undo. It lives outside the sheet on purpose: even when
/// the sheet is closed while the save is still running, the toast shows.
class QuickAddSavedNotifier extends Notifier<SavedEntry?> {
  @override
  SavedEntry? build() => null;

  void announce(SavedEntry entry) => state = entry;

  /// The shell calls this once it has shown the toast.
  void clear() => state = null;
}

final NotifierProvider<QuickAddSavedNotifier, SavedEntry?>
quickAddSavedProvider = NotifierProvider<QuickAddSavedNotifier, SavedEntry?>(
  QuickAddSavedNotifier.new,
);
