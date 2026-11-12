import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Text field in the DESIGN.md style: `tile` fill, no border, `radiusField`.
/// Focused: 2pt `primaryDeep` line. Error: 2pt `danger` line and a `caption`
/// message in `danger` below the field.
///
/// The label sits above the field (not inside it), so it stays readable
/// when the field is filled. The field is at least `fieldHeight` tall.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.prefixText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.autofocus = false,
    super.key,
  });

  /// Shown above the field and read by screen readers.
  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;

  /// Fixed text before the input, e.g. "₹".
  final String? prefixText;

  /// Error message below the field. Null means no error.
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  /// Longest allowed input. The counter is hidden; the field stops at this
  /// length.
  final int? maxLength;
  final bool autofocus;

  static const OutlineInputBorder _noBorder = OutlineInputBorder(
    borderRadius: AppRadius.field,
    borderSide: BorderSide.none,
  );

  static const OutlineInputBorder _focusBorder = OutlineInputBorder(
    borderRadius: AppRadius.field,
    borderSide: BorderSide(
      color: AppColors.primaryDeep,
      width: AppSizes.fieldLineWidth,
    ),
  );

  static const OutlineInputBorder _errorBorder = OutlineInputBorder(
    borderRadius: AppRadius.field,
    borderSide: BorderSide(
      color: AppColors.danger,
      width: AppSizes.fieldLineWidth,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final InputDecoration decoration = InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
      prefixText: prefixText,
      prefixStyle: AppTextStyles.body,
      filled: true,
      fillColor: AppColors.tile,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      border: _noBorder,
      enabledBorder: _noBorder,
      disabledBorder: _noBorder,
      focusedBorder: _focusBorder,
      errorBorder: _errorBorder,
      focusedErrorBorder: _errorBorder,
      errorText: errorText,
      errorMaxLines: 2,
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.danger),
    );

    return Semantics(
      label: label,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.ink),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.fieldHeight),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: decoration,
              style: AppTextStyles.body,
              cursorColor: AppColors.primaryDeep,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              inputFormatters: inputFormatters,
              maxLength: maxLength,
              autofocus: autofocus,
              buildCounter: (
                BuildContext context, {
                required int currentLength,
                required bool isFocused,
                required int? maxLength,
              }) => null,
            ),
          ),
        ],
      ),
    );
  }
}
