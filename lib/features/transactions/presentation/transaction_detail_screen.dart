import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router.dart';
import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/utils/today_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_sizes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/skeleton_block.dart';
import '../../../shared/widgets/staggered_entrance.dart';
import '../../../shared/wow/parallax.dart';
import '../../../shared/wow/scene_activity.dart';
import '../../../shared/wow/spring_press.dart';
import '../../../shared/wow/wow_header.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_controller.dart';
import '../../mascot/presentation/mascot_moment.dart';
import '../application/transactions_list_providers.dart';
import '../domain/transaction_entry.dart';
import '../domain/transaction_list_item.dart';
import 'transactions_actions.dart';
import 'widgets/detail_hero.dart';

/// One entry, in full. A living header (`WowHeader`, back button, monkey)
/// sits over the hero card (it tilts in 3D) and the facts. Edit opens Quick
/// Add in edit mode. Delete asks first, then goes back to the list, which shows "Entry
/// deleted" with Undo.
class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({required this.transactionId, super.key});

  final String transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  /// Last entry shown, kept while a delete is in progress (so the screen
  /// does not flash "not found" before it pops).
  TransactionListItem? _lastShown;
  bool _deleting = false;
  bool _missingLogged = false;
  final MascotController _monkey = MascotController();
  final ScrollOffset _scroll = ScrollOffset();
  final SceneActivity _activity = SceneActivity();

  @override
  void initState() {
    super.initState();
    // Logged once, when the entry is found to be missing (not in build).
    ref.listenManual<AsyncValue<TransactionListItem?>>(
      transactionDetailProvider(widget.transactionId),
      (
        AsyncValue<TransactionListItem?>? previous,
        AsyncValue<TransactionListItem?> next,
      ) {
        if (next.hasValue && next.value == null && !_missingLogged) {
          _missingLogged = true;
          ref.read(loggerProvider).info(transactionsLogTag, 'entry not found');
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _monkey.dispose();
    _scroll.dispose();
    _activity.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.transactions);
    }
  }

  Future<void> _delete(TransactionEntry entry) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('You can undo it from the list for a few seconds.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _monkey.react(MascotReaction.del);
    setState(() => _deleting = true);
    final bool deleted = await deleteEntryWithUndo(
      actions: ref.read(transactionActionsProvider),
      messenger: messenger,
      log: ref.read(loggerProvider),
      entry: entry,
    );
    if (!mounted) return;
    if (deleted) {
      _back();
    } else {
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TransactionListItem?> async = ref.watch(
      transactionDetailProvider(widget.transactionId),
    );
    final String today = ref.watch(todayProvider);
    final TransactionListItem? item = async.value;
    if (item != null) _lastShown = item;
    final TransactionListItem? shown = _deleting ? _lastShown : item;
    final double bottom = MediaQuery.paddingOf(context).bottom;

    final Widget content;
    if (shown != null) {
      content = SliverPadding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.space6,
          AppSpacing.screenPadding,
          AppSpacing.space8 + bottom,
        ),
        sliver: SliverList(
          delegate: SliverChildListDelegate(<Widget>[
            StaggeredEntrance(index: 0, child: DetailHero(item: shown)),
            const SizedBox(height: AppSpacing.space4),
            StaggeredEntrance(
              index: 1,
              child: _Facts(
                rows: <(String, String)>[
                  if (shown.isTransfer) ...<(String, String)>[
                    ('From', shown.accountName),
                    ('To', shown.toAccountName ?? ''),
                  ] else ...<(String, String)>[
                    ('Account', shown.accountName),
                    ('Category', shown.categoryName ?? ''),
                  ],
                  if ((shown.entry.note ?? '').trim().isNotEmpty)
                    ('Note', shown.entry.note!.trim()),
                  ('Created', _stamp(shown.entry.createdAt, today)),
                  ('Updated', _stamp(shown.entry.updatedAt, today)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            StaggeredEntrance(
              index: 2,
              child: PrimaryButton(
                label: 'Edit entry',
                onPressed: () => openEditEntry(
                  context,
                  ref.read(loggerProvider),
                  shown.entry,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            StaggeredEntrance(
              index: 3,
              child: _DeleteButton(onTap: () => _delete(shown.entry)),
            ),
          ]),
        ),
      );
    } else {
      final Widget state;
      if (async.hasError) {
        state = ErrorState(
          title: 'Could not open this entry',
          message: 'Your data is safe. Try again.',
          onRetry: () =>
              ref.invalidate(transactionDetailProvider(widget.transactionId)),
        );
      } else if (async.isLoading) {
        state = const _DetailSkeleton();
      } else {
        state = EmptyState(
          illustration: 'empty_transactions',
          title: 'This entry is gone',
          message:
              'It was deleted or never existed. Your other entries are safe.',
          action: PrimaryButton(
            label: 'Back to Transactions',
            fullWidth: false,
            onPressed: _back,
          ),
        );
      }
      // A fixed box (the state views scroll inside it at large text sizes).
      content = SliverToBoxAdapter(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: state,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Listener(
        onPointerDown: (PointerDownEvent e) {
          _activity.poke();
          _monkey.follow(e.position);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: _scroll.onScroll,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: WowHeader(
                  eyebrow: 'Your Activity',
                  title: 'Entry',
                  scroll: _scroll,
                  activity: _activity,
                  leading: IconButton(
                    tooltip: 'Back to Transactions',
                    onPressed: _back,
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      size: AppSizes.iconNav,
                      color: AppColors.ink,
                    ),
                  ),
                  trailing: MascotMoment(
                    controller: _monkey,
                    reaction: MascotReaction.hello,
                    size: 64,
                    halo: false,
                  ),
                ),
              ),
              content,
            ],
          ),
        ),
      ),
    );
  }

  /// `12 Nov 2026, 14:05` in local time.
  static String _stamp(int epochMs, String today) {
    final DateTime local = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final String day = shortDateLabel(dateKey(local), todayKey: today);
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$day, $hh:$mm';
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.tile,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, color: AppColors.divider),
            Semantics(
              container: true,
              label: '${rows[i].$1}: ${rows[i].$2}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 92,
                      child: Text(rows[i].$1, style: AppTextStyles.caption),
                    ),
                    Expanded(
                      child: Text(rows[i].$2, style: AppTextStyles.bodyStrong),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpringPress(
      semanticLabel: 'Delete entry',
      onTap: onTap,
      scale: 0.97,
      child: ExcludeSemantics(
        child: Container(
          height: AppSizes.buttonHeight,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.pill,
            border: Border.fromBorderSide(BorderSide(color: AppColors.danger)),
          ),
          child: Text(
            'Delete entry',
            style: AppTextStyles.bodyStrong.copyWith(color: AppColors.danger),
          ),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: <Widget>[
            SkeletonBlock(height: 220),
            SizedBox(height: AppSpacing.space4),
            SkeletonBlock(height: 120),
          ],
        ),
      ),
    );
  }
}
