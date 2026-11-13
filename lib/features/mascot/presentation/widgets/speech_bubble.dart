import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_depth.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_shadows.dart';
import '../../../../shared/theme/app_text_styles.dart';

/// mini_checklist `.bubble`: white, ink text, 14/14/14/3 corners, fades in
/// and out. Listens to [text] (null hides it). Read out by screen readers.
class SpeechBubble extends StatefulWidget {
  const SpeechBubble({required this.text, super.key});

  final ValueListenable<String?> text;

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble> {
  // Keeps the last text while fading out.
  String _last = '';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: widget.text,
      builder: (BuildContext context, String? value, Widget? _) {
        if (value != null) _last = value;
        final bool show = value != null;
        return IgnorePointer(
          child: Semantics(
            liveRegion: true,
            label: show ? value : null,
            child: AnimatedOpacity(
              opacity: show ? 1 : 0,
              duration: AppMotion.resolve(context, AppDepth.press),
              child: AnimatedSlide(
                offset: show ? Offset.zero : const Offset(0, 0.15),
                duration: AppMotion.resolve(context, AppDepth.press),
                curve: AppDepth.bouncy,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 210),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                      bottomLeft: Radius.circular(3),
                    ),
                    boxShadow: AppShadows.shadowFloat,
                  ),
                  child: Text(
                    _last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong.copyWith(fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
