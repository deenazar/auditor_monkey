import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/logging/app_logger.dart';
import '../features/quick_add/application/quick_add_state.dart';
import '../features/quick_add/application/quick_add_undo.dart';
import '../features/quick_add/presentation/quick_add_sheet.dart';
import '../features/quick_add/presentation/quick_add_toast_host.dart';
import '../shared/widgets/app_bottom_nav.dart';

/// Screen frame around the four tabs: the tab content plus the bottom bar.
class AppShell extends ConsumerWidget {
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

  /// Opens Quick Add. After a save the sheet returns the entry and this
  /// shell (which stays mounted) shows the toast with Undo.
  Future<void> _onQuickAdd(BuildContext context, WidgetRef ref) async {
    logger.info('quick_add', 'sheet opened');
    final QuickAddUndo undo = ref.read(quickAddUndoProvider);
    final SavedEntry? saved = await QuickAddSheet.show(context);
    if (saved == null || !context.mounted) return;
    showSavedToast(context, saved, undo: undo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: body,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onSelect: _onSelect,
        onQuickAdd: () => _onQuickAdd(context, ref),
      ),
    );
  }
}
