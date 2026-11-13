import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import 'num_pad_key.dart';

/// The Quick Add number pad: 4 rows of 3 keys (1-9, point, 0, delete).
///
/// Pure: it reports taps and does not hold any amount. Tapping delete calls
/// [onBackspace]; holding it calls [onClear]. Keys have `space2` gaps and
/// are `numPadKeyHeight` tall. With [enabled] false (while saving) every key
/// is inert.
class NumberPad extends StatelessWidget {
  const NumberPad({
    required this.onDigit,
    required this.onDot,
    required this.onBackspace,
    required this.onClear,
    this.enabled = true,
    super.key,
  });

  /// Called with "0" to "9".
  final ValueChanged<String> onDigit;

  /// Called for the decimal point.
  final VoidCallback onDot;

  /// Called for a short tap on delete.
  final VoidCallback onBackspace;

  /// Called for a long press on delete ("clear all").
  final VoidCallback onClear;

  final bool enabled;

  static const List<String> _digitRows = <String>['123', '456', '789'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final String row in _digitRows) ...<Widget>[
          _Row(
            children: <Widget>[
              for (final String digit in row.split('')) _digitKey(digit),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
        _Row(
          children: <Widget>[
            NumPadKey(
              label: 'point',
              enabled: enabled,
              onTap: enabled ? onDot : null,
              child: _face('.'),
            ),
            _digitKey('0'),
            NumPadKey(
              label: 'delete',
              enabled: enabled,
              onTap: enabled ? onBackspace : null,
              onLongPress: enabled ? onClear : null,
              child: Icon(
                LucideIcons.delete,
                size: AppSizes.iconNav,
                color: enabled ? AppColors.ink : AppColors.iconInactive,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _digitKey(String digit) {
    return NumPadKey(
      label: digit,
      enabled: enabled,
      onTap: enabled ? () => onDigit(digit) : null,
      child: _face(digit),
    );
  }

  Widget _face(String text) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: AppTextStyles.headline.copyWith(
          color: enabled ? AppColors.ink : AppColors.iconInactive,
        ),
      ),
    );
  }
}

/// One row of three keys with `space2` between them.
class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: AppSpacing.space2),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}
