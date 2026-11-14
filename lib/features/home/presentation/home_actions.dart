import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/date_keys.dart';
import '../../transactions/application/transactions_list_providers.dart';
import '../../transactions/domain/transaction_entry.dart';
import '../../transactions/domain/transaction_filter.dart';

/// Log tag of the Home screen.
const String homeLogTag = 'home';

/// What a Home tap does in the rest of the app. Every action is logged
/// without amounts, names or ids.
///
/// Drill-downs set the shared Transactions filter first (the search text is
/// cleared too, so the list shows exactly what the tapped number counts),
/// then open the Transactions tab.
class HomeActions {
  const HomeActions(this.ref, this.context);

  final WidgetRef ref;
  final BuildContext context;

  void _log(String message) =>
      ref.read(loggerProvider).info(homeLogTag, message);

  void _openFiltered(TransactionFilter filter) {
    final TransactionFilterNotifier notifier = ref.read(
      transactionFilterProvider.notifier,
    );
    notifier
      ..clear()
      ..setFacets(filter);
    context.go(AppRoutes.transactions);
  }

  /// This month's spending: month + `expense`. [categoryId] narrows it to
  /// one category (a Top spending row).
  void openMonthSpending(String month, {String? categoryId}) {
    _log(categoryId == null ? 'drill-down: spent' : 'drill-down: top category');
    _openFiltered(
      TransactionFilter(
        from: '$month-01',
        to: monthLastDay(month),
        types: const <TransactionType>{TransactionType.expense},
        categoryIds: categoryId == null ? const <String>{} : {categoryId},
      ),
    );
  }

  /// "See all": no filter at all.
  void seeAll() {
    _log('see all');
    ref.read(transactionFilterProvider.notifier).clear();
    context.go(AppRoutes.transactions);
  }

  /// A doughnut slice, second tap: the account statement.
  void openAccount(String accountId) {
    _log('open account from doughnut');
    context.go(AppRoutes.accountStatement(accountId));
  }

  /// A recent row: the entry detail.
  void openEntry(String entryId) {
    _log('open entry');
    context.go(AppRoutes.transactionDetail(entryId));
  }
}
