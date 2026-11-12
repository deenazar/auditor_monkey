import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../features/setup/domain/opening_balance_input.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/money_input_formatter.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/account.dart';
import '../../domain/account_form_rules.dart';
import 'account_form_values.dart';
import 'account_type_chips.dart';
import 'colour_swatch_picker.dart';
import 'owes_toggle.dart';

/// The add / edit account form (DESIGN "W1s"). Used by the setup wizard and
/// by the Accounts and statement screens.
///
/// Fields: name, type chips, colour swatches and, when [showOpeningBalance]
/// is set, the opening balance with the "I owe" toggle for cards. Errors
/// show under the field while typing (after the first change) and on
/// press. [onSave] runs the real save; return an [AccountFormError] to show
/// it, or `null` to close the sheet.
class AccountFormSheet extends StatefulWidget {
  const AccountFormSheet({
    required this.title,
    required this.submitLabel,
    required this.otherNames,
    required this.onSave,
    this.initial,
    this.showOpeningBalance = false,
    this.onRemove,
    super.key,
  });

  final String title;
  final String submitLabel;

  /// Names of the other accounts, for the duplicate check (ignoring case).
  final List<String> otherNames;

  /// Values to start with. Null means a blank new account.
  final AccountFormValues? initial;

  final bool showOpeningBalance;

  /// Saves the form. Return `null` on success (the sheet then closes).
  final Future<AccountFormError?> Function(AccountFormValues values) onSave;

  /// Shows "Remove account" when given (used for wizard accounts the user
  /// added). Called before the sheet closes.
  final VoidCallback? onRemove;

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

const AccountType _defaultType = AccountType.bank;
const String _defaultColour = 'primary';

class _AccountFormSheetState extends State<AccountFormSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late final TextEditingController _balance = TextEditingController(
    text: widget.initial?.balanceText ?? '',
  );
  final FocusNode _balanceFocus = FocusNode();
  late AccountType _type = widget.initial?.type ?? _defaultType;
  late String _colour = widget.initial?.colour ?? _defaultColour;
  late bool _owes =
      (widget.initial?.owes ?? false) && _type == AccountType.card;

  bool _nameTouched = false;
  bool _balanceTouched = false;
  bool _attempted = false;
  bool _saving = false;
  AccountFormError? _serverError;

  final List<String> _colourChoices = accountColourTokens.toList();

  @override
  void initState() {
    super.initState();
    // Put grouping (1,23,456) on the amount when the field loses focus.
    _balanceFocus.addListener(_onBalanceFocus);
  }

  @override
  void dispose() {
    _balanceFocus.removeListener(_onBalanceFocus);
    _balanceFocus.dispose();
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  void _onBalanceFocus() {
    if (_balanceFocus.hasFocus) return;
    final String grouped = groupRupeeText(_balance.text);
    if (grouped != _balance.text) {
      _balance.value = TextEditingValue(
        text: grouped,
        selection: TextSelection.collapsed(offset: grouped.length),
      );
    }
  }

  String? get _nameProblem =>
      accountNameError(_name.text, otherNames: widget.otherNames);

  OpeningBalanceInput get _opening =>
      parseOpeningBalance(_balance.text, type: _type, owes: _owes);

  bool get _valid =>
      _nameProblem == null && (!widget.showOpeningBalance || _opening.isValid);

  AccountFormValues _values() => AccountFormValues(
    name: _name.text.trim(),
    type: _type,
    colour: _colour,
    balanceText: _balance.text,
    owes: _owes && _type == AccountType.card,
  );

  String? _errorFor(String field) {
    if (_serverError?.field == field) return _serverError!.message;
    if (field == 'name' && (_nameTouched || _attempted)) return _nameProblem;
    if (field == 'balance' && (_balanceTouched || _attempted)) {
      return _opening.error;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _attempted = true;
      _serverError = null;
    });
    if (!_valid) return;
    setState(() => _saving = true);
    final AccountFormError? error = await widget.onSave(_values());
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _serverError = error;
    });
  }

  void _remove() {
    widget.onRemove?.call();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCard = _type == AccountType.card;
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.space6,
          AppSpacing.screenPadding,
          AppSpacing.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title,
            ),
            const SizedBox(height: AppSpacing.space5),
            AppTextField(
              label: 'Name',
              controller: _name,
              maxLength: accountNameMaxLength,
              errorText: _errorFor('name'),
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() => _nameTouched = true),
            ),
            const SizedBox(height: AppSpacing.space5),
            const _Caption('Type'),
            const SizedBox(height: AppSpacing.space2),
            AccountTypeChips(
              selected: _type,
              onChanged: (AccountType t) => setState(() {
                _type = t;
                if (t != AccountType.card) _owes = false;
              }),
            ),
            const SizedBox(height: AppSpacing.space5),
            const _Caption('Colour'),
            const SizedBox(height: AppSpacing.space2),
            ColourSwatchPicker(
              tokens: _colourChoices,
              selected: _colour,
              onChanged: (String token) => setState(() => _colour = token),
            ),
            if (widget.showOpeningBalance) ...<Widget>[
              const SizedBox(height: AppSpacing.space5),
              AppTextField(
                label: 'Opening balance',
                controller: _balance,
                focusNode: _balanceFocus,
                prefixText: '₹',
                hintText: '0',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: const <TextInputFormatter>[
                  MoneyInputFormatter(),
                ],
                errorText: _errorFor('balance'),
                onChanged: (_) => setState(() => _balanceTouched = true),
              ),
              const SizedBox(height: AppSpacing.space2),
              const _Caption('Your balance today. Leave empty for ₹0.00.'),
              if (isCard) ...<Widget>[
                const SizedBox(height: AppSpacing.space3),
                OwesToggle(
                  owes: _owes,
                  onChanged: (bool owes) => setState(() => _owes = owes),
                ),
              ],
            ],
            if (_serverError != null &&
                _serverError!.field == null) ...<Widget>[
              const SizedBox(height: AppSpacing.space3),
              Text(
                _serverError!.message,
                style: AppTextStyles.caption.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: AppSpacing.space6),
            PrimaryButton(
              label: widget.submitLabel,
              loading: _saving,
              onPressed: _saving ? null : _submit,
            ),
            if (widget.onRemove != null) ...<Widget>[
              const SizedBox(height: AppSpacing.space2),
              _RemoveButton(onTap: _remove),
            ],
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(color: AppColors.ink),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Remove account',
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: AppSpacing.minTapTarget,
          child: Center(
            child: Text(
              'Remove account',
              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.danger),
            ),
          ),
        ),
      ),
    );
  }
}
