import 'package:auditor_monkey/core/database/database_provider.dart';
import 'package:auditor_monkey/core/logging/logger_provider.dart';
import 'package:auditor_monkey/core/utils/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'test_env.dart';

/// Provider overrides that point the app at [env]: its in-memory database,
/// its clock and its logger (so log checks see everything).
List<Override> envOverrides(TestEnv env) => <Override>[
  appDatabaseProvider.overrideWithValue(env.db),
  clockProvider.overrideWithValue(env.clock),
  loggerProvider.overrideWithValue(env.ctx.logger),
];

/// A container wired to [env]. Dispose it in tearDown.
ProviderContainer containerFor(
  TestEnv env, {
  List<Override> extra = const [],
}) => ProviderContainer(overrides: <Override>[...envOverrides(env), ...extra]);
