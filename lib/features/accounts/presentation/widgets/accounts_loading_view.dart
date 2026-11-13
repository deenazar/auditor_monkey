import 'package:flutter/material.dart';

import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/skeleton_block.dart';

/// Static skeleton of the Accounts screen while balances load: a header
/// line, one card-sized block and three row blocks. No animation.
class AccountsLoadingView extends StatelessWidget {
  const AccountsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // The page title is static text, so it shows while data loads.
          const PageHeader(eyebrow: 'Your Wallet', title: 'Accounts'),
          const SizedBox(height: AppSpacing.space6),
          const SkeletonBlock(height: AppSizes.accountCardHeight),
          const SizedBox(height: AppSpacing.sectionGap),
          for (int i = 0; i < 3; i++) ...<Widget>[
            const SkeletonBlock(height: AppSizes.iconCircle),
            const SizedBox(height: AppSpacing.listRowGap),
          ],
        ],
      ),
    );
  }
}
