import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router.dart';
import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_shadows.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/rolling_amount.dart';
import '../../../shared/widgets/staggered_entrance.dart';
import '../../../shared/widgets/step_dots.dart';
import '../../../shared/wow/long_press_preview.dart';
import '../../../shared/wow/parallax.dart';
import '../../../shared/wow/scene_activity.dart';
import '../../../shared/wow/swipe_action_row.dart';
import '../../../shared/wow/tilt_3d.dart';
import '../../../shared/wow/wow_header.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_controller.dart';
import '../../mascot/presentation/mascot_moment.dart';
import '../application/accounts_providers.dart';
import '../domain/account.dart';
import 'widgets/account_card.dart';
import 'widgets/account_carousel.dart';
import 'widgets/account_form_sheet.dart';
import 'widgets/account_form_values.dart';
import 'widgets/account_hero.dart';
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
  final MascotController _monkey = MascotController();
  final ScrollOffset _scroll = ScrollOffset();
  final SceneActivity _activity = SceneActivity();
  int _page = 0;

  @override
  void dispose() {
    _monkey.dispose();
    _scroll.dispose();
    _activity.dispose();
    super.dispose();
  }

  /// Pull-to-refresh: re-reads balances (they are live anyway; this also
  /// reassures after an import or sync).
  Future<void> _refresh() async {
    ref.read(loggerProvider).info('accounts', 'pull to refresh');
    _monkey.react(MascotReaction.spin);
    ref.invalidate(accountBalancesProvider);
    ref.invalidate(netWorthProvider);
    try {
      await ref.read(accountBalancesProvider.future);
    } catch (_) {
      // The error body shows itself.
    }
  }

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
      _monkey.react(MascotReaction.check, text: 'New account added!');
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
        child: NotificationListener<ScrollNotification>(
          onNotification: _scroll.onScroll,
          child: Listener(
            onPointerDown: (PointerDownEvent e) {
              _activity.poke();
              _monkey.follow(e.position);
            },
            child: balances.when(
              loading: () => const AccountsLoadingView(),
              error: (Object error, StackTrace stack) =>
                  _ErrorBody(error: error),
              data: (List<AccountBalance> list) => list.isEmpty
                  ? const _EmptyBody()
                  : _DataBody(
                      list: list,
                      page: _page,
                      carousel: _carousel,
                      onPageChanged: (int page) {
                        _monkey.look(Offset(page > _page ? 1 : -1, 0.4));
                        setState(() => _page = page);
                      },
                      onOpen: _openStatement,
                      onAdd: _addAccount,
                      onRefresh: _refresh,
                      monkey: _monkey,
                      scroll: _scroll,
                      activity: _activity,
                    ),
            ),
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
    required this.onRefresh,
    required this.monkey,
    required this.scroll,
    required this.activity,
  });

  final Future<void> Function() onRefresh;
  final MascotController monkey;
  final ScrollOffset scroll;
  final SceneActivity activity;
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

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryDeep,
      backgroundColor: AppColors.background,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: AppSpacing.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Living header (Motion & 3D): blobs, parallax title, rolling
            // net worth and an Auditor Monkey that reacts to this screen.
            WowHeader(
              eyebrow: 'Your Wallet',
              title: 'Accounts',
              scroll: scroll,
              activity: activity,
              bottom: _NetWorth(fallback: _sum(list)),
              trailing: MascotMoment(
                controller: monkey,
                reaction: MascotReaction.hello,
                size: 64,
                halo: false,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            // The carousel is full-bleed: no side padding around it.
            if (live.isNotEmpty)
              StaggeredEntrance(
                index: 1,
                child: AccountCarousel(
                  controller: carousel,
                  itemCount: live.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (BuildContext context, int index) {
                    final Account a = live[index].account;
                    // Motion & 3D: tilts under the finger, lifts on layered
                    // shadows, and flies into the statement (Hero).
                    return Tilt3D(
                      borderRadius: AppRadius.card,
                      child: Hero(
                        tag: accountHeroTag(a.id),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            borderRadius: AppRadius.card,
                            boxShadow: AppShadows.shadowLayered,
                          ),
                          child: AccountCard(
                            name: a.name,
                            type: a.type,
                            colourToken: a.colour,
                            balancePaise: live[index].balance,
                            openingPaise: a.openingBalance,
                            rollKey: 'account:${a.id}',
                            onTap: () => onOpen(a),
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
                  for (int i = 0; i < live.length; i++)
                    StaggeredEntrance(
                      index: 2 + i,
                      child: _row(live[i], () => onOpen(live[i].account)),
                    ),
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
      ),
    );
  }

  /// A row (Motion & 3D): long-press peeks at the account's card; swipe
  /// left opens the statement, swipe right peeks at the card too.
  Widget _row(AccountBalance b, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.listRowGap),
    child: Builder(
      builder: (BuildContext context) => SwipeActionRow(
        id: 'account-${b.account.id}',
        start: SwipeAction(
          icon: LucideIcons.eye,
          label: 'Preview card',
          colour: AppColors.primaryDeep,
          onTrigger: () =>
              LongPressPreview.show(context, (_) => _previewCard(b)),
        ),
        end: SwipeAction(
          icon: LucideIcons.chevronRight,
          label: 'Open statement',
          colour: AppColors.primary,
          onTrigger: onTap,
        ),
        child: LongPressPreview(
          semanticHint: 'Long press to preview the card',
          preview: (_) => _previewCard(b),
          child: AccountListRow(
            name: b.account.name,
            colourToken: b.account.colour,
            balancePaise: b.balance,
            onTap: onTap,
          ),
        ),
      ),
    ),
  );

  static Widget _previewCard(AccountBalance b) => AccountCard(
    name: b.account.name,
    type: b.account.type,
    colourToken: b.account.colour,
    balancePaise: b.balance,
    openingPaise: b.account.openingBalance,
    archived: b.account.archived,
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
          style: AppTextStyles.overline.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.space1),
        RollingAmount.text(
          paise: paise,
          rollKey: 'net-worth',
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
      illustration: 'empty_accounts',
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
