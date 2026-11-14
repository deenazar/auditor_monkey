import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transactions/domain/transaction_entry.dart';
import '../domain/quick_add_defaults.dart';
import 'quick_add_data_provider.dart';
import 'quick_add_notifier.dart';
import 'quick_add_resolve.dart';
import 'quick_add_state.dart';

/// State and loaded data merged, ready to draw.
class QuickAddView {
  const QuickAddView({
    required this.state,
    required this.dataValue,
    required this.current,
  });

  final QuickAddState state;
  final AsyncValue<QuickAddData> dataValue;

  /// What the screen shows for the current tab: pick ?? default.
  final DefaultPicks current;

  QuickAddData? get data => dataValue.value;
  bool get isLoading => dataValue.isLoading && data == null;
  bool get hasLoadError => dataValue.hasError && data == null;

  TransactionType get type => state.type;

  /// Transfer needs two accounts. True until the data says otherwise.
  bool get transferAvailable => data?.transferAvailable ?? true;

  /// Needs data, a real amount, and no save in progress. No red error
  /// for an empty amount: the button just stays off.
  bool get canSave =>
      data != null &&
      state.amount.isSavable &&
      state.status != SaveStatus.saving &&
      state.status != SaveStatus.done &&
      current.accountId != null &&
      (state.type == TransactionType.transfer
          ? current.toAccountId != null
          : current.categoryId != null);

  bool get isEditing => state.isEditing;

  /// "Save expense", "Save income" or "Save transfer"; "Save changes" when
  /// editing.
  String get saveLabel =>
      isEditing ? 'Save changes' : 'Save ${state.type.name}';

  /// Header text over the tabs: "Edit entry" when editing, else `null`.
  String? get headerTitle => isEditing ? 'Edit entry' : null;

  /// True when the current expense / income tab has no category to pick.
  bool get noCategories =>
      data != null &&
      state.type != TransactionType.transfer &&
      data!.categoryIdsOf(state.type).isEmpty;
}

final Provider<QuickAddView> quickAddViewProvider =
    Provider.autoDispose<QuickAddView>((Ref ref) {
      final QuickAddState state = ref.watch(quickAddProvider);
      final AsyncValue<QuickAddData> data = ref.watch(quickAddDataProvider);
      return QuickAddView(
        state: state,
        dataValue: data,
        current: resolvePicks(
          state.type,
          state.picksOf(state.type),
          data.value,
        ),
      );
    });
