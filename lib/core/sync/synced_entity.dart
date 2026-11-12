import 'sync_status.dart';

/// Fields every stored item has. Times are UTC epoch milliseconds.
abstract base class SyncedEntity {
  const SyncedEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.syncStatus,
  });

  /// UUID v4 text.
  final String id;
  final int createdAt;
  final int updatedAt;

  /// `null` while the item is live.
  final int? deletedAt;
  final SyncStatus syncStatus;

  bool get isDeleted => deletedAt != null;
}
