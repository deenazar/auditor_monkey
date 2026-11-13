import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quick_add/application/quick_add_state.dart';

/// The last entry saved from Quick Add, kept for the monkey on Home (the
/// shell clears the toast's own provider right away). [serial] grows on
/// every save so the same amount twice still counts.
class SavedForMascot {
  const SavedForMascot(this.entry, this.serial);
  final SavedEntry entry;
  final int serial;
}

class MascotEventsNotifier extends Notifier<SavedForMascot?> {
  @override
  SavedForMascot? build() => null;

  void saved(SavedEntry entry) =>
      state = SavedForMascot(entry, (state?.serial ?? 0) + 1);
}

final NotifierProvider<MascotEventsNotifier, SavedForMascot?>
mascotEventsProvider = NotifierProvider<MascotEventsNotifier, SavedForMascot?>(
  MascotEventsNotifier.new,
);
