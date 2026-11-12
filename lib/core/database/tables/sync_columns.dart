import 'package:drift/drift.dart';

/// Columns every table has. See docs/DATABASE.md.
///
/// - `id`: UUID v4 text made in Dart.
/// - `created_at`, `updated_at`: UTC epoch milliseconds (plain integers).
/// - `deleted_at`: `NULL` while the row is live; the delete time otherwise.
/// - `sync_status`: `pending` after every local write, `synced` after sync.
///
/// The CHECK rules are written as plain strings on purpose: Drift needs
/// constant text to put them in the schema dump used by migration tests.
mixin SyncColumns on Table {
  TextColumn get id =>
      text().customConstraint('NOT NULL CHECK (length(id) = 36)')();

  IntColumn get createdAt => integer().customConstraint(
    "NOT NULL CHECK (typeof(created_at) = 'integer')",
  )();

  IntColumn get updatedAt => integer().customConstraint(
    "NOT NULL CHECK (typeof(updated_at) = 'integer' "
    'AND updated_at >= created_at)',
  )();

  IntColumn get deletedAt => integer().nullable().customConstraint(
    "CHECK (deleted_at IS NULL OR typeof(deleted_at) = 'integer')",
  )();

  TextColumn get syncStatus => text()
      .clientDefault(() => 'pending')
      .customConstraint(
        "NOT NULL DEFAULT 'pending' "
        "CHECK (sync_status IN ('pending', 'synced'))",
      )();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
