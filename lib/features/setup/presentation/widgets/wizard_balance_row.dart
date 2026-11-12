import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/money_input_formatter.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/widgets/account_colours.dart';
import '../../../accounts/presentation/widgets/owes_toggle.dart';
import '../../application/setup_wizard_state.dart';
import '../../domain/opening_balance_input.dart';

/// One account row of the balances step: colour dot and name, then the
/// amount field, then the "I have / I owe" toggle for cards. Grouping
/// (1,23,456) is added when the field loses focus.
class WizardBalanceRow extends StatefulWidget {
  const WizardBalanceRow({
    required this.account,
    required this.error,
    required this.onChanged,
    required this.onOwesChanged,
    super.key,
  });

  final WizardAccount account;

  /// Friendly amount problem, or `null`.
  final String? error;

  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onOwesChanged;

  @override
  State<WizardBalanceRow> createState() => _WizardBalanceRowState();
}

class _WizardBalanceRowState extends State<WizardBalanceRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.account.balanceText,
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(WizardBalanceRow old) {
    super.didUpdateWidget(old);
    // Keep the field in step with the wizard state (not while typing).
    final String text = widget.account.balanceText;
    if (!_focus.hasFocus && _controller.text != text) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focus.hasFocus) return;
    final String grouped = groupRupeeText(_controller.text);
    if (grouped != _controller.text) {
      _controller.value = TextEditingValue(
        text: grouped,
        selection: TextSelection.collapsed(offset: grouped.length),
      );
    }
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final WizardAccount a = widget.account;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: accountColourFor(a.colour),
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: AppSizes.colourDot),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(child: Text(a.name, style: AppTextStyles.bodyStrong)),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        AppTextField(
          label: 'Balance for ${a.name}',
          controller: _controller,
          focusNode: _focus,
          prefixText: '₹',
          hintText: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const <TextInputFormatter>[MoneyInputFormatter()],
          errorText: widget.error,
          onChanged: widget.onChanged,
        ),
        if (a.type == AccountType.card) ...<Widget>[
          const SizedBox(height: AppSpacing.space3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OwesToggle(owes: a.owes, onChanged: widget.onOwesChanged),
          ),
        ],
      ],
    );
  }
}
