import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router.dart';
import '../../../core/utils/today_provider.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_sizes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../setup/domain/opening_balance_input.dart';
import '../../transactions/domain/statement_line.dart';
import '../application/account_statement_provider.dart';
import '../application/accounts_providers.dart';
import '../domain/account.dart';
import 'widgets/account_form_sheet.dart';
import 'widgets/account_form_values.dart';
import 'widgets/show_account_form_sheet.dart';
import 'widgets/statement_list_view.dart';
import 'widgets/statement_loading_view.dart';

/// Statement of one account (S1 to S5): balance card, the six-month chart,
/// the lines with running balance and the opening balance last. Read-only,
/// except for "Edit account" (opens the shared form sheet).
///
/// Lines load a page at a time; the next page loads when the list is 80%
/// scrolled. A malformed or unknown id shows "not available".
class AccountStatementScreen extends ConsumerStatefulWidget {
  const AccountStatementScreen({required this.accountId, super.key});

  /// From the URL. May be malformed; the provider checks it.
  final String accountId;

  @override
  ConsumerState<AccountStatementScreen> createState() =>
      _AccountStatementScreenState();
}

/// Fraction of the scroll at which the next page starts loading.
const double _loadMoreAt = 0.8;

class _AccountStatementScreenState
    extends ConsumerState<AccountStatementScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final ScrollPosition position = _scroll.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent * _loadMoreAt) {
      unawaited(
        ref
            .read(accountStatementProvider(widget.accountId).notifier)
            .loadMore(),
      );
    }
  }

  Future<void> _openEdit(Account account) async {
    final List<AccountBalance> all =
        ref.read(accountBalancesProvider).value ?? const <AccountBalance>[];
    final List<String> others = <String>[
      for (final AccountBalance b in all)
        if (b.account.id != account.id) b.account.name,
    ];
    await showAccountFormSheet(
      context,
      AccountFormSheet(
        title: 'Edit account',
        submitLabel: 'Save changes',
        otherNames: others,
        showOpeningBalance: true,
        initial: AccountFormValues(
          name: account.name,
          type: account.type,
          colour: account.colour,
          balanceText: paiseToInputText(account.openingBalance),
          owes: account.openingBalance < 0,
        ),
        onSave: (AccountFormValues values) => _saveEdit(account.id, values),
      ),
    );
  }

  Future<AccountFormError?> _saveEdit(
    String id,
    AccountFormValues values,
  ) async {
    try {
      await ref
          .read(accountsRepositoryProvider)
          .editAccount(id, toAccountDetails(values));
      return null;
    } on DataFailure catch (failure) {
      return accountFormErrorFrom(failure);
    }
  }

  void _back() {
    unawaited(Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AccountStatementState> statement = ref.watch(
      accountStatementProvider(widget.accountId),
    );
    final String todayKey = ref.watch(todayProvider);
    final AsyncValue<List<MonthlyTotal>> months = ref.watch(
      accountMonthlyTotalsProvider(widget.accountId),
    );
    final AccountStatementState? data = statement.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _TopBar(
              onBack: _back,
              onEdit: data == null ? null : () => _openEdit(data.account),
            ),
            Expanded(
              child: statement.when(
                loading: () => const StatementLoadingView(),
                error: (Object error, StackTrace stack) =>
                    error is NotFoundFailure
                    ? const _NotAvailable()
                    : _ErrorView(
                        error: error,
                        onRetry: () => ref.invalidate(
                          accountStatementProvider(widget.accountId),
                        ),
                      ),
                data: (AccountStatementState state) => StatementListView(
                  state: state,
                  todayKey: todayKey,
                  months: months,
                  scrollController: _scroll,
                  onRetryMore: () => unawaited(
                    ref
                        .read(
                          accountStatementProvider(widget.accountId).notifier,
                        )
                        .loadMore(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back on the left, "Edit account" on the right (44pt targets).
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, this.onEdit});

  final VoidCallback onBack;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(
              LucideIcons.chevronLeft,
              size: AppSizes.iconNav,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit account',
              onPressed: onEdit,
              icon: const Icon(
                LucideIcons.pencil,
                size: AppSizes.iconInline,
                color: AppColors.ink,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotAvailable extends StatelessWidget {
  const _NotAvailable();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: LucideIcons.wallet,
      title: "This account isn't available",
      message: 'It may have been removed, or the link is wrong.',
      action: PrimaryButton(
        label: 'Back to Accounts',
        fullWidth: false,
        onPressed: () => context.go(AppRoutes.accounts),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: "We couldn't load this statement",
      message: error is OverflowFailure
          ? 'A balance is too large to show'
          : 'Check the app and try again.',
      onRetry: onRetry,
    );
  }
}
