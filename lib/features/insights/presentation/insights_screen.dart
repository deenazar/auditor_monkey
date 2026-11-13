import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_view.dart';

/// Placeholder for the Insights screen (built in a later session).
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderView(
      eyebrow: 'Your Spending',
      title: 'Insights',
      message: 'Charts will show up here.',
      illustration: 'empty_insights',
    );
  }
}
