import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_shadows.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../domain/home_format.dart';
import '../../domain/home_summary.dart';
import 'date_strip.dart';
import 'home_entry_row.dart';

/// The sliding panel (mini_checklist `.panel`): handle, date strip, a list
/// head with this month's progress, then the entries. Its scroll view is
/// the [DraggableScrollableSheet]'s, so dragging slides the panel first.
class HomePanel extends StatelessWidget {
  const HomePanel({
    required this.scroll,
    required this.summary,
    required this.budgetTotal,
    required this.selected,
    required this.rows,
    required this.onPick,
    super.key,
  });

  final ScrollController scroll;
  final HomeSummary summary;
  final int budgetTotal;
  final String? selected;
  final List<HomeEntryView> rows;
  final ValueChanged<String> onPick;

  /// How many entries the "Recent" list shows.
  static const int recentCount = 20;

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.paddingOf(context).bottom + 24;
    final int plan = summary.plan(budgetTotal);
    final double used = plan <= 0
        ? 0
        : (summary.monthSpent / plan).clamp(0.0, 1.0);
    final String headValue = selected == null
        ? '${formatPaise(summary.monthSpent)} this month'
        : formatPaise(summary.spentOn(selected!) ?? 0);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: AppRadius.sheet,
        boxShadow: AppShadows.shadowPanel,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.sheet,
        child: CustomScrollView(
          controller: scroll,
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              sliver: SliverList.list(
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DateStrip(
                    days: summary.days,
                    today: summary.today,
                    selected: selected,
                    onPick: onPick,
                  ),
                  const SizedBox(height: 12),
                  _ListHead(
                    title: selected == null
                        ? 'Recent'
                        : selected == summary.today
                        ? 'Today'
                        : dayTitle(selected!),
                    used: used,
                    over: plan > 0 && summary.monthSpent > plan,
                    value: headValue,
                  ),
                ],
              ),
            ),
            if (rows.isEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: EmptyState(
                    illustration: 'empty_home',
                    title: selected == null
                        ? 'Nothing here yet'
                        : 'No entries this day',
                    message: selected == null
                        ? 'Tap + to add your first expense. '
                              'The monkey keeps the books.'
                        : 'Pick another day, or tap + to add one.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                sliver: SliverList.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int i) =>
                      StaggeredEntrance(
                        key: ValueKey<String>(rows[i].entry.id),
                        index: i,
                        child: HomeEntryRow(view: rows[i]),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// mini_checklist `.lhead`: a display title, a thin progress bar (teal to
/// lime; red when over) and a mono value.
class _ListHead extends StatelessWidget {
  const _ListHead({
    required this.title,
    required this.used,
    required this.over,
    required this.value,
  });

  final String title;
  final double used;
  final bool over;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(title, style: AppTextStyles.sectionTitle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Semantics(
            label: 'Month used ${(used * 100).round()} percent',
            excludeSemantics: true,
            child: Container(
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: used),
                duration: AppMotion.resolve(
                  context,
                  const Duration(milliseconds: 700),
                ),
                curve: AppMotion.grow,
                builder: (BuildContext context, double v, Widget? _) =>
                    FractionallySizedBox(
                      widthFactor: v.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(3),
                          ),
                          gradient: LinearGradient(
                            colors: over
                                ? const <Color>[
                                    AppColors.coral,
                                    AppColors.danger,
                                  ]
                                : const <Color>[AppColors.teal, AppColors.lime],
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(value, style: AppTextStyles.amountSmall.copyWith(fontSize: 12.5)),
      ],
    );
  }
}
