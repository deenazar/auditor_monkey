import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/logging/logger_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_icon_button.dart';
import '../application/demo_mode.dart';

/// Debug and profile builds only: a small button that opens the demo data
/// sheet. Shows nothing in release builds.
class DemoDataMenuButton extends ConsumerWidget {
  const DemoDataMenuButton({this.glass = false, super.key});

  /// Draws as a glass pill (on the Home sky).
  final bool glass;

  void _open(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const DemoDataSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kReleaseMode) return const SizedBox.shrink();
    if (glass) {
      return GlassIconButton(
        icon: LucideIcons.flaskConical,
        semanticLabel: 'Demo data',
        onTap: () => _open(context),
      );
    }
    return IconButton(
      tooltip: 'Demo data',
      icon: const Icon(LucideIcons.flaskConical),
      color: AppColors.inkMuted,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: () => _open(context),
    );
  }
}

/// The sheet: Load demo data / Clear demo data.
class DemoDataSheet extends ConsumerStatefulWidget {
  const DemoDataSheet({super.key});

  @override
  ConsumerState<DemoDataSheet> createState() => _DemoDataSheetState();
}

class _DemoDataSheetState extends ConsumerState<DemoDataSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      ref
          .read(loggerProvider)
          .error('demo', 'demo action failed', error: error);
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not do that. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool on = ref.watch(demoModeActiveProvider);
    final DemoModeController controller = ref.read(
      demoModeControllerProvider.notifier,
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space6,
          0,
          AppSpacing.space6,
          AppSpacing.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Demo data', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.space2),
            Text(
              on
                  ? 'Demo data is on. Your real data is safe and untouched.'
                  : 'Fills a separate demo copy for testing the look. '
                        'Your real data is never changed.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.space4),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                child: Text(
                  _error!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(on ? controller.clear : controller.load),
              child: Text(on ? 'Clear demo data' : 'Load demo data'),
            ),
          ],
        ),
      ),
    );
  }
}
