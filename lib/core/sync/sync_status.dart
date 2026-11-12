/// Sync state of a row. Stored as TEXT in `sync_status`.
///
/// Every local write sets `pending`; the sync session (later) sets `synced`.
enum SyncStatus {
  pending,
  synced;

  /// Reads the stored text. Unknown text is treated as `pending`, so a row
  /// is never silently skipped by the sync queue.
  static SyncStatus parse(String value) => SyncStatus.values.firstWhere(
    (SyncStatus s) => s.name == value,
    orElse: () => SyncStatus.pending,
  );
}
