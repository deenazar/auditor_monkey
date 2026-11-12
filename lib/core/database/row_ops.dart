import 'package:drift/drift.dart';

/// Soft delete one live row: sets `deleted_at`, bumps `updated_at` and marks
/// the row `pending`. Returns the number of rows changed (0 or 1).
Future<int> softDeleteRow(
  GeneratedDatabase db,
  TableInfo<Table, Object?> table,
  String id,
  int now,
) => db.customUpdate(
  'UPDATE ${table.actualTableName} '
  'SET deleted_at = ?, updated_at = max(?, created_at), '
  "sync_status = 'pending' WHERE id = ? AND deleted_at IS NULL",
  variables: <Variable<Object>>[
    Variable<int>(now),
    Variable<int>(now),
    Variable<String>(id),
  ],
  updates: <TableInfo<Table, Object?>>{table},
  updateKind: UpdateKind.update,
);

/// Restore one soft-deleted row (clears `deleted_at`, marks it `pending`).
Future<int> restoreRow(
  GeneratedDatabase db,
  TableInfo<Table, Object?> table,
  String id,
  int now,
) => db.customUpdate(
  'UPDATE ${table.actualTableName} '
  'SET deleted_at = NULL, updated_at = max(?, created_at), '
  "sync_status = 'pending' WHERE id = ? AND deleted_at IS NOT NULL",
  variables: <Variable<Object>>[Variable<int>(now), Variable<String>(id)],
  updates: <TableInfo<Table, Object?>>{table},
  updateKind: UpdateKind.update,
);

/// Value for `updated_at`: now, but never before `created_at` (the clock
/// may have moved back).
int updatedAtFor(int createdAt, int now) => now < createdAt ? createdAt : now;
