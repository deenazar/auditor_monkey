import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/rolling_amount.dart';
import '../../../shared/widgets/step_dots.dart';
import '../application/accounts_providers.dart';
import '../domain/account.dart';
import 'widgets/account_card.dart';
import 'widgets/account_carousel.dart';
import 'widgets/account_form_sheet.dart';
import 'widgets/account_form_values.dart';
import 'widgets/account_list_row.dart';
import 'widgets/accounts_loading_view.dart';
import 'widgets/show_account_form_sheet.dart';

/// The Accounts tab (DESIGN "Accounts"): page header, net worth, a card
/// carousel, the "Add account" button and the "All accounts" list. Archived
/// accounts come last under an "ARCHIVED" label. Tapping a card or row opens
/// its statement.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final AccountCarouselController _carousel = AccountCarouselController();
  int _page = 0;

  void _openStatement(Account account) {
    context.push(AppRoutes.accountStatement(account.id));
  }

  Future<void> _addAccount(List<String> names) async {
    await showAccountFormSheet(
      context,
      AccountFormSheet(
        title: 'Add account',
        submitLabel: 'Add account',
        otherNames: names,
        showOpeningBalance: true,
        onSave: _save,
      ),
    );
  }

  Future<AccountFormError?> _save(AccountFormValues values) async {
    final AccountDetails details = toAccountDetails(values);
    try {
      await ref.read(accountsRepositoryProvider).addAccount(details);
      return null;
    } on DataFailure catch (failure) {
      return accountFormErrorFrom(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<AccountBalance>> balances = ref.watch(
      accountBalancesProvider,
    );
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: balances.when(
          loading: () => const AccountsLoadingView(),
          error: (Object error, StackTrace stack) => _ErrorBody(error: error),
          data: (List<AccountBalance> list) => list.isEmpty
              ? const _EmptyBody()
              : _DataBody(
                  list: list,
                  page: _page,
                  carousel: _carousel,
                  onPageChanged: (int page) => setState(() => _page = page),
                  onOpen: _openStatement,
                  onAdd: _addAccount,
                ),
        ),
      ),
    );
  }
}

class _DataBody extends StatelessWidget {
  const _DataBody({
    required this.list,
    required this.page,
    required this.carousel,
    required this.onPageChanged,
    required this.onOpen,
    required this.onAdd,
  });

  final List<AccountBalance> list;
  final int page;
  final AccountCarouselController carousel;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<Account> onOpen;
  final ValueChanged<List<String>> onAdd;

  @override
  Widget build(BuildContext context) {
    final List<AccountBalance> live = list
        .where((AccountBalance b) => !b.account.archived)
        .toList(growable: false);
    final List<AccountBalance> archived = list
        .where((AccountBalance b) => b.account.archived)
        .toList(growable: false);
    final List<String> names = list
        .map((AccountBalance b) => b.account.name)
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: PageHeader(eyebrow: 'Your Wallet', title: 'Accounts'),
          ),
          const SizedBox(height: AppSpacing.space6),
          _NetWorth(fallback: _sum(list)),
          const SizedBox(height: AppSpacing.space6),
          // The carousel is full-bleed: no side padding around it.
          if (live.isNotEmpty)
            AccountCarousel(
              controller: carousel,
              itemCount: live.length,
              onPageChanged: onPageChanged,
              itemBuilder: (BuildContext context, int index) {
                final Account a = live[index].account;
                return AccountCard(
                  name: a.name,
                  type: a.type,
                  colourToken: a.colour,
                  balancePaise: live[index].balance,
                  openingPaise: a.openingBalance,
                  onTap: () => onOpen(a),
                );
              },
            ),
          if (live.length > 1) ...<Widget>[
            const SizedBox(height: AppSpacing.space3),
            Center(
              child: StepDots(
                count: live.length,
                current: page.clamp(0, live.length - 1),
                semanticsLabel:
                    'Card ${page.clamp(0, live.length - 1) + 1} '
                    'of ${live.length}',
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sectionGap),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: PrimaryButton(
                    label: 'Add account',
                    fullWidth: false,
                    onPressed: () => onAdd(names),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                const Text('All accounts', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.space3),
                for (final AccountBalance b in live)
                  _row(b, () => onOpen(b.account)),
                if (archived.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.space5),
                  Text(
                    'ARCHIVED',
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  for (final AccountBalance b in archived)
                    _row(b, () => onOpen(b.account)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AccountBalance b, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.listRowGap),
    child: AccountListRow(
      name: b.account.name,
      colourToken: b.account.colour,
      balancePaise: b.balance,
      onTap: onTap,
    ),
  );

  static int _sum(List<AccountBalance> list) {
    int total = 0;
    for (final AccountBalance b in list) {
      total += b.balance;
    }
    return total;
  }
}

/// "NET WORTH" with the total, which rolls when it changes. Includes
/// archived accounts (as the data layer does).
class _NetWorth extends ConsumerWidget {
  const _NetWorth({required this.fallback});

  final int fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int paise = ref.watch(netWorthProvider).value ?? fallback;
    return Column(
      children: <Widget>[
        Text(
          'NET WORTH',
          textAlign: TextAlign.center,
          style: AppTextStyles.overline.copyWith(color: AppColors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.space1),
        RollingAmount.text(
          paise: paise,
          style: AppTextStyles.headline,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: LucideIcons.wallet,
      title: 'No accounts yet',
      message: 'Set up your accounts to see balances here.',
      action: PrimaryButton(
        label: 'Set up accounts',
        fullWidth: false,
        onPressed: () => context.go(AppRoutes.setup),
      ),
    );
  }
}

class _ErrorBody extends ConsumerWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String message = error is OverflowFailure
        ? 'A balance is too large to show'
        : 'Check the app and try again.';
    return ErrorState(
      title: "We couldn't load your accounts",
      message: message,
      onRetry: () => ref.invalidate(accountBalancesProvider),
    );
  }
}
