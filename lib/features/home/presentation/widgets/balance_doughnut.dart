import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_depth.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_shadows.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/wow/haptics.dart';
import '../../../../shared/wow/tilt_3d.dart';
import '../../../mascot/domain/mascot_mood.dart';
import '../../../mascot/presentation/mascot_controller.dart';
import '../../../mascot/presentation/mascot_moment.dart';
import '../../domain/balance_slices.dart';
import 'dashboard_money.dart';
import 'doughnut_legend.dart';

/// Pop-out of a selected slice, in pt (plan: 6pt).
const double _popOut = 6;

/// Gap between the ring and the card edge, so the pop-out fits.
const double _ringInset = 10;

/// "Where your money is": the account balance doughnut with its legend.
///
/// Plain data in ([slices] from `buildBalanceSlices`), no providers.
/// - The ring sweeps in clockwise ([AppDepth.chartDraw]) and morphs when the
///   data changes ([AppDepth.chartDraw] too). Reduce motion shows the final
///   ring at once.
/// - First tap on a slice selects it: it pops out by 6pt, a selection haptic
///   plays, the centre shows that account and the monkey looks at it and
///   says e.g. "PF holds 50%". Second tap calls [onOpenAccount] with the
///   account id. "Other" has no account, so its second tap does nothing.
/// - The legend rows select the same way.
/// - Negative balances are not drawn: they show as an "Owed -₹..." line.
/// - No positive balance: the ring is hidden and a mascot moment explains it.
///
/// The ring is in a [RepaintBoundary]; only the sweep and the pop-out move,
/// the rest of the card stays still.
class BalanceDoughnut extends StatefulWidget {
  const BalanceDoughnut({
    required this.slices,
    required this.onOpenAccount,
    this.ringSize = 176,
    super.key,
  });

  /// The slices, owed sum and assets from `buildBalanceSlices`.
  final BalanceSlices slices;

  /// Called with the account id on the second tap of a slice.
  final ValueChanged<String> onOpenAccount;

  /// Width and height of the ring, in pt.
  final double ringSize;

  @override
  State<BalanceDoughnut> createState() => _BalanceDoughnutState();
}

class _BalanceDoughnutState extends State<BalanceDoughnut> {
  final MascotController _mascot = MascotController();
  int? _selected;

  @override
  void dispose() {
    _mascot.dispose();
    super.dispose();
  }

  /// Slice [i] was tapped (from the ring or the legend).
  void _tap(int i) {
    final BalanceSlice slice = widget.slices.slices[i];
    if (_selected == i) {
      final String? id = slice.accountId;
      if (id != null) widget.onOpenAccount(id);
      return;
    }
    AppHaptics.tap();
    setState(() => _selected = i);
    _mascot.look(_directionOf(i));
    _mascot.say('${slice.label} holds ${slice.percentLabel}');
  }

  void _onTouch(FlTouchEvent event, PieTouchResponse? response) {
    if (event is! FlTapUpEvent) return;
    final int i = response?.touchedSection?.touchedSectionIndex ?? -1;
    if (i < 0 || i >= widget.slices.slices.length) return;
    _tap(i);
  }

  /// Direction from the ring centre to the middle of slice [i] (screen
  /// axes, the ring starts at 12 o'clock and runs clockwise).
  Offset _directionOf(int i) {
    final List<BalanceSlice> all = widget.slices.slices;
    final int total = widget.slices.assets;
    if (total <= 0) return Offset.zero;
    int before = 0;
    for (int k = 0; k < i; k++) {
      before += all[k].amount;
    }
    final double mid = (before + all[i].amount / 2) / total;
    final double angle = mid * 2 * math.pi - math.pi / 2;
    return Offset(math.cos(angle), math.sin(angle));
  }

  @override
  Widget build(BuildContext context) {
    final BalanceSlices data = widget.slices;
    final int? sel = _selected != null && _selected! < data.slices.length
        ? _selected
        : null;
    return Tilt3D(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.tile,
          borderRadius: AppRadius.card,
          boxShadow: AppShadows.shadowLayered,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Where your money is', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.space3),
              if (data.hasSlices) ...<Widget>[
                // Its own row, centred, so the speech bubble has room on
                // both sides at any text scale.
                Center(
                  child: MascotMoment(
                    controller: _mascot,
                    size: 72,
                    halo: false,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Center(child: _ring(context, sel)),
                const SizedBox(height: AppSpacing.space3),
                if (data.hasOwed) _owedLine(data.owed),
                const SizedBox(height: AppSpacing.space2),
                DoughnutLegend(
                  slices: data.slices,
                  selectedIndex: sel,
                  onSelect: _tap,
                ),
              ] else if (data.hasOwed) ...<Widget>[
                _owedLine(data.owed),
                const SizedBox(height: AppSpacing.space3),
                const Center(
                  child: MascotMoment(
                    mood: MascotMood.idle,
                    say: 'Only debts for now',
                    size: 120,
                    halo: false,
                  ),
                ),
              ] else
                const Center(
                  child: MascotMoment(
                    mood: MascotMood.idle,
                    say: 'Add an account balance to see it here',
                    size: 120,
                    halo: false,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _owedLine(int owed) => Text(
    'Owed ${minusMoney(owed)}',
    style: AppTextStyles.caption.copyWith(color: AppColors.inkMuted),
    textAlign: TextAlign.center,
  );

  Widget _ring(BuildContext context, int? sel) {
    final BalanceSlices data = widget.slices;
    final bool reduce = AppMotion.reduceMotion(context);
    final double outer = widget.ringSize / 2 - _ringInset;
    final double thickness = outer * 0.25;
    final double centre = outer - thickness;
    final double total = data.assets.toDouble();

    return Semantics(
      label: 'Assets, ${formatPaise(data.assets)}',
      container: true,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.ringSize,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: reduce ? 1 : 0, end: 1),
            duration: reduce ? Duration.zero : AppDepth.chartDraw,
            curve: AppDepth.draw,
            builder: (BuildContext context, double sweep, Widget? _) {
              // While the ring sweeps in, a transparent filler takes the
              // rest of the circle. The filler is never a touch target.
              final List<PieChartSectionData> sections = <PieChartSectionData>[
                for (int i = 0; i < data.slices.length; i++)
                  PieChartSectionData(
                    value: data.slices[i].amount.toDouble(),
                    color: sliceColour(data.slices[i]),
                    radius: i == sel ? thickness + _popOut : thickness,
                    cornerRadius: 4,
                    showTitle: false,
                    borderSide: BorderSide.none,
                  ),
                if (sweep < 1)
                  PieChartSectionData(
                    value: total * (1 - sweep),
                    color: const Color(0x00000000),
                    radius: thickness,
                    showTitle: false,
                    borderSide: BorderSide.none,
                  ),
              ];
              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: centre,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(touchCallback: _onTouch),
                    ),
                    // Morph only when the data changes, not during the sweep.
                    duration: sweep < 1 || reduce
                        ? Duration.zero
                        : AppMotion.durationChart,
                    curve: AppMotion.curveEnter,
                  ),
                  _centre(data, sel, centre),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// "ASSETS" and the total, or the selected account and its amount.
  Widget _centre(BalanceSlices data, int? sel, double centre) {
    final BalanceSlice? slice = sel == null ? null : data.slices[sel];
    final String caption = slice == null ? 'ASSETS' : slice.label;
    final String amount = slice == null
        ? formatPaise(data.assets)
        : '${formatPaise(slice.amount)} · ${slice.percentLabel}';
    return ExcludeSemantics(
      child: SizedBox(
        width: centre * 1.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                caption,
                style: slice == null
                    ? AppTextStyles.overline
                    : AppTextStyles.caption,
                maxLines: 1,
                softWrap: false,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(amount, style: AppTextStyles.bodyStrong),
            ),
          ],
        ),
      ),
    );
  }
}
