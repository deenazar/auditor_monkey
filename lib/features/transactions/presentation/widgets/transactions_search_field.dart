import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/logging/logger_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_sizes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../application/transactions_list_providers.dart';
import '../transactions_actions.dart';

/// Quiet search box on the panel. Typing waits 250 ms, then sets the
/// filter's search text (one list reload per pause, not per key).
class TransactionsSearchField extends ConsumerStatefulWidget {
  const TransactionsSearchField({super.key});

  /// Pause before the search text is applied.
  static const Duration debounce = Duration(milliseconds: 250);

  @override
  ConsumerState<TransactionsSearchField> createState() =>
      _TransactionsSearchFieldState();
}

class _TransactionsSearchFieldState
    extends ConsumerState<TransactionsSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(transactionFilterProvider).query,
  );
  final FocusNode _focus = FocusNode();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _timer?.cancel();
    _timer = Timer(TransactionsSearchField.debounce, _apply);
    setState(() {});
  }

  void _apply() {
    _timer?.cancel();
    _timer = null;
    final String text = _controller.text;
    ref.read(transactionFilterProvider.notifier).setQuery(text);
    // The text itself is never logged.
    ref.read(loggerProvider).debug(transactionsLogTag, 'search applied');
  }

  void _clear() {
    _timer?.cancel();
    _timer = null;
    _controller.clear();
    ref.read(transactionFilterProvider.notifier).setQuery('');
    setState(() {});
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // Filter cleared from elsewhere (for example "Clear filters"): follow it.
    ref.listen<String>(transactionFilterProvider.select((f) => f.query), (
      String? previous,
      String next,
    ) {
      if (_timer == null && _controller.text != next) {
        _controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
        setState(() {});
      }
    });
    final bool hasText = _controller.text.isNotEmpty;
    return Container(
      height: AppSizes.fieldHeight - 4,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.field,
        border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 12),
          const ExcludeSemantics(
            child: Icon(
              LucideIcons.search,
              size: AppSizes.iconInline,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              maxLength: 60,
              onChanged: _onChanged,
              onSubmitted: (_) => _apply(),
              textInputAction: TextInputAction.search,
              style: AppTextStyles.body.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Search notes, categories, amount',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.inkMuted,
                ),
                counterText: '',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (hasText)
            Semantics(
              button: true,
              label: 'Clear search',
              child: SizedBox(
                width: AppSpacing.minTapTarget,
                height: AppSpacing.minTapTarget,
                child: IconButton(
                  onPressed: _clear,
                  icon: const Icon(
                    LucideIcons.x,
                    size: AppSizes.iconChip,
                    color: AppColors.inkMuted,
                  ),
                  tooltip: 'Clear search',
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}
