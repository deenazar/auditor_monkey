import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router.dart';
import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/utils/today_provider.dart';
import '../../../shared/scene/sky_phase.dart';
import '../../../shared/scene/sky_scene.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_shadows.dart';
import '../../../shared/theme/app_sizes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/glass_icon_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/skeleton_block.dart';
import '../../../shared/widgets/staggered_entrance.dart';
import '../application/transactions_list_providers.dart';
import '../domain/transaction_entry.dart';
import '../domain/transaction_list_item.dart';
import 'transactions_actions.dart';
import 'widgets/detail_hero.dart';

/// Height of the sky above the panel (below the status bar).
const double _stageHeight = 180;

/// How far the hero card rises into the sky above the panel's top edge.
const double _heroOverlap = 90;

/// How far the panel's top edge sits above the stage's bottom.
const double _panelOverlap = 40;

/// One entry, in full. The hero card sits over a compact sky (the same time
/// of day as the list) and overlaps the panel. Edit opens Quick Add in edit
/// mode. Delete asks first, then goes back to the list, which shows "Entry
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
    final SkyPhase phase = SkyPhase.at(
      DateTime.fromMillisecondsSinceEpoch(ref.watch(clockProvider).nowMs()),
    );
    final TransactionListItem? item = async.value;
    if (item != null) _lastShown = item;
    final TransactionListItem? shown = _deleting ? _lastShown : item;
    final double padTop = MediaQuery.paddingOf(context).top;
    final double bottom = MediaQuery.paddingOf(context).bottom;
    final double stageH = padTop + _stageHeight;

    final Widget content;
    if (shown != null) {
      content = ListView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 32 + bottom),
        children: <Widget>[
          DetailHero(item: shown),
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
              onPressed: () =>
                  openEditEntry(context, ref.read(loggerProvider), shown.entry),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          StaggeredEntrance(
            index: 3,
            child: _DeleteButton(onTap: () => _delete(shown.entry)),
          ),
        ],
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
      content = Padding(
        padding: const EdgeInsets.only(top: _heroOverlap),
        child: state,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.panel,
      body: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: stageH,
            child: _DetailStage(phase: phase, topInset: padTop, onBack: _back),
          ),
          // The panel the hero card overlaps.
          Positioned(
            left: 0,
            right: 0,
            top: stageH - _panelOverlap,
            bottom: 0,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: AppRadius.sheet,
                boxShadow: AppShadows.shadowPanel,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: stageH - _heroOverlap,
            bottom: 0,
            child: content,
          ),
        ],
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

/// The compact sky: a glass back button and the screen title.
class _DetailStage extends StatelessWidget {
  const _DetailStage({
    required this.phase,
    required this.topInset,
    required this.onBack,
  });

  final SkyPhase phase;
  final double topInset;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final double top = topInset + 8;
    return BackdropGroup(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          Positioned.fill(
            child: SkyScene(phase: phase, cloudTop: top + 48),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: top,
            child: Row(
              children: <Widget>[
                GlassIconButton(
                  icon: LucideIcons.arrowLeft,
                  semanticLabel: 'Back to Transactions',
                  onTap: onBack,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Semantics(
                    header: true,
                    label: 'Entry',
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'Entry',
                        maxLines: 1,
                        style: AppTextStyles.displayTitle.copyWith(
                          color: AppColors.glassInk,
                          shadows: AppShadows.textOnSky,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.card,
        border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
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
    return Semantics(
      button: true,
      label: 'Delete entry',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: AppSizes.buttonHeight,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.pill,
            border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
          ),
          child: Text(
            'Delete entry',
            style: AppTextStyles.button.copyWith(color: AppColors.danger),
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
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            SkeletonBlock(height: 220, borderRadius: AppRadius.hero),
            SizedBox(height: 16),
            SkeletonBlock(height: 120),
          ],
        ),
      ),
    );
  }
}
