import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/money/money.dart';
import '../../../mascot/domain/mascot_mood.dart';
import '../../../mascot/presentation/mascot_controller.dart';
import '../../../mascot/presentation/mascot_moment.dart';
import '../../../transactions/domain/transaction_entry.dart';
import '../../application/quick_add_notifier.dart';
import '../../application/quick_add_state.dart';

/// The small Auditor Monkey in Quick Add's header (Motion & 3D layer).
/// It perks up while you type the amount, nods when an amount is refused,
/// spins when you switch Expense / Income / Transfer and hops as you save.
class QuickAddMascot extends ConsumerStatefulWidget {
  const QuickAddMascot({this.size = 44, super.key});

  final double size;

  @override
  ConsumerState<QuickAddMascot> createState() => _QuickAddMascotState();
}

class _QuickAddMascotState extends ConsumerState<QuickAddMascot> {
  final MascotController _monkey = MascotController();

  @override
  void dispose() {
    _monkey.dispose();
    super.dispose();
  }

  void _onState(QuickAddState? before, QuickAddState now) {
    if (before == null) return;
    if (now.refusalCount != before.refusalCount) {
      _monkey.react(MascotReaction.sad);
    } else if (now.type != before.type) {
      _monkey.react(
        MascotReaction.spin,
        text: switch (now.type) {
          TransactionType.expense => 'Spending?',
          TransactionType.income => 'Money in!',
          TransactionType.transfer => 'Moving money',
        },
      );
    } else if (now.isSaving && !before.isSaving) {
      final int? paise = now.amount.paise;
      _monkey.react(
        MascotReaction.add,
        text: paise == null ? null : formatPaise(paise),
      );
    } else if (now.amount.text != before.amount.text) {
      _monkey.type();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QuickAddState>(quickAddProvider, _onState);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FittedBox(
        child: MascotMoment(
          controller: _monkey,
          mood: MascotMood.happy,
          size: widget.size,
          halo: false,
        ),
      ),
    );
  }
}
