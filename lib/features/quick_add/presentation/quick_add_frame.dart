import 'package:flutter/material.dart';

import '../../../shared/theme/app_spacing.dart';

/// Layout of the Quick Add sheet: header, amount, number pad and Save stay
/// pinned; only the middle part scrolls (small phones, large text).
class QuickAddFrame extends StatelessWidget {
  const QuickAddFrame({
    required this.header,
    required this.amount,
    required this.middle,
    required this.pad,
    required this.save,
    super.key,
  });

  final Widget header;
  final Widget amount;

  /// Recent strip, category row, detail pills. Scrolls.
  final Widget middle;
  final Widget pad;

  /// Save button, with the error card above it when there is one.
  final Widget save;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space2,
            AppSpacing.space4,
            0,
          ),
          child: header,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: amount,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: middle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: pad,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space3,
            AppSpacing.screenPadding,
            AppSpacing.space4,
          ),
          child: save,
        ),
      ],
    );
  }
}
