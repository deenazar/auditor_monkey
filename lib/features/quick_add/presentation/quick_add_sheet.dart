import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_motion.dart';
import '../application/quick_add_notifier.dart';
import '../application/quick_add_state.dart';
import 'quick_add_keys.dart';
import 'quick_add_placeholder_body.dart';

/// The Quick Add bottom sheet: frame, hardware keys and close on success.
///
/// [show] returns the saved entry (for the toast) or `null` when the sheet
/// was closed without saving. Closing drops the draft without asking.
class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  /// Share of the available height the sheet uses.
  static const double heightFraction = 0.92;

  /// Opens the sheet: [AppMotion.durationMedium], [AppMotion.curveEnter];
  /// closes with [AppMotion.curveExit]. Zero durations with reduce motion.
  static Future<SavedEntry?> show(BuildContext context) {
    return showModalBottomSheet<SavedEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        duration: AppMotion.resolve(context, AppMotion.durationMedium),
        reverseDuration: AppMotion.resolve(context, AppMotion.durationMedium),
        curve: AppMotion.curveEnter,
        reverseCurve: AppMotion.curveExit,
      ),
      builder: (BuildContext context) => const QuickAddSheet(),
    );
  }

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  bool _closing = false;

  void _onStatus(SaveStatus? previous, SaveStatus next) {
    if (next != SaveStatus.done || _closing) return;
    _closing = true;
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
          heightFactor: QuickAddSheet.heightFraction,
          // Wave 2 swaps this for the final QuickAddBody.
          child: QuickAddPlaceholderBody(),
        ),
      ),
    );
  }
}
