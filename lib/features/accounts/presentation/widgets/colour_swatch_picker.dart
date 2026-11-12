import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import 'account_colours.dart';

/// Row of colour swatches for choosing an account colour.
///
/// Each swatch is a `colourSwatch` circle inside a 44pt tap target. The
/// selected swatch shows a check icon in the swatch's text colour. Each swatch
/// is announced by its colour name.
class ColourSwatchPicker extends StatelessWidget {
  const ColourSwatchPicker({
    required this.tokens,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Colour token names to offer, in display order.
  final List<String> tokens;

  /// The selected token, or null when none is chosen.
  final String? selected;

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: <Widget>[
        for (final String token in tokens)
          _Swatch(
            token: token,
            selected: token == selected,
            onTap: () => onChanged(token),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.token,
    required this.selected,
    required this.onTap,
  });

  final String token;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color colour = accountColourFor(token);
    final String name = accountColourName(token);
    return Semantics(
      label: name,
      button: true,
      selected: selected,
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox(
        width: AppSpacing.minTapTarget,
        height: AppSpacing.minTapTarget,
        child: Material(
          color: AppColors.background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Container(
                width: AppSizes.colourSwatch,
                height: AppSizes.colourSwatch,
                decoration: BoxDecoration(
                  color: colour,
                  shape: BoxShape.circle,
                ),
                child: selected
                    ? Icon(
                        LucideIcons.check,
                        size: AppSizes.iconChip,
                        color: accountTextColourFor(token),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
