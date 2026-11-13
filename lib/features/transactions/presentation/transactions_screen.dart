import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/today_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/wow/parallax.dart';
import '../../../shared/wow/scene_activity.dart';
import 'transactions_panel.dart';
import 'widgets/transactions_header.dart';

/// The Transactions screen: a living header (`WowHeader`) with the month
/// summary on top, then search, filters, saved chips and the day-grouped
/// list. The month summary follows the topmost visible day. The header
/// stays put while the list scrolls; its title parallaxes away.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  /// `YYYY-MM` of the topmost visible day. Only the header listens to it.
  final ValueNotifier<String> _month = ValueNotifier<String>('');
  final ScrollOffset _scroll = ScrollOffset();
  final SceneActivity _activity = SceneActivity();

  @override
  void initState() {
    super.initState();
    _month.value = ref.read(currentMonthProvider);
  }

  @override
  void dispose() {
    _month.dispose();
    _scroll.dispose();
    _activity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.sizeOf(context).height;
    return Material(
      color: AppColors.background,
      child: Listener(
        onPointerDown: (_) => _activity.poke(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // At large text sizes the header scrolls inside this box, so
            // the list always keeps at least half of the screen.
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height * 0.5),
              child: SingleChildScrollView(
                child: TransactionsHeader(
                  month: _month,
                  scroll: _scroll,
                  activity: _activity,
                ),
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _scroll.onScroll,
                child: TransactionsPanel(
                  onMonthChanged: (String m) => _month.value = m,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
