import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/logging/app_logger.dart';
import '../features/quick_add/application/quick_add_saved.dart';
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

  /// Opens Quick Add. The toast comes from [quickAddSavedProvider] (see
  /// [build]), so it shows even if the sheet closed while saving.
  void _onQuickAdd(BuildContext context) {
    logger.info('quick_add', 'sheet opened');
    QuickAddSheet.show(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SavedEntry?>(quickAddSavedProvider, (
      SavedEntry? previous,
      SavedEntry? saved,
    ) {
      if (saved == null) return;
      showSavedToast(context, saved, undo: ref.read(quickAddUndoProvider));
      ref.read(quickAddSavedProvider.notifier).clear();
    });
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
