import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/logging/app_logger.dart';
import '../features/quick_add/presentation/quick_add_sheet.dart';
import '../shared/widgets/app_bottom_nav.dart';

/// Screen frame around the four tabs: the tab content plus the bottom bar.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.body,
    required this.logger,
    super.key,
  });

  static const List<String> tabNames = <String>[
    'home',
    'insights',
    'transactions',
    'accounts',
  ];

  final StatefulNavigationShell navigationShell;
  final Widget body;
  final AppLogger logger;

  void _onSelect(int index) {
    if (index != navigationShell.currentIndex) {
      logger.debug('nav', 'tab changed to ${tabNames[index]}');
    }
    // Tapping the current tab goes back to that tab's first screen.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _onQuickAdd(BuildContext context) {
    logger.info('quick_add', 'sheet opened');
    QuickAddSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onSelect: _onSelect,
        onQuickAdd: () => _onQuickAdd(context),
      ),
    );
  }
}
