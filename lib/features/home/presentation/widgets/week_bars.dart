import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_shadows.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass.dart';
import '../../domain/home_format.dart';
import '../../domain/home_summary.dart';

/// The week's spending as seven glass bars (mimi-world `.mw-week`). Today
/// is the warm bar with a dot; the picked day has a white label and ring.
/// Bars grow with a 50 ms stagger (none with reduce motion).
class WeekBars extends StatefulWidget {
  const WeekBars({
    required this.days,
    required this.today,
    required this.selected,
    required this.onPick,
    this.tint = AppColors.glassLight,
    super.key,
  });

  final List<DaySpend> days;
  final String today;
  final String? selected;
  final ValueChanged<String> onPick;

  /// Glass fill (lighter by day, dimmer at night).
  final Color tint;

  @override
  State<WeekBars> createState() => _WeekBarsState();
}

class _WeekBarsState extends State<WeekBars>
    with SingleTickerProviderStateMixin {
  static final Duration _total =
      AppMotion.durationBars + AppMotion.durationBarStagger * 6;

  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: _total,
  );
  List<double> _from = List<double>.filled(7, 0);
  List<double> _to = List<double>.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _to = _fractions(widget.days);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_grow.isDismissed) _start();
  }

  @override
  void didUpdateWidget(WeekBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    final List<double> next = _fractions(widget.days);
    if (!_same(next, _to)) {
      _from = List<double>.generate(7, _value);
      _to = next;
      _start();
    }
  }

  void _start() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _grow.value = 1;
    } else {
      _grow.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  static bool _same(List<double> a, List<double> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static List<double> _fractions(List<DaySpend> days) {
    final int top = days.fold<int>(
      0,
      (int m, DaySpend d) => math.max(m, d.spent),
    );
    return List<double>.generate(7, (int i) {
      if (i >= days.length || top <= 0) return 0;
      return days[i].spent / top;
    });
  }

  double _value(int i) {
    final double start =
        AppMotion.durationBarStagger.inMilliseconds * i / _total.inMilliseconds;
    final double span =
        AppMotion.durationBars.inMilliseconds / _total.inMilliseconds;
    final double local = ((_grow.value - start) / span).clamp(0.0, 1.0);
    final double eased = AppMotion.grow.transform(local);
    return _from[i] + (_to[i] - _from[i]) * eased;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Spending this week',
      child: Glass(
        tint: widget.tint,
        edge: AppColors.glassLightEdge,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.radiusGlassPanel),
        ),
        shadows: AppShadows.shadowGlass,
        padding: const EdgeInsets.fromLTRB(9, 9, 9, 7),
        child: AnimatedBuilder(
          animation: _grow,
          builder: (BuildContext context, Widget? _) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < widget.days.length && i < 7; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 5),
                Expanded(child: _bar(widget.days[i], _value(i))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar(DaySpend day, double fraction) {
    final bool isToday = day.date == widget.today;
    final bool isSelected = day.date == widget.selected;
    final bool empty = day.spent == 0;
    const TextStyle onSky = TextStyle(
      color: AppColors.glassInk,
      shadows: <Shadow>[
        Shadow(color: Color(0x4D000000), blurRadius: 4, offset: Offset(0, 1)),
      ],
    );
    final String value = empty ? '–' : compactRupees(day.spent);
    return PressScale(
      scale: 0.94,
      selected: isSelected,
      semanticLabel:
          '${weekdayLong(day.date)}${isToday ? ', today' : ''}: '
          '${empty ? 'nothing spent' : formatPaise(day.spent)}',
      onTap: () => widget.onPick(day.date),
      child: ExcludeSemantics(
        child: Column(
          children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: AppTextStyles.amountSmall
                    .merge(onSky)
                    .copyWith(fontSize: 9.5, height: 1),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 20),
                  child: AnimatedContainer(
                    duration: AppMotion.resolve(
                      context,
                      AppMotion.durationPress,
                    ),
                    curve: AppMotion.springy,
                    decoration: BoxDecoration(
                      color: AppColors.glassTrack,
                      borderRadius: const BorderRadius.all(Radius.circular(7)),
                      border: isSelected
                          ? Border.all(color: AppColors.glassInk, width: 2)
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(7)),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: math.max(0.06, math.min(1, fraction)),
                          widthFactor: 1,
                          child: Opacity(
                            opacity: empty ? 0.35 : 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(7),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isToday
                                      ? const <Color>[
                                          AppColors.todayBarTop,
                                          AppColors.todayBarBottom,
                                        ]
                                      : const <Color>[
                                          AppColors.barTop,
                                          AppColors.barBottom,
                                        ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (isToday)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: const BoxDecoration(
                  color: AppColors.todayDot,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: AppColors.todayDot, blurRadius: 6),
                  ],
                ),
              ),
            AnimatedContainer(
              duration: AppMotion.resolve(context, AppMotion.durationPress),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.card : const Color(0x00FFFFFF),
                borderRadius: const BorderRadius.all(Radius.circular(5)),
              ),
              child: Text(
                weekdayShort(day.date).toUpperCase(),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: AppTextStyles.overline
                    .merge(isSelected ? null : onSky)
                    .copyWith(
                      fontSize: 8,
                      letterSpacing: 0.2,
                      height: 1,
                      color: isSelected ? AppColors.ink : AppColors.glassInk,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
