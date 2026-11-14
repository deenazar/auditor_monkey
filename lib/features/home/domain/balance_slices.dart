import '../../../core/utils/validation_failure.dart';
import '../../accounts/domain/account.dart';

/// Most slices the doughnut shows (4 accounts + "Other" when there are more).
const int maxBalanceSlices = 5;

/// Accounts shown on their own when "Other" is needed.
const int _namedWhenOther = maxBalanceSlices - 1;

/// Biggest assets total that can be multiplied by 100 without overflow.
const int _maxAssets = 92233720368547758; // (2^63 - 1) ~/ 100

/// One slice of the account balance doughnut.
class BalanceSlice {
  const BalanceSlice({
    required this.accountId,
    required this.label,
    required this.amount,
    required this.percent,
    required this.lessThanOnePercent,
    required this.colourToken,
    required this.memberIds,
  });

  /// The account, or null for the "Other" slice.
  final String? accountId;

  /// Account name, or `Other`.
  final String label;

  /// Paise, always > 0.
  final int amount;

  /// Whole percent of assets (see [buildBalanceSlices]). 0 when
  /// [lessThanOnePercent]. All slices add to 100.
  final int percent;

  /// The real share is under 1%: show `<1%`, not `0%`.
  final bool lessThanOnePercent;

  /// The account's colour token; null for "Other" (use `iconInactive`).
  final String? colourToken;

  /// Account ids behind the slice (one id, or the rest for "Other").
  final List<String> memberIds;

  bool get isOther => accountId == null;

  /// `<1%` or e.g. `50%`.
  String get percentLabel => lessThanOnePercent ? '<1%' : '$percent%';
}

/// The doughnut: slices (biggest first, "Other" last), what they add up to,
/// and what is owed on negative accounts.
class BalanceSlices {
  const BalanceSlices({
    required this.slices,
    required this.assets,
    required this.owed,
  });

  static const BalanceSlices empty = BalanceSlices(
    slices: <BalanceSlice>[],
    assets: 0,
    owed: 0,
  );

  final List<BalanceSlice> slices;

  /// Sum of the slices = sum of all positive balances (paise).
  final int assets;

  /// Sum of the negative balances (paise, zero or negative). Shown as
  /// "Owed -Rs ..." under the ring.
  final int owed;

  bool get hasSlices => slices.isNotEmpty;
  bool get hasOwed => owed < 0;
}

/// Builds the doughnut from account balances (archived accounts included).
///
/// Rules (Session 6 plan, section 2 row 6):
/// - one slice per account with balance > 0; zero balances get no slice;
/// - negative balances get no slice; their sum is [BalanceSlices.owed];
/// - biggest first, ties by sort order, then name, then id;
/// - more than [maxBalanceSlices] accounts: the 4 biggest + "Other" (the sum
///   of the rest), which is always last;
/// - percent = share of assets, whole numbers by the largest-remainder
///   method, so they add to 100. A share under 1% never gets a point from
///   the remainder: it shows `<1%` (percent 0). If the points to hand out
///   outnumber the other slices, they go round again to the biggest
///   remainders.
///
/// Integer paise only. Throws [OverflowFailure] when the total is too large.
BalanceSlices buildBalanceSlices(List<AccountBalance> balances) {
  final List<AccountBalance> positive = <AccountBalance>[];
  int owed = 0;
  for (final AccountBalance b in balances) {
    if (b.balance > 0) {
      positive.add(b);
    } else if (b.balance < 0) {
      owed = _add(owed, b.balance);
    }
  }
  if (positive.isEmpty) {
    return BalanceSlices(slices: const <BalanceSlice>[], assets: 0, owed: owed);
  }
  positive.sort(_biggestFirst);

  final List<_Raw> raw = <_Raw>[];
  if (positive.length <= maxBalanceSlices) {
    for (final AccountBalance b in positive) {
      raw.add(_Raw.account(b));
    }
  } else {
    for (final AccountBalance b in positive.take(_namedWhenOther)) {
      raw.add(_Raw.account(b));
    }
    final List<AccountBalance> rest = positive.sublist(_namedWhenOther);
    int sum = 0;
    for (final AccountBalance b in rest) {
      sum = _add(sum, b.balance);
    }
    raw.add(
      _Raw(
        accountId: null,
        label: 'Other',
        amount: sum,
        colourToken: null,
        memberIds: <String>[for (final AccountBalance b in rest) b.account.id],
      ),
    );
  }

  int assets = 0;
  for (final _Raw r in raw) {
    assets = _add(assets, r.amount);
  }
  if (assets > _maxAssets) throw const OverflowFailure();

  final List<int> percents = _largestRemainder(
    raw.map((_Raw r) => r.amount).toList(),
    assets,
  );
  return BalanceSlices(
    slices: List<BalanceSlice>.unmodifiable(<BalanceSlice>[
      for (int i = 0; i < raw.length; i++)
        BalanceSlice(
          accountId: raw[i].accountId,
          label: raw[i].label,
          amount: raw[i].amount,
          percent: percents[i],
          lessThanOnePercent: raw[i].amount * 100 < assets,
          colourToken: raw[i].colourToken,
          memberIds: List<String>.unmodifiable(raw[i].memberIds),
        ),
    ]),
    assets: assets,
    owed: owed,
  );
}

int _biggestFirst(AccountBalance a, AccountBalance b) {
  if (a.balance != b.balance) return b.balance.compareTo(a.balance);
  if (a.account.sortOrder != b.account.sortOrder) {
    return a.account.sortOrder.compareTo(b.account.sortOrder);
  }
  final int byName = a.account.name.compareTo(b.account.name);
  return byName != 0 ? byName : a.account.id.compareTo(b.account.id);
}

int _add(int a, int b) {
  final int sum = a + b;
  // Two ints of the same sign overflow when the sign flips.
  if ((a >= 0 && b >= 0 && sum < 0) || (a < 0 && b < 0 && sum >= 0)) {
    throw const OverflowFailure();
  }
  return sum;
}

class _Raw {
  const _Raw({
    required this.accountId,
    required this.label,
    required this.amount,
    required this.colourToken,
    required this.memberIds,
  });

  factory _Raw.account(AccountBalance b) => _Raw(
    accountId: b.account.id,
    label: b.account.name,
    amount: b.balance,
    colourToken: b.account.colour,
    memberIds: <String>[b.account.id],
  );

  final String? accountId;
  final String label;
  final int amount;
  final String? colourToken;
  final List<String> memberIds;
}

/// Whole percents of [amounts] in [total] that add to 100. [amounts] are
/// in display order (biggest first), which settles equal remainders.
List<int> _largestRemainder(List<int> amounts, int total) {
  final int n = amounts.length;
  final List<int> floors = <int>[for (final int a in amounts) a * 100 ~/ total];
  final List<int> remainders = <int>[
    for (final int a in amounts) a * 100 % total,
  ];
  int left = 100 - floors.fold<int>(0, (int s, int f) => s + f);

  // Slices with a real share of 1% or more can take a point; tiny ones
  // cannot (they must keep showing "<1%").
  final List<int> order =
      <int>[
        for (int i = 0; i < n; i++)
          if (amounts[i] * 100 >= total) i,
      ]..sort(
        (int a, int b) => remainders[a] != remainders[b]
            ? remainders[b].compareTo(remainders[a])
            : a.compareTo(b),
      );
  if (order.isEmpty) return floors;
  int k = 0;
  while (left > 0) {
    floors[order[k % order.length]]++;
    left--;
    k++;
  }
  return floors;
}
