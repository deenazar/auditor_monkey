import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/utils/no_retry.dart';
import '../../../core/utils/today_provider.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';

final Provider<DashboardRepository> dashboardRepositoryProvider =
    Provider<DashboardRepository>(
      (Ref ref) => DashboardRepository(ref.watch(repositoryContextProvider)),
    );

/// The Dashboard numbers of the current month, read in one snapshot and
/// re-read whenever entries, accounts, categories or budgets change, and
/// when [todayProvider] rolls to a new day (app resume).
final StreamProvider<DashboardSummary> dashboardSummaryProvider =
    StreamProvider<DashboardSummary>((Ref ref) {
      final DashboardRepository repo = ref.watch(dashboardRepositoryProvider);
      final String today = ref.watch(todayProvider);
      return repo.watchSignal().asyncMap((_) => repo.load(today: today));
    }, retry: noRetry);
