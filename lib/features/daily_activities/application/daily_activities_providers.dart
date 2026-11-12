import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/daily_activities_repository.dart';
import '../domain/daily_activity.dart';

final Provider<DailyActivitiesRepository> dailyActivitiesRepositoryProvider =
    Provider<DailyActivitiesRepository>(
      (Ref ref) =>
          DailyActivitiesRepository(ref.watch(repositoryContextProvider)),
    );

/// Live activities for a day (`YYYY-MM-DD`).
final dailyActivitiesForDateProvider =
    StreamProvider.family<List<DailyActivity>, String>(
      (Ref ref, String date) =>
          ref.watch(dailyActivitiesRepositoryProvider).watchForDate(date),
    );
