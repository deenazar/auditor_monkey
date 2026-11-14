import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/wow/spring_press.dart';
import '../../../mascot/domain/mascot_mood.dart';
import '../../../mascot/presentation/mascot_moment.dart';

/// A Home section that could not load: a small worried monkey, one short
/// line and "Try again". Only this section shows it; the rest of Home keeps
/// working. [message] is plain text, never amounts or names.
class HomeSectionError extends StatelessWidget {
  const HomeSectionError({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.tile,
          borderRadius: AppRadius.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: <Widget>[
              const ExcludeSemantics(
                child: MascotMoment(
                  mood: MascotMood.worried,
                  size: 64,
                  halo: false,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: Text(message, style: AppTextStyles.body)),
              SpringPress(
                onTap: onRetry,
                semanticLabel: 'Try again',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.minTapTarget,
                    minHeight: AppSpacing.minTapTarget,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: ExcludeSemantics(
                      child: Text(
                        'Try again',
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: AppColors.accentText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
