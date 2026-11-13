import '../../transactions/domain/transaction_entry.dart';
import '../domain/amount_input.dart';

enum SaveStatus { idle, saving, failed, done }

/// The user's OWN choices for one type. Null = "not chosen, use the
/// default". Defaults that arrive late never overwrite a choice.
class Picks {
  const Picks({this.accountId, this.toAccountId, this.categoryId});

  static const Picks none = Picks();

  final String? accountId;
  final String? toAccountId;
  final String? categoryId;

  Picks copyWith({
    String? accountId,
    String? toAccountId,
    String? categoryId,
  }) => Picks(
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId ?? this.toAccountId,
    categoryId: categoryId ?? this.categoryId,
  );
}

/// What was saved (for the toast and Undo).
class SavedEntry {
  const SavedEntry({
    required this.id,
    required this.type,
    required this.amount,
    this.edited = false,
  });

  final String id;
  final TransactionType type;

  /// Paise.
  final int amount;

  /// True when an existing entry was changed (edit mode). The toast says
  /// "Changes saved" with no Undo, and the monkey does not react.
  final bool edited;
}

/// What the user did in this sheet. Amount, date and note are shared by the
/// three tabs; picks are kept per type.
class QuickAddState {
  const QuickAddState({
    required this.type,
    required this.today,
    required this.date,
    this.amount = const AmountInput(),
    this.note = '',
    this.picks = const <TransactionType, Picks>{},
    this.amountHint,
    this.refusalCount = 0,
    this.recentTick = 0,
    this.status = SaveStatus.idle,
    this.saveError,
    this.saved,
    this.edit,
  });

  final TransactionType type;

  /// `YYYY-MM-DD`, read from the clock when the sheet opened.
  final String today;

  /// `YYYY-MM-DD` of the entry (starts as [today]).
  final String date;
  final AmountInput amount;
  final String note;
  final Map<TransactionType, Picks> picks;

  /// Why the last key was refused. Cleared by the next accepted edit.
  final AmountRefusal? amountHint;

  /// Grows with every refusal, so the screen can nudge again even when the
  /// hint text is the same.
  final int refusalCount;

  /// Grows only when a recent entry is applied (never when typing), so the
  /// amount rolls to the entry's value but not on every key.
  final int recentTick;
  final SaveStatus status;

  /// Plain message from the failed save or the form check. Cleared by the
  /// next edit.
  final String? saveError;

  /// Set when [status] is [SaveStatus.done].
  final SavedEntry? saved;

  /// The entry being edited (edit mode), or `null` when adding. Never
  /// changes while the sheet is open.
  final TransactionEntry? edit;

  bool get isEditing => edit != null;

  Picks picksOf(TransactionType t) => picks[t] ?? Picks.none;

  bool get isSaving => status == SaveStatus.saving;

  QuickAddState copyWith({
    TransactionType? type,
    String? date,
    AmountInput? amount,
    String? note,
    Map<TransactionType, Picks>? picks,
    AmountRefusal? amountHint,
    bool clearHint = false,
    int? refusalCount,
    int? recentTick,
    SaveStatus? status,
    String? saveError,
    bool clearError = false,
    SavedEntry? saved,
  }) => QuickAddState(
    type: type ?? this.type,
    today: today,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    note: note ?? this.note,
    picks: picks ?? this.picks,
    amountHint: clearHint ? null : (amountHint ?? this.amountHint),
    refusalCount: refusalCount ?? this.refusalCount,
    recentTick: recentTick ?? this.recentTick,
    status: status ?? this.status,
    saveError: clearError ? null : (saveError ?? this.saveError),
    saved: saved ?? this.saved,
    edit: edit,
  );
}
