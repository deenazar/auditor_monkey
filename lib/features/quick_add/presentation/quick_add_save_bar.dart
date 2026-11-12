import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/quick_add_notifier.dart';
import '../application/quick_add_view.dart';
import 'widgets/save_error_card.dart';

/// The save area: the error card (when there is one) above the primary
/// button. The button shows the ring while saving and is off until the
/// entry is complete (see `QuickAddView.canSave`).
class QuickAddSaveBar extends ConsumerWidget {
  const QuickAddSaveBar({required this.view, super.key});

  final QuickAddView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuickAddNotifier n = ref.read(quickAddProvider.notifier);
    final String? error = view.state.saveError;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (error != null) ...<Widget>[
          SaveErrorCard(key: ValueKey<String>(error), message: error),
          const SizedBox(height: AppSpacing.space3),
        ],
        PrimaryButton(
          label: view.saveLabel,
          loading: view.state.isSaving,
          // Stays tappable while saving so the ring shows; save() ignores
          // taps during a save, and PrimaryButton ignores them while loading.
          onPressed: view.canSave || view.state.isSaving
              ? () => n.save()
              : null,
        ),
      ],
    );
  }
}
