import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import '../domain/transaction_filter.dart';
import '../domain/transaction_filter_validator.dart';

/// Where the saved filter chips are kept (one small text). The store only
/// moves text; [encodeSavedFilters] and [decodeSavedFilters] do the rest.
abstract interface class SavedFiltersStore {
  /// The stored text, or `null` when nothing was saved yet.
  Future<String?> read();

  Future<void> write(String text);
}

/// Tests (and previews) use this one.
class MemorySavedFiltersStore implements SavedFiltersStore {
  MemorySavedFiltersStore([this.text]);

  String? text;

  @override
  Future<String?> read() async => text;

  @override
  Future<void> write(String value) async => text = value;
}

const String savedFiltersFileName = 'saved_filters.json';

/// A JSON file in the app support folder (private to the app, not backed up
/// to the photo / file apps). It holds names, dates and ids of accounts and
/// categories only: no amounts, notes or search text.
class FileSavedFiltersStore implements SavedFiltersStore {
  FileSavedFiltersStore([Future<Directory> Function()? directory])
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  Future<File> _file() async =>
      File(p.join((await _directory()).path, savedFiltersFileName));

  @override
  Future<String?> read() async {
    final File file = await _file();
    return file.existsSync() ? file.readAsString() : null;
  }

  /// Writes to a temp file first and renames it, so a crash in the middle
  /// never leaves a half-written file.
  @override
  Future<void> write(String text) async {
    final File file = await _file();
    await file.parent.create(recursive: true);
    final File temp = File('${file.path}.tmp');
    await temp.writeAsString(text, flush: true);
    await temp.rename(file.path);
  }
}

const int _formatVersion = 1;

String encodeSavedFilters(List<SavedFilter> filters) =>
    jsonEncode(<String, Object?>{
      'version': _formatVersion,
      'filters': <Object?>[for (final SavedFilter f in filters) f.toJson()],
    });

/// Reads [text]. Returns `null` when the whole text is unreadable; single
/// bad entries are dropped. Never throws. Search text is always dropped
/// (chips keep facets only).
List<SavedFilter>? decodeSavedFilters(String? text) {
  if (text == null || text.trim().isEmpty) return const <SavedFilter>[];
  try {
    final Object? root = jsonDecode(text);
    if (root is! Map<String, Object?>) return null;
    final Object? list = root['filters'];
    if (list is! List) return null;
    final List<SavedFilter> out = <SavedFilter>[];
    final Set<String> ids = <String>{};
    for (final Object? item in list) {
      if (item is! Map<String, Object?>) continue;
      final Object? id = item['id'];
      final Object? name = item['name'];
      final Object? filter = item['filter'];
      if (id is! String || !isUuidShape(id) || !ids.add(id)) continue;
      if (name is! String ||
          name.trim().isEmpty ||
          name.length > maxSavedFilterName) {
        continue;
      }
      if (filter is! Map<String, Object?>) continue;
      final TransactionFilter facets = TransactionFilter.fromJson(filter)
          .withoutQuery();
      if (facets.facetCount == 0) continue;
      try {
        validateTransactionFilter(facets);
      } on ValidationFailure {
        continue;
      }
      out.add(SavedFilter(id: id, name: name, filter: facets));
      if (out.length >= maxSavedFilters) break;
    }
    return out;
  } on Object {
    return null;
  }
}
