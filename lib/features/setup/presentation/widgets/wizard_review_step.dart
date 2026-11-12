import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../accounts/presentation/widgets/account_colours.dart';
import '../../application/setup_wizard_state.dart';
import 'wizard_frame.dart';

/// Step 3 (W3): the starting net worth, one mini card per account, and
/// "Create accounts". While saving the button shows a ring and is off, so
/// a second tap does nothing. A failed save keeps the entries and shows why.
class WizardReviewStep extends StatelessWidget {
  const WizardReviewStep({
    required this.state,
    required this.onBack,
    required this.onSave,
    super.key,
  });

  final SetupWizardState state;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final List<WizardAccount> picked = state.selected;
    final String? error = state.saveError;
    return WizardFrame(
      stepIndex: 2,
      onBack: onBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PageHeader(eyebrow: 'Step 3 of 3', title: 'All set?'),
          const SizedBox(height: AppSpacing.space6),
          Text(
            'STARTING NET WORTH',
            textAlign: TextAlign.center,
            style: AppTextStyles.overline.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.space1),
          AmountText(
            paise: state.totalPaise ?? 0,
            style: AppTextStyles.headline,
            alignment: AlignmentDirectional.center,
          ),
          const SizedBox(height: AppSpacing.space6),
          for (final WizardAccount a in picked) ...<Widget>[
            _MiniCard(account: a, paise: state.openingFor(a).paise ?? 0),
            const SizedBox(height: AppSpacing.space3),
          ],
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (error != null) ...<Widget>[
            _ErrorCard(message: error),
            const SizedBox(height: AppSpacing.space3),
          ],
          PrimaryButton(
            label: 'Create accounts',
            loading: state.isSaving,
            onPressed: state.canSave ? onSave : null,
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.account, required this.paise});

  final WizardAccount account;
  final int paise;

  @override
  Widget build(BuildContext context) {
    final Color text = accountTextColourFor(account.colour);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accountColourFor(account.colour),
        borderRadius: AppRadius.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                account.name,
                style: AppTextStyles.bodyStrong.copyWith(color: text),
              ),
            ),
            AmountText(
              paise: paise,
              style: AppTextStyles.body,
              color: text,
              alignment: AlignmentDirectional.centerEnd,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.tile,
          borderRadius: AppRadius.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                LucideIcons.triangleAlert,
                size: AppSizes.iconInline,
                color: AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: Text(message, style: AppTextStyles.body)),
            ],
          ),
        ),
      ),
    );
  }
}
