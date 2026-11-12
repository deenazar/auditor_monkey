// Quick Add notifier: API note for the UI.
//
// Providers (all autoDispose, one set per open sheet):
//   quickAddProvider      NotifierProvider<QuickAddNotifier, QuickAddState>
//                         what the user did (type, amount, date, note, picks,
//                         hint, save status).
//   quickAddDataProvider  FutureProvider<QuickAddData>: accounts, categories
//                         (suggested first), recent entries, defaults.
//   quickAddViewProvider  QuickAddView: state + data merged. READ THIS TO
//                         DRAW: current account / To / category (pick ??
//                         default), canSave, save label, transferAvailable.
//   quickAddUndoProvider  QuickAddUndo: `await ref.read(...)(entryId)`.
//
// Call (ref.read(quickAddProvider.notifier).xxx):
//   setType(TransactionType)       Transfer is ignored (returns false) when
//                                  fewer than 2 accounts are offered.
//   pressDigit('0'..'9'), pressDot(), backspace(), clear()  (long-press
//                                  backspace), paste(clipboardText).
//   pickCategory(id)               expense / income.
//   pickAccount(id)                expense / income account.
//   pickFrom(id), pickTo(id)       transfer; picking the other side's
//                                  account swaps them. swapAccounts().
//   setDate('YYYY-MM-DD'), setNote(text), applyRecent(entry) (keeps date),
//   clearError(), save() (safe to call twice: one row).
//
// State to watch: status (idle / saving / failed / done), saveError (plain
// message for the error card; cleared by the next edit), amountHint +
// refusalCount (nudge + hint under the amount), saved (id, type, paise)
// when status is done. The sheet closes itself on done and returns `saved`.
// Everything is ignored while status is saving or done.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import '../../transactions/application/transactions_providers.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../domain/amount_input.dart';
import '../domain/quick_add_defaults.dart';
import '../domain/quick_add_validator.dart';
import 'quick_add_data_provider.dart';
import 'quick_add_resolve.dart';
import 'quick_add_state.dart';

const String _tag = 'quick_add';
const String _genericSaveError = 'Could not save. Please try again.';

final NotifierProvider<QuickAddNotifier, QuickAddState> quickAddProvider =
    NotifierProvider.autoDispose<QuickAddNotifier, QuickAddState>(
      QuickAddNotifier.new,
    );

class QuickAddNotifier extends Notifier<QuickAddState> {
  AppLogger get _log => ref.read(loggerProvider);

  QuickAddData? get _data => ref.read(quickAddDataProvider).value;

  bool get _locked =>
      state.status == SaveStatus.saving || state.status == SaveStatus.done;

  @override
  QuickAddState build() {
    // Keep the data alive (and loading) as long as the sheet is open.
    ref.listen(quickAddDataProvider, (_, _) {});
    final String today = dateKey(
      DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs()),
    );
    return QuickAddState(
      type: TransactionType.expense,
      today: today,
      date: today,
    );
  }

  // Type.

  bool setType(TransactionType type) {
    if (_locked || type == state.type) return !_locked;
    final QuickAddData? data = _data;
    if (type == TransactionType.transfer &&
        data != null &&
        !data.transferAvailable) {
      return false;
    }
    _log.debug(_tag, 'tab changed to ${type.name}');
    state = state.copyWith(type: type, clearHint: true, clearError: true);
    return true;
  }

  // Number pad.

  void pressDigit(String digit) => _edit(state.amount.pressDigit(digit));

  void pressDot() => _edit(state.amount.pressDot());

  void backspace() {
    if (_locked) return;
    state = state.copyWith(
      amount: state.amount.backspace(),
      clearHint: true,
      clearError: true,
    );
  }

  void clear() {
    if (_locked) return;
    state = state.copyWith(
      amount: const AmountInput(),
      clearHint: true,
      clearError: true,
    );
  }

  void paste(String? clipboardText) => _edit(state.amount.paste(clipboardText));

  void _edit(AmountEdit edit) {
    if (_locked) return;
    if (edit.refused) {
      state = state.copyWith(
        amountHint: edit.refusal,
        refusalCount: state.refusalCount + 1,
        clearError: true,
      );
      return;
    }
    state = state.copyWith(
      amount: edit.input,
      clearHint: true,
      clearError: true,
    );
  }

  // Picks.

  void pickCategory(String id) =>
      _setPicks(state.type, (Picks p) => p.copyWith(categoryId: id));

  void pickAccount(String id) => state.type == TransactionType.transfer
      ? pickFrom(id)
      : _setPicks(state.type, (Picks p) => p.copyWith(accountId: id));

  void pickFrom(String id) {
    final DefaultPicks now = _resolved(TransactionType.transfer);
    final bool swap = now.toAccountId == id && now.accountId != null;
    _setPicks(
      TransactionType.transfer,
      (Picks p) => swap
          ? p.copyWith(accountId: id, toAccountId: now.accountId)
          : p.copyWith(accountId: id),
    );
  }

  void pickTo(String id) {
    final DefaultPicks now = _resolved(TransactionType.transfer);
    final bool swap = now.accountId == id && now.toAccountId != null;
    _setPicks(
      TransactionType.transfer,
      (Picks p) => swap
          ? p.copyWith(accountId: now.toAccountId, toAccountId: id)
          : p.copyWith(toAccountId: id),
    );
  }

  void swapAccounts() {
    final DefaultPicks now = _resolved(TransactionType.transfer);
    final String? from = now.accountId;
    final String? to = now.toAccountId;
    if (from == null || to == null) return;
    _setPicks(
      TransactionType.transfer,
      (Picks p) => p.copyWith(accountId: to, toAccountId: from),
    );
  }

  DefaultPicks _resolved(TransactionType type) =>
      resolvePicks(type, state.picksOf(type), _data);

  void _setPicks(TransactionType type, Picks Function(Picks) change) {
    if (_locked) return;
    state = state.copyWith(
      picks: <TransactionType, Picks>{
        ...state.picks,
        type: change(state.picksOf(type)),
      },
      clearError: true,
    );
  }

  // Details.

  void setDate(String date) {
    if (_locked || !isValidDate(date)) return;
    state = state.copyWith(date: date, clearError: true);
  }

  void setNote(String note) {
    if (_locked) return;
    state = state.copyWith(note: note, clearError: true);
  }

  void clearError() {
    if (state.saveError == null || _locked) return;
    state = state.copyWith(clearError: true, status: SaveStatus.idle);
  }

  /// Fills type, amount, accounts, category and note from a past entry. The
  /// date stays. Does not save.
  void applyRecent(TransactionEntry entry) {
    if (_locked) return;
    final QuickAddData? data = _data;
    if (entry.type == TransactionType.transfer &&
        data != null &&
        !data.transferAvailable) {
      return;
    }
    final int index =
        data?.recent.indexWhere((TransactionEntry e) => e.id == entry.id) ?? -1;
    _log.debug(_tag, 'recent entry used index=$index');
    state = state.copyWith(
      type: entry.type,
      amount: AmountInput.fromPaise(entry.amount),
      note: entry.note ?? '',
      picks: <TransactionType, Picks>{
        ...state.picks,
        entry.type: Picks(
          accountId: entry.accountId,
          toAccountId: entry.toAccountId,
          categoryId: entry.categoryId,
        ),
      },
      clearHint: true,
      clearError: true,
    );
  }

  // Save.

  /// Validates and saves. A second call while saving (or after done) does
  /// nothing: the status changes before any `await`.
  Future<void> save() async {
    if (_locked) return;
    final QuickAddData? data = _data;
    if (data == null) return; // Save is disabled while loading.
    final TransactionType type = state.type;
    final DefaultPicks p = _resolved(type);
    final QuickAddForm form = QuickAddForm(
      type: type,
      amountPaise: state.amount.paise,
      date: state.date,
      today: state.today,
      note: state.note,
      accountId: p.accountId,
      toAccountId: p.toAccountId,
      categoryId: p.categoryId,
      offeredAccountIds: data.accountIds,
      offeredCategoryIds: data.categoryIdsOf(type),
    );
    final QuickAddIssue? issue = validateQuickAdd(form);
    if (issue != null) {
      state = state.copyWith(saveError: issue.message);
      return;
    }
    state = state.copyWith(status: SaveStatus.saving, clearError: true);
    _log.info(_tag, 'save started type=${type.name}');
    final Stopwatch watch = Stopwatch()..start();
    try {
      final TransactionEntry saved = await ref
          .read(transactionsRepositoryProvider)
          .create(buildQuickAddDraft(form));
      _log.info(
        _tag,
        'save done type=${type.name} ms=${watch.elapsedMilliseconds}',
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        status: SaveStatus.done,
        saved: SavedEntry(id: saved.id, type: type, amount: saved.amount),
      );
    } on DataFailure catch (failure) {
      _log.warning(_tag, 'save failed: ${failure.code.name}');
      _fail(failure.message);
    } on Object {
      _log.warning(_tag, 'save failed: unknown');
      _fail(_genericSaveError);
    }
  }

  void _fail(String message) {
    if (!ref.mounted) return;
    state = state.copyWith(status: SaveStatus.failed, saveError: message);
  }
}
