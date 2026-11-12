import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_view.dart';

/// Placeholder for the Home screen (built in a later session).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderView(
      eyebrow: 'Auditor Monkey',
      title: 'Home',
      message: 'Your dashboard will show up here.',
    );
  }
}
