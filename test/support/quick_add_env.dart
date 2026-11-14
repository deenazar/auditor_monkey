import 'package:auditor_monkey/features/accounts/domain/account.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_data_provider.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_edit.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_notifier.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_state.dart';
import 'package:auditor_monkey/features/quick_add/application/quick_add_view.dart';
import 'package:auditor_monkey/features/transactions/domain/transaction_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'provider_env.dart';
import 'test_env.dart';

/// A container for Quick Add tests: wired to [env], with the sheet's
/// providers kept alive (as the open sheet does).
class QuickAddHarness {
  /// [edit] opens the sheet in edit mode for that entry.
  QuickAddHarness(this.env, {TransactionEntry? edit})
    : container = containerFor(env) {
    if (edit != null) {
      container.read(quickAddEditProvider.notifier).begin(edit);
    }
    _keep = <ProviderSubscription<Object?>>[
      container.listen(quickAddProvider, (_, _) {}),
      container.listen(quickAddDataProvider, (_, _) {}),
      container.listen(quickAddViewProvider, (_, _) {}),
    ];
  }

  final TestEnv env;
  final ProviderContainer container;
  late final List<ProviderSubscription<Object?>> _keep;

  QuickAddNotifier get notifier => container.read(quickAddProvider.notifier);
  QuickAddState get state => container.read(quickAddProvider);
  QuickAddView get view => container.read(quickAddViewProvider);

  Future<QuickAddData> loaded() async {
    final QuickAddData data = await container.read(quickAddDataProvider.future);
    await pumpEventQueue(); // let the view provider pick the data up
    return data;
  }

  /// Types [keys] on the pad ('.' is the dot).
  void type(String keys) {
    for (final String k in keys.split('')) {
      k == '.' ? notifier.pressDot() : notifier.pressDigit(k);
    }
  }

  void dispose() {
    for (final ProviderSubscription<Object?> s in _keep) {
      s.close();
    }
    container.dispose();
  }
}

/// A test database whose clock reads 2026-11-12 (the fixed test day).
TestEnv quickAddTestEnv() {
  final TestEnv env = TestEnv();
  env.clock.now = DateTime(2026, 11, 12, 10).millisecondsSinceEpoch;
  return env;
}

/// Hand (opening 1,000.00), SBI (5,000.00) and Axis (0.00), in this order.
Future<List<Account>> threeAccounts(TestEnv env) async {
  final List<(String, int)> specs = <(String, int)>[
    ('Hand', 100000),
    ('SBI', 500000),
    ('Axis', 0),
  ];
  final List<Account> out = <Account>[];
  for (final (String name, int opening) in specs) {
    out.add(
      await env.accounts.create(
        AccountDraft(
          name: name,
          type: AccountType.bank,
          colour: 'accountSbi',
          openingBalance: opening,
          sortOrder: out.length,
        ),
      ),
    );
  }
  return out;
}
