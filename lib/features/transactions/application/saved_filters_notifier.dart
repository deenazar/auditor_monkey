import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/logger_provider.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/validation_failure.dart';
import '../data/saved_filters_store.dart';
import '../domain/transaction_filter.dart';
import '../domain/transaction_filter_validator.dart';

const String _tag = 'saved_filters';

final RegExp _controlChars = RegExp(r'[\u0000-\u001F\u007F]');

/// Where saved filters are kept. Tests override it with
/// [MemorySavedFiltersStore].
final Provider<SavedFiltersStore> savedFiltersStoreProvider =
    Provider<SavedFiltersStore>((Ref ref) => FileSavedFiltersStore());

/// Saved filter chips, oldest first.
final AsyncNotifierProvider<SavedFiltersNotifier, List<SavedFilter>>
savedFiltersProvider =
    AsyncNotifierProvider<SavedFiltersNotifier, List<SavedFilter>>(
      SavedFiltersNotifier.new,
    );

class SavedFiltersNotifier extends AsyncNotifier<List<SavedFilter>> {
  Future<void> _queue = Future<void>.value();

  SavedFiltersStore get _store => ref.read(savedFiltersStoreProvider);

  /// Reads the file. A missing file is an empty list; a corrupt or
  /// unreadable one is an empty list too (warning in the log), never a
  /// crash.
  @override
  Future<List<SavedFilter>> build() async {
    final log = ref.read(loggerProvider);
    try {
      final List<SavedFilter>? read = decodeSavedFilters(await _store.read());
      if (read == null) {
        log.warning(_tag, 'saved filters file is corrupt, starting empty');
        return const <SavedFilter>[];
      }
      return read;
    } on Object {
      log.warning(_tag, 'saved filters could not be read, starting empty');
      return const <SavedFilter>[];
    }
  }

  /// Saves [filter]'s facets under [name]. Throws `ValidationFailure`
  /// (plain message) for an empty / too long / duplicate name, an empty
  /// filter, or more than [maxSavedFilters]. A failed write throws
  /// `StorageFailure` and changes nothing.
  Future<SavedFilter> add(String name, TransactionFilter filter) =>
      _serial<SavedFilter>(() async {
        final String clean = _checkName(name);
        final TransactionFilter facets = validateTransactionFilter(filter)
            .withoutQuery();
        if (facets.facetCount == 0) {
          throw const ValidationFailure(
            'filter',
            FailureCode.required,
            'Pick at least one filter to save.',
          );
        }
        final List<SavedFilter> current = await future;
        if (current.length >= maxSavedFilters) {
          throw const ValidationFailure(
            'name',
            FailureCode.rule,
            'You can save up to $maxSavedFilters filters. Remove one first.',
          );
        }
        final String lower = clean.toLowerCase();
        if (current.any((SavedFilter s) => s.name.toLowerCase() == lower)) {
          throw const ValidationFailure(
            'name',
            FailureCode.duplicate,
            'You already have a filter with this name.',
          );
        }
        final SavedFilter saved = SavedFilter(
          id: ref.read(idGeneratorProvider).newId(),
          name: clean,
          filter: facets,
        );
        await _persist(<SavedFilter>[...current, saved]);
        ref.read(loggerProvider).info(_tag, 'add ok');
        return saved;
      });

  Future<void> remove(String id) => _serial<void>(() async {
    final List<SavedFilter> current = await future;
    final List<SavedFilter> next = <SavedFilter>[
      for (final SavedFilter s in current)
        if (s.id != id) s,
    ];
    if (next.length == current.length) return;
    await _persist(next);
    ref.read(loggerProvider).info(_tag, 'remove ok');
  });

  String _checkName(String name) {
    final String text = name.trim();
    if (text.isEmpty) {
      throw const ValidationFailure(
        'name',
        FailureCode.required,
        'Give this filter a name.',
      );
    }
    if (text.length > maxSavedFilterName) {
      throw const ValidationFailure(
        'name',
        FailureCode.tooLong,
        'Use $maxSavedFilterName characters or fewer.',
      );
    }
    if (_controlChars.hasMatch(text)) {
      throw const ValidationFailure(
        'name',
        FailureCode.invalidCharacters,
        'Remove special characters.',
      );
    }
    return text;
  }

  Future<void> _persist(List<SavedFilter> next) async {
    try {
      await _store.write(encodeSavedFilters(next));
    } on Object {
      ref.read(loggerProvider).warning(_tag, 'could not write saved filters');
      throw const StorageFailure();
    }
    if (ref.mounted) state = AsyncData<List<SavedFilter>>(next);
  }

  /// One change at a time, so two quick saves cannot overwrite each other.
  Future<T> _serial<T>(Future<T> Function() body) {
    final Future<T> result = _queue.then((_) => body());
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }
}
