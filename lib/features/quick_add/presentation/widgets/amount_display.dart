import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/rolling_amount.dart';
import '../../../transactions/domain/transaction_entry.dart';

/// Shows the amount being typed (DESIGN.md Quick Add, Q2 to Q6).
///
/// [text] is the raw typed text (for example `1250.5`). It is only shown
/// here: the digits are grouped the Indian way (`1,250.5`), with a smaller ₹
/// in front. Money is never a `double` in this widget.
///
/// - Empty: `₹0` in `inkMuted`.
/// - Expense: `ink`. Income: a `+` and the digits in `success` green.
///   Transfer: a ⇄ icon and the digits in `inkMuted`.
/// - [refuseTick] changes when the input is refused: the amount nudges
///   `space2` sideways and back (`durationMedium`). With reduce motion the
///   nudge is instant, so the amount does not move. The [hint] fades in.
/// - [hint] is the line under the amount. [isError] makes it `danger`.
/// - A long press shows a "Paste" menu when [onPaste] is set. It gives the
///   clipboard text to the caller, which validates it.
///
/// The text is shrunk to fit (FittedBox), so it never clips at text scale
/// 2.0. The whole amount is one live region for screen readers.
class AmountDisplay extends StatefulWidget {
  const AmountDisplay({
    required this.text,
    required this.type,
    this.hint,
    this.isError = false,
    this.refuseTick = 0,
    this.onPaste,
    this.paise,
    this.rollTick = 0,
    super.key,
  });

  /// Raw typed text. Empty means nothing typed yet.
  final String text;

  final TransactionType type;

  /// Line under the amount (e.g. a refusal reason). Null hides it.
  final String? hint;

  /// True for a refusal hint (`danger`), false for a normal hint.
  final bool isError;

  /// Increase this to play the refused nudge. The value itself is ignored.
  final int refuseTick;

  /// Called with the clipboard text when the user picks "Paste".
  final ValueChanged<String>? onPaste;

  /// The amount in paise (the screen's `AmountInput.paise`, null when there
  /// is none). Needed for the roll; without it the text is drawn as typed.
  final int? paise;

  /// Increase this when a recent entry was applied: the amount then rolls
  /// from the old value to [paise] over `durationSlow` (instant with reduce
  /// motion). Typing never changes it, so typing stays instant.
  final int rollTick;

  @override
  State<AmountDisplay> createState() => _AmountDisplayState();
}

/// Paise in one rupee, and the digits of the paise part.
const int _paisePerRupee = 100;
const int _paiseDigits = 2;

/// Height of one caption line: the hint line always keeps this room, so a
/// refusal hint never moves the layout below the amount.
final double _hintLineHeight =
    (AppTextStyles.caption.fontSize ?? 0) * (AppTextStyles.caption.height ?? 1);

/// Text for an intermediate paise value while rolling (e.g. `125.37`).
String _paiseAsText(int value) =>
    '${value ~/ _paisePerRupee}.'
    '${(value % _paisePerRupee).toString().padLeft(_paiseDigits, '0')}';

/// Groups the integer part of raw typed text the Indian way and keeps the
/// decimal part as typed. `1250.5` -> `1,250.5`; `12345678` ->
/// `1,23,45,678`; `12.` -> `12.`; `.5` -> `0.5`; empty -> `0`. Pure text.
String groupTypedAmount(String raw) {
  if (raw.isEmpty) return '0';
  final int dot = raw.indexOf('.');
  final String whole = dot < 0 ? raw : raw.substring(0, dot);
  final String decimals = dot < 0 ? '' : raw.substring(dot);
  return '${_groupIndian(whole.isEmpty ? '0' : whole)}$decimals';
}

/// Indian grouping: the last [_lastGroup] digits, then pairs.
const int _lastGroup = 3;
const int _pairGroup = 2;

String _groupIndian(String digits) {
  if (digits.length <= _lastGroup) return digits;
  final String last3 = digits.substring(digits.length - _lastGroup);
  String rest = digits.substring(0, digits.length - _lastGroup);
  final List<String> parts = <String>[];
  while (rest.length > _pairGroup) {
    parts.insert(0, rest.substring(rest.length - _pairGroup));
    rest = rest.substring(0, rest.length - _pairGroup);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

class _AmountDisplayState extends State<AmountDisplay>
    with SingleTickerProviderStateMixin {
  /// `durationSlow` for the roll that follows a recent entry, else zero.
  Duration _rollDuration = Duration.zero;

  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: AppMotion.durationMedium,
  );

  // Out by one step and back: 0 -> 1 -> 0, shaped by curveEnter.
  late final Animation<double> _offset = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0),
        weight: 1,
      ),
    ],
  ).animate(CurvedAnimation(parent: _nudge, curve: AppMotion.curveEnter));

  @override
  void didUpdateWidget(AmountDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rollDuration = widget.rollTick != oldWidget.rollTick
        ? AppMotion.durationSlow
        : Duration.zero;
    if (widget.refuseTick != oldWidget.refuseTick) {
      // Zero duration with reduce motion: the nudge ends at once.
      _nudge.duration = AppMotion.resolve(context, AppMotion.durationMedium);
      _nudge.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _nudge.dispose();
    super.dispose();
  }

  String get _sign => switch (widget.type) {
    TransactionType.income => widget.text.isEmpty ? '' : '+',
    TransactionType.expense || TransactionType.transfer => '',
  };

  Color get _colour {
    if (widget.text.isEmpty) return AppColors.inkMuted;
    return switch (widget.type) {
      TransactionType.expense => AppColors.ink,
      TransactionType.income => AppColors.success,
      TransactionType.transfer => AppColors.inkMuted,
    };
  }

  String get _spoken {
    final String amount = '₹${groupTypedAmount(widget.text)}';
    return switch (widget.type) {
      TransactionType.income when widget.text.isNotEmpty => '+$amount',
      _ => amount,
    };
  }

  Future<void> _showPasteMenu() async {
    final ValueChanged<String>? onPaste = widget.onPaste;
    if (onPaste == null) return;
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final Rect rect =
        box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    final String? choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'paste',
          child: Text('Paste', style: AppTextStyles.bodyStrong),
        ),
      ],
    );
    if (choice != 'paste' || !mounted) return;
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String? clip = data?.text;
    if (clip != null && clip.isNotEmpty && mounted) onPaste(clip);
  }

  @override
  Widget build(BuildContext context) {
    final int? target = widget.paise;
    final Widget number = target == null
        ? _number(widget.text)
        : RollingAmount(
            paise: target,
            duration: _rollDuration,
            builder: (BuildContext context, int value) => _number(
              // The final frame is the exact typed text.
              value == target ? widget.text : _paiseAsText(value),
            ),
          );

    return Semantics(
      liveRegion: true,
      label: _spoken,
      excludeSemantics: true,
      onLongPress: widget.onPaste == null ? null : _showPasteMenu,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: widget.onPaste == null ? null : _showPasteMenu,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedBuilder(
              animation: _offset,
              builder: (BuildContext context, Widget? child) =>
                  Transform.translate(
                    offset: Offset(_offset.value * AppSpacing.space2, 0),
                    child: child,
                  ),
              child: number,
            ),
            const SizedBox(height: AppSpacing.space2),
            // The hint line has a fixed height, shown or not, so a hint never
            // moves what is below. One line, cut with an ellipsis at large
            // text sizes.
            SizedBox(
              height: _hintLineHeight,
              child: Center(
                child: AnimatedSwitcher(
                  duration: AppMotion.resolve(context, AppMotion.durationFast),
                  child: widget.hint == null
                      ? const SizedBox.shrink(key: ValueKey<String>('no-hint'))
                      : Text(
                          widget.hint!,
                          key: ValueKey<String>('hint-${widget.hint}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: widget.isError
                                ? AppColors.danger
                                : AppColors.inkMuted,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The grouped number with the smaller ₹, shrunk to fit.
  Widget _number(String text) {
    final TextStyle amountStyle = AppTextStyles.displayAmount.copyWith(
      color: _colour,
    );
    final TextStyle rupee = AppTextStyles.rupeeSign(amountStyle).copyWith(
      fontFamilyFallback: DefaultTextStyle.of(context).style.fontFamilyFallback,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            if (widget.type == TransactionType.transfer)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space2),
                  child: Icon(
                    LucideIcons.arrowLeftRight,
                    size: AppSizes.iconInline,
                    color: _colour,
                  ),
                ),
              ),
            if (_sign.isNotEmpty) TextSpan(text: _sign),
            TextSpan(text: '₹', style: rupee),
            TextSpan(text: groupTypedAmount(text)),
          ],
        ),
        maxLines: 1,
        softWrap: false,
        style: AppTextStyles.tabular(amountStyle),
      ),
    );
  }
}
