import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_shadows.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/category_icon_circle.dart';
import '../../../accounts/presentation/widgets/account_colours.dart';
import '../../domain/transaction_entry.dart';
import '../../domain/transaction_list_item.dart';
import '../transactions_format.dart';

/// The entry's hero card. It tilts in 3D as the finger moves over it and
/// springs back on release (off with reduce motion). Transfers show the
/// From and To accounts in their colours with an arrow that slides in.
class DetailHero extends StatefulWidget {
  const DetailHero({required this.item, super.key});

  final TransactionListItem item;

  /// Largest tilt in radians (about 7 degrees).
  static const double maxTilt = 0.12;

  @override
  State<DetailHero> createState() => _DetailHeroState();
}

class _DetailHeroState extends State<DetailHero>
    with SingleTickerProviderStateMixin {
  /// x = rotation around Y (left-right), y = rotation around X (up-down).
  final ValueNotifier<Offset> _tilt = ValueNotifier<Offset>(Offset.zero);
  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: AppMotion.durationSlow,
  )..addListener(_onBack);
  Offset _from = Offset.zero;
  Size _size = Size.zero;

  @override
  void dispose() {
    _back.dispose();
    _tilt.dispose();
    super.dispose();
  }

  void _onBack() {
    final double t = AppMotion.springy.transform(_back.value);
    _tilt.value = _from * (1 - t);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_size.isEmpty) return;
    _back.stop();
    final double nx = (d.localPosition.dx / _size.width * 2 - 1).clamp(
      -1.0,
      1.0,
    );
    final double ny = (d.localPosition.dy / _size.height * 2 - 1).clamp(
      -1.0,
      1.0,
    );
    _tilt.value = Offset(nx * DetailHero.maxTilt, -ny * DetailHero.maxTilt);
  }

  void _springBack() {
    _from = _tilt.value;
    if (_from == Offset.zero) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _tilt.value = Offset.zero;
      return;
    }
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = AppMotion.reduceMotion(context);
    final Widget card = _HeroCard(item: widget.item);
    if (reduce) return card;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        _size = Size(c.maxWidth, c.maxHeight.isFinite ? c.maxHeight : 260);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: _onPanUpdate,
          onPanEnd: (DragEndDetails _) => _springBack(),
          onPanCancel: _springBack,
          child: ValueListenableBuilder<Offset>(
            valueListenable: _tilt,
            builder: (BuildContext context, Offset tilt, Widget? child) =>
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateX(tilt.dy)
                    ..rotateY(tilt.dx),
                  child: child,
                ),
            child: card,
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.item});

  final TransactionListItem item;

  @override
  Widget build(BuildContext context) {
    final TransactionEntry e = item.entry;
    final Color amountColour = switch (e.type) {
      TransactionType.expense => AppColors.ink,
      TransactionType.income => AppColors.success,
      TransactionType.transfer => AppColors.inkMuted,
    };
    final String kind = kindLabel(e.type).toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.hero,
        border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
        boxShadow: AppShadows.shadowFloat,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (item.isTransfer)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.fill,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: AppSizes.iconCircle,
                    child: Icon(
                      LucideIcons.arrowLeftRight,
                      size: AppSizes.iconInline,
                      color: AppColors.inkMuted,
                    ),
                  ),
                )
              else
                CategoryIconCircle(
                  iconName: item.categoryIcon ?? '',
                  colourGroup:
                      item.categoryColourGroup ??
                      (e.type == TransactionType.income ? 'income' : 'other'),
                ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  kind,
                  style: AppTextStyles.overline.copyWith(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              signedAmount(e),
              maxLines: 1,
              style: AppTextStyles.displayAmount.copyWith(color: amountColour),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            item.isTransfer ? 'Moved between accounts' : item.title,
            style: AppTextStyles.headline.copyWith(fontSize: 17),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(longDate(e.date), style: AppTextStyles.caption),
          if (item.isTransfer) ...<Widget>[
            const SizedBox(height: AppSpacing.space5),
            _TransferFlow(item: item),
          ],
        ],
      ),
    );
  }
}

/// From account, a sliding arrow, To account; both in their colours.
class _TransferFlow extends StatelessWidget {
  const _TransferFlow({required this.item});

  final TransactionListItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Flexible(
          child: _AccountPill(
            name: item.accountName,
            colour: accountColourFor(item.accountColour),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: AppMotion.resolve(context, AppMotion.durationSlow),
          curve: AppMotion.springy,
          builder: (BuildContext context, double t, Widget? child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset((1 - t) * -12, 0),
              child: child,
            ),
          ),
          child: const ExcludeSemantics(
            child: Icon(
              LucideIcons.arrowRight,
              size: AppSizes.iconInline,
              color: AppColors.inkMuted,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Flexible(
          child: _AccountPill(
            name: item.toAccountName ?? '',
            colour: accountColourFor(item.toAccountColour ?? ''),
          ),
        ),
      ],
    );
  }
}

class _AccountPill extends StatelessWidget {
  const _AccountPill({required this.name, required this.colour});

  final String name;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final Color text = colour.computeLuminance() > 0.5
        ? AppColors.ink
        : AppColors.onDark;
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.chipIconCircle + 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colour, borderRadius: AppRadius.pill),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyStrong.copyWith(fontSize: 13, color: text),
      ),
    );
  }
}
