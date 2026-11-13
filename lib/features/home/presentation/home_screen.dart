import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/staggered_entrance.dart';
import '../../demo_data/presentation/demo_data_menu_button.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_view.dart';

/// Placeholder for the Home screen (built in a later session). Shows the
/// Auditor Monkey in its idle state above the placeholder message. The demo
/// data menu (debug and profile builds only) sits in the top-right corner.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.space6,
            ),
            child: Column(
              children: <Widget>[
                const StaggeredEntrance(
                  index: 0,
                  child: PageHeader(eyebrow: 'Auditor Monkey', title: 'Home'),
                ),
                Expanded(
                  child: Center(
                    child: StaggeredEntrance(
                      index: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const MascotView(mood: MascotMood.idle, size: 160),
                          const SizedBox(height: AppSpacing.space5),
                          Text(
                            'Your dashboard will show up here.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Align(
            alignment: AlignmentDirectional.topEnd,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space2),
              child: DemoDataMenuButton(),
            ),
          ),
        ],
      ),
    );
  }
}
