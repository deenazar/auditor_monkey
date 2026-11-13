import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/today_provider.dart';
import '../../../shared/theme/app_colors.dart';
import 'transactions_panel.dart';
import 'widgets/transactions_stage.dart';

/// The Transactions screen, in Home's layout: a compact sky on top (title,
/// month summary) and a panel that slides over it with search, filters,
/// saved chips and the day-grouped list. The month summary follows the
/// topmost visible day.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  /// `YYYY-MM` of the topmost visible day. Only the stage listens to it.
  final ValueNotifier<String> _month = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _month.value = ref.read(currentMonthProvider);
  }

  @override
  void dispose() {
    _month.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.panel,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final double padTop = MediaQuery.paddingOf(context).top;
          final double stageH =
              padTop + (c.maxHeight * 0.3).clamp(200.0, 250.0);
          final double initial = ((c.maxHeight - stageH + 22) / c.maxHeight)
              .clamp(0.2, 0.9);
          final double max = ((c.maxHeight - padTop - 64) / c.maxHeight).clamp(
            initial,
            1.0,
          );
          return Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: stageH,
                child: TransactionsStage(month: _month),
              ),
              DraggableScrollableSheet(
                initialChildSize: initial,
                minChildSize: initial,
                maxChildSize: max,
                snap: true,
                builder: (BuildContext context, ScrollController scroll) =>
                    MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: TransactionsPanel(
                        scroll: scroll,
                        onMonthChanged: (String m) => _month.value = m,
                      ),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}
