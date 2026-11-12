import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../application/quick_add_notifier.dart';
import '../application/quick_add_view.dart';
import 'quick_add_frame.dart';

/// TEMPORARY plain body for wave 1 (frame + notifier wiring). Wave 2 replaces
/// it with the final `QuickAddBody` built from the presentational widgets.
class QuickAddPlaceholderBody extends ConsumerWidget {
  const QuickAddPlaceholderBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuickAddView view = ref.watch(quickAddViewProvider);
    final QuickAddNotifier n = ref.read(quickAddProvider.notifier);
    final String amount = view.state.amount.display;
    return QuickAddFrame(
      header: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Close',
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          for (final TransactionType t in TransactionType.values)
            TextButton(
              key: Key('type-${t.name}'),
              onPressed: () => n.setType(t),
              child: Text(t.name),
            ),
        ],
      ),
      amount: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
        child: Text(
          amount.isEmpty ? '₹0' : '₹$amount',
          key: const Key('amount'),
          textAlign: TextAlign.center,
          style: AppTextStyles.displayAmount,
        ),
      ),
      middle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (view.state.saveError != null)
            Text(
              view.state.saveError!,
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
            ),
          if (view.state.amountHint != null)
            Text(view.state.amountHint!.message),
          Wrap(
            spacing: AppSpacing.space2,
            children: <Widget>[
              for (final Category c
                  in view.data?.categoriesOf(view.type).all ??
                      const <Category>[])
                ChoiceChip(
                  key: Key('cat-${c.id}'),
                  label: Text(c.name),
                  selected: view.current.categoryId == c.id,
                  onSelected: (_) => n.pickCategory(c.id),
                ),
            ],
          ),
          if (view.data != null) Text('Recent: ${view.data!.recent.length}'),
        ],
      ),
      pad: Wrap(
        alignment: WrapAlignment.center,
        children: <Widget>[
          for (final String k in <String>[
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '.',
            '0',
            '<',
          ])
            TextButton(
              key: Key('pad-$k'),
              onPressed: () => switch (k) {
                '.' => n.pressDot(),
                '<' => n.backspace(),
                _ => n.pressDigit(k),
              },
              child: Text(k, style: AppTextStyles.headline),
            ),
        ],
      ),
      save: PrimaryButton(
        label: view.saveLabel,
        loading: view.state.isSaving,
        onPressed: view.canSave ? n.save : null,
      ),
    );
  }
}
