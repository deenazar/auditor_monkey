import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../application/quick_add_notifier.dart';
import '../application/quick_add_view.dart';
import '../domain/amount_input.dart' show AmountRefusal;
import 'quick_add_frame.dart';
import 'quick_add_middle.dart';
import 'quick_add_save_bar.dart';
import 'widgets/amount_display.dart';
import 'widgets/number_pad.dart';
import 'widgets/type_tabs.dart';

/// The Quick Add sheet content (DESIGN.md Quick Add, sec. 3): close and
/// type tabs on top, the amount, a scrolling middle (recent, categories or
/// accounts, details), the number pad and Save at the bottom.
///
/// While a save runs, the middle, the tabs and the pad are read-only.
class QuickAddBody extends ConsumerWidget {
  const QuickAddBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuickAddView view = ref.watch(quickAddViewProvider);
    final QuickAddNotifier n = ref.read(quickAddProvider.notifier);
    final bool saving = view.state.isSaving;
    final AmountRefusal? hint = view.state.amountHint;
    return QuickAddFrame(
      header: _Header(
        view: view,
        locked: saving,
        onClose: () => Navigator.of(context).maybePop(),
        onType: n.setType,
      ),
      amount: AmountDisplay(
        text: view.state.amount.text,
        type: view.type,
        hint: hint?.message,
        isError: hint != null,
        refuseTick: view.state.refusalCount,
        paise: view.state.amount.paise,
        rollTick: view.state.recentTick,
        onPaste: n.paste,
      ),
      middle: IgnorePointer(
        ignoring: saving,
        child: QuickAddMiddle(view: view),
      ),
      pad: NumberPad(
        enabled: !saving,
        onDigit: n.pressDigit,
        onDot: n.pressDot,
        onBackspace: n.backspace,
        onClear: n.clear,
      ),
      save: QuickAddSaveBar(view: view),
    );
  }
}

/// Close (left, 44 target) and the type tabs (centred).
class _Header extends StatelessWidget {
  const _Header({
    required this.view,
    required this.locked,
    required this.onClose,
    required this.onType,
  });

  final QuickAddView view;
  final bool locked;
  final VoidCallback onClose;
  final ValueChanged<TransactionType> onType;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IconButton(
          tooltip: 'Close',
          constraints: const BoxConstraints.tightFor(
            width: AppSpacing.minTapTarget,
            height: AppSpacing.minTapTarget,
          ),
          icon: const Icon(LucideIcons.x, color: AppColors.ink),
          onPressed: onClose,
        ),
        Expanded(
          child: IgnorePointer(
            ignoring: locked,
            child: TypeTabs(
              selected: view.type,
              transferEnabled: view.transferAvailable,
              onChanged: onType,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.minTapTarget),
      ],
    );
  }
}
