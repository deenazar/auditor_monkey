import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_motion.dart';
import '../../../shared/theme/app_sizes.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../application/quick_add_edit.dart';
import '../application/quick_add_notifier.dart';
import '../application/quick_add_state.dart';
import 'quick_add_body.dart';
import 'quick_add_keys.dart';

/// The Quick Add bottom sheet: frame, hardware keys and close on success.
///
/// [show] returns the saved entry (for the toast) or `null` when the sheet
/// was closed without saving. Closing drops the draft without asking.
class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  /// With [edit] the sheet edits that entry (title "Edit entry", save label
  /// "Save changes", no recent strip); otherwise it adds a new one.
  ///
  /// Opens with the [AppMotion.sheetSpring] curve (about 350ms, slight
  /// overshoot); the sheet is usable from its first frame. Closes in
  /// [AppMotion.durationMedium] with [AppMotion.curveExit]. Zero durations
  /// with reduce motion.
  static Future<SavedEntry?> show(
    BuildContext context, {
    TransactionEntry? edit,
  }) {
    final QuickAddEditNotifier? editing = edit == null
        ? null
        : ProviderScope.containerOf(
            context,
            listen: false,
          ).read(quickAddEditProvider.notifier);
    if (edit != null) editing!.begin(edit);
    return showModalBottomSheet<SavedEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        duration: AppMotion.resolve(context, AppMotion.durationSheetOpen),
        reverseDuration: AppMotion.resolve(context, AppMotion.durationMedium),
        curve: AppMotion.sheetSpringCurve,
        reverseCurve: AppMotion.curveExit,
      ),
      builder: (BuildContext context) => const QuickAddSheet(),
    ).whenComplete(() {
      if (edit != null) editing!.end(edit);
    });
  }

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  bool _closing = false;

  void _onStatus(SaveStatus? previous, SaveStatus next) {
    if (next != SaveStatus.done || _closing) return;
    _closing = true;
    // Already closing (for example a swipe-down during the save): the toast
    // comes from the shell, and a second pop would close the page below.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(context).pop(ref.read(quickAddProvider).saved);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SaveStatus>(
      quickAddProvider.select((QuickAddState s) => s.status),
      _onStatus,
    );
    final bool saving = ref.watch(
      quickAddProvider.select((QuickAddState s) => s.isSaving),
    );
    // Android back (and a tap outside) is held while the save runs.
    return PopScope(
      canPop: !saving,
      child: Focus(
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) =>
            handleQuickAddKey(event, ref.read(quickAddProvider.notifier)),
        child: const FractionallySizedBox(
          heightFactor: AppSizes.quickAddSheetHeightFraction,
          child: QuickAddBody(),
        ),
      ),
    );
  }
}
