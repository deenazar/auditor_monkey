import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/validation_failure.dart';
import '../../transactions/application/transactions_providers.dart';
import '../../transactions/data/transactions_repository.dart';

const String _tag = 'quick_add';

/// Undo for the "saved" toast: soft deletes the entry that was just saved.
/// Balances update live through the existing streams.
class QuickAddUndo {
  const QuickAddUndo(this._repository, this._logger);

  final TransactionsRepository _repository;
  final AppLogger _logger;

  /// Returns `true` when the entry was removed. Never throws; logs the
  /// result without any values.
  Future<bool> call(String entryId) async {
    try {
      await _repository.softDelete(entryId);
      _logger.info(_tag, 'undo done');
      return true;
    } on DataFailure catch (failure) {
      _logger.warning(_tag, 'undo failed: ${failure.code.name}');
      return false;
    } on Object {
      _logger.warning(_tag, 'undo failed');
      return false;
    }
  }
}

final Provider<QuickAddUndo> quickAddUndoProvider = Provider<QuickAddUndo>(
  (Ref ref) => QuickAddUndo(
    ref.watch(transactionsRepositoryProvider),
    ref.watch(loggerProvider),
  ),
);
