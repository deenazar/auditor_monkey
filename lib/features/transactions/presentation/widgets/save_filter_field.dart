import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/logger_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/wow/spring_press.dart';
import '../../application/transactions_list_providers.dart';
import '../../domain/transaction_filter.dart';
import '../transactions_actions.dart';

/// Name field plus "Save as chip". The validator's message shows inline
/// under the field. [onSaved] runs after the chip is stored.
class SaveFilterField extends ConsumerStatefulWidget {
  const SaveFilterField({
    required this.filter,
    required this.onSaved,
    this.buttonLabel = 'Save as chip',
    super.key,
  });

  /// The facets to save (search text is not saved).
  final TransactionFilter filter;
  final VoidCallback onSaved;
  final String buttonLabel;

  @override
  ConsumerState<SaveFilterField> createState() => _SaveFilterFieldState();
}

class _SaveFilterFieldState extends ConsumerState<SaveFilterField> {
  final TextEditingController _name = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(savedFiltersProvider.notifier)
          .add(_name.text.trim(), widget.filter.withoutQuery());
      ref.read(loggerProvider).info(transactionsLogTag, 'saved filter added');
      if (mounted) widget.onSaved();
    } on Object catch (error) {
      ref
          .read(loggerProvider)
          .warning(transactionsLogTag, 'saved filter refused');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = failureMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          label: 'Chip name',
          controller: _name,
          maxLength: maxSavedFilterName,
          errorText: _error,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: AppSpacing.space3),
        Align(
          alignment: Alignment.centerRight,
          // Secondary: the sheet's Apply is the one mint action.
          child: _SecondaryButton(
            label: _saving ? 'Saving…' : widget.buttonLabel,
            onTap: _saving ? null : _save,
          ),
        ),
      ],
    );
  }
}

/// A quiet pill button (`tile` with `ink` text), for a second action next to
/// the mint primary one.
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return SpringPress(
      semanticLabel: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Container(
          height: AppSizes.buttonHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.tile,
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyStrong.copyWith(
              color: enabled ? AppColors.ink : AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
