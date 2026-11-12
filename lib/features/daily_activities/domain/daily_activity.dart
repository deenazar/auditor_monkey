import '../../../core/sync/synced_entity.dart';

final class DailyActivity extends SyncedEntity {
  const DailyActivity({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
    required super.syncStatus,
    required this.date,
    required this.title,
    required this.note,
  });

  final String date;
  final String title;
  final String? note;
}

class DailyActivityDraft {
  const DailyActivityDraft({
    required this.date,
    required this.title,
    this.note,
  });

  final String date;
  final String title;
  final String? note;
}
