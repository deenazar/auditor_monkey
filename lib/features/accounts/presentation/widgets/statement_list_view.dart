import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_shadows.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_illustration.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../../shared/wow/long_press_preview.dart';
import '../../../../shared/wow/swipe_action_row.dart';
import '../../../../shared/wow/tilt_3d.dart';
import '../../../mascot/domain/mascot_mood.dart';
import '../../../mascot/presentation/mascot_moment.dart';
import '../../../transactions/domain/statement_line.dart';
import '../../application/account_statement_provider.dart';
import '../../domain/account.dart';
import 'account_hero.dart';
import 'account_type_label.dart';
import 'opening_balance_row.dart';
import 'statement_balance_card.dart';
import 'statement_chart_tile.dart';
import 'statement_footer.dart';
import 'statement_row.dart';

/// The scrolling part of a statement: header, balance card, the chart tile,
/// then the lines (newest first) and the opening balance last.
///
/// Lines are built lazily in a sliver list. [scrollController] is watched by
/// the screen to load the next page at 80% of the scroll.
class StatementListView extends StatelessWidget {
  const StatementListView({
    required this.state,
    required this.todayKey,
    required this.months,
    required this.scrollController,
    required this.onRetryMore,
    this.onDeleteLine,
    super.key,
  });

  final AccountStatementState state;

  /// `YYYY-MM-DD` of today (for the date labels).
  final String todayKey;

  /// Monthly totals for the chart: data, loading (no value) or error.
  final AsyncValue<List<MonthlyTotal>> months;

  final ScrollController scrollController;
  final VoidCallback onRetryMore;

  /// Swipe-to-delete on a line (Motion & 3D). Null: no swipe.
  final ValueChanged<StatementLine>? onDeleteLine;

  /// A statement line with swipe-to-delete and a long-press preview.
  Widget _entryRow(StatementLine line) {
    final Widget row = LongPressPreview(
      preview: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: StatementRow(line: line, todayKey: todayKey),
      ),
      child: StatementRow(line: line, todayKey: todayKey),
    );
    final ValueChanged<StatementLine>? delete = onDeleteLine;
    if (delete == null) return row;
    return SwipeActionRow(
      id: line.entry.id,
      end: SwipeAction(
        icon: LucideIcons.trash2,
        label: 'Delete',
        colour: AppColors.swipeDelete,
        removesRow: true,
        onTrigger: () => delete(line),
      ),
      child: row,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Account account = state.account;
    final AccountStatementState s = state;
    final int rowCount = s.lines.length + (s.showOpeningRow ? 1 : 0);
    return CustomScrollView(
      controller: scrollController,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.space6,
              AppSpacing.screenPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                StaggeredEntrance(
                  index: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      PageHeader(
                        eyebrow: accountTypeLabel(account.type),
                        title: account.name,
                      ),
                      const SizedBox(height: AppSpacing.space6),
                      // Motion & 3D: the card arrives by Hero, tilts and
                      // lifts on layered shadows.
                      Tilt3D(
                        child: Hero(
                          tag: accountHeroTag(account.id),
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              borderRadius: AppRadius.card,
                              boxShadow: AppShadows.shadowLayered,
                            ),
                            child: StatementBalanceCard(
                              colourToken: account.colour,
                              balancePaise: s.balance,
                              rollKey: 'statement:${account.id}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
                StaggeredEntrance(
                  index: 1,
                  child: Tilt3D(
                    child: StatementChartTile(
                      months: months.value,
                      failed: months.hasError && !months.hasValue,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                StaggeredEntrance(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text('Statement', style: AppTextStyles.title),
                      const SizedBox(height: AppSpacing.space3),
                      if (s.lines.isEmpty && !s.hasMore)
                        const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.space5),
                          child: Column(
                            children: <Widget>[
                              AppIllustration('empty_statement'),
                              SizedBox(height: AppSpacing.space2),
                              MascotMoment(
                                reaction: MascotReaction.hello,
                                say: 'Add one with +',
                                size: 72,
                                halo: false,
                              ),
                              SizedBox(height: AppSpacing.space3),
                              Text(
                                'Entries you add with + show here.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          sliver: SliverList.builder(
            itemCount: rowCount,
            itemBuilder: (BuildContext context, int index) {
              final Widget row = index < s.lines.length
                  ? _entryRow(s.lines[index])
                  : OpeningBalanceRow(openingPaise: account.openingBalance);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.listRowGap),
                child: row,
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: StatementFooter(
              loading: s.loadingMore,
              failed: s.loadMoreFailed,
              onRetry: onRetryMore,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space8)),
      ],
    );
  }
}
