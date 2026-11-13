import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../application/quick_add_data_provider.dart';
import '../application/quick_add_notifier.dart';
import '../application/quick_add_state.dart';
import '../application/quick_add_view.dart';
import '../domain/quick_add_defaults.dart';
import 'quick_add_mapping.dart';
import 'quick_add_pickers.dart';
import 'widgets/account_pill.dart';
import 'widgets/date_chips.dart';
import 'widgets/note_sheet.dart';
import 'widgets/quick_add_view_models.dart';

/// The details row: the account pill (expense and income only), the note
/// pill, and the date chips (Today, Yesterday, calendar).
class QuickAddDetails extends ConsumerWidget {
  const QuickAddDetails({
    required this.view,
    required this.balances,
    super.key,
  });

  final QuickAddView view;

  /// Account id to balance (paise), from the balance stream.
  final Map<String, int> balances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuickAddNotifier n = ref.read(quickAddProvider.notifier);
    final QuickAddData? data = view.data;
    final DefaultPicks current = view.current;
    final List<AccountOption> options = data == null
        ? const <AccountOption>[]
        : accountOptionsOf(data.accounts, balances);
    final AccountOption? account = optionById(options, current.accountId);
    final DateTime today = dayOf(view.state.today);
    final bool transfer = view.type == TransactionType.transfer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (!transfer && account != null)
              AccountPill(
                account: account,
                onTap: () => pickAccountSheet(
                  context,
                  title: 'Pick account',
                  accounts: options,
                  selectedId: current.accountId,
                  onPicked: n.pickAccount,
                ),
              ),
            NotePill(
              note: view.state.note,
              onTap: () => editNoteSheet(
                context,
                note: view.state.note,
                onDone: n.setNote,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        DateChips(
          selected: dayOf(view.state.date),
          today: today,
          firstDate: quickAddFirstDate,
          // An edited entry may already sit further ahead than the limit.
          lastDate: _lastDate(today, view.state),
          onChanged: (DateTime day) => n.setDate(dateKey(day)),
        ),
      ],
    );
  }
}

DateTime _lastDate(DateTime today, QuickAddState state) {
  final DateTime limit = quickAddLastDate(today);
  final DateTime own = dayOf(state.edit?.date ?? state.date);
  return own.isAfter(limit) ? own : limit;
}
