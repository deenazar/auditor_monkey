import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/logging/logger_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/staggered_entrance.dart';
import '../../../shared/wow/confetti.dart';
import '../../../shared/wow/wow_sheet.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_moment.dart';
import '../application/demo_mode.dart';

/// Debug and profile builds only: a small button that opens the demo data
/// sheet. Shows nothing in release builds.
class DemoDataMenuButton extends ConsumerWidget {
  const DemoDataMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kReleaseMode) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Demo data',
      icon: const Icon(LucideIcons.flaskConical),
      color: AppColors.inkMuted,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: () => showWowSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const DemoDataSheet(),
      ),
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

  bool _loading = false;

  Future<void> _run(
    Future<void> Function() action, {
    required bool load,
  }) async {
    _loading = load;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      // Motion & 3D: a little celebration when demo data arrives.
      if (_loading) Confetti.burst(context);
      Navigator.of(context).pop();
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
            Center(
              child: MascotMoment(
                mood: on ? MascotMood.happy : MascotMood.idle,
                reaction: MascotReaction.hello,
                say: on ? 'Playing with demo data' : 'Want sample data?',
                size: 96,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            const StaggeredEntrance(
              index: 1,
              child: Text('Demo data', style: AppTextStyles.title),
            ),
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
            StaggeredEntrance(
              index: 2,
              child: PrimaryButton(
                label: on ? 'Clear demo data' : 'Load demo data',
                loading: _busy,
                onPressed: _busy
                    ? null
                    : () => _run(
                        on ? controller.clear : controller.load,
                        load: !on,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
