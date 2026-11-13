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
import '../application/transactions_list_providers.dart';
import '../domain/transaction_entry.dart';
import '../domain/transaction_list_item.dart';
import 'transactions_actions.dart';
import 'widgets/detail_hero.dart';

/// One entry, in full. Edit opens Quick Add in edit mode. Delete asks first,
/// then goes back to the list, which shows "Entry deleted" with Undo.
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
    final TransactionListItem? item = async.value;
    if (item != null) _lastShown = item;
    final TransactionListItem? shown = _deleting ? _lastShown : item;

    final Widget body;
    if (shown != null) {
      body = _DetailBody(
        item: shown,
        today: today,
        onEdit: () =>
            openEditEntry(context, ref.read(loggerProvider), shown.entry),
        onDelete: () => _delete(shown.entry),
      );
    } else if (async.hasError) {
      body = ErrorState(
        title: 'Could not open this entry',
        message: 'Your data is safe. Try again.',
        onRetry: () =>
            ref.invalidate(transactionDetailProvider(widget.transactionId)),
      );
    } else if (async.isLoading) {
      body = const _DetailSkeleton();
    } else {
      ref.read(loggerProvider).info(transactionsLogTag, 'entry not found');
      body = EmptyState(
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

    return Scaffold(
      backgroundColor: AppColors.panel,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: _back,
                    tooltip: 'Back to Transactions',
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      size: AppSizes.iconInline,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.item,
    required this.today,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionListItem item;
  final String today;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final TransactionEntry e = item.entry;
    final String note = (e.note ?? '').trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: <Widget>[
        DetailHero(item: item),
        const SizedBox(height: AppSpacing.space4),
        _Facts(
          rows: <(String, String)>[
            if (item.isTransfer) ...<(String, String)>[
              ('From', item.accountName),
              ('To', item.toAccountName ?? ''),
            ] else ...<(String, String)>[
              ('Account', item.accountName),
              ('Category', item.categoryName ?? ''),
            ],
            if (note.isNotEmpty) ('Note', note),
            ('Created', _stamp(e.createdAt, today)),
            ('Updated', _stamp(e.updatedAt, today)),
          ],
        ),
        const SizedBox(height: AppSpacing.space6),
        PrimaryButton(label: 'Edit entry', onPressed: onEdit),
        const SizedBox(height: AppSpacing.space3),
        _DeleteButton(onTap: onDelete),
      ],
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
