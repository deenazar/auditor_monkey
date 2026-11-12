import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/no_retry.dart';
import '../../accounts/application/accounts_providers.dart';

/// "Setup is done": at least one live account exists (archived ones count).
/// No extra table or setting. Loading while the database opens; an error
/// when it cannot be read (the start screen shows a safe message).
final StreamProvider<bool> setupCompleteProvider = StreamProvider<bool>(
  (Ref ref) => ref.watch(accountsRepositoryProvider).watchHasAccounts(),
  retry: noRetry,
);
