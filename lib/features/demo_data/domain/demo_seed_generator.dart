import 'dart:math';

import '../../../core/utils/date_keys.dart';
import '../../transactions/domain/transaction_entry.dart';
import 'demo_accounts.dart';

/// Days of history the demo data covers, ending today.
const int demoDays = 90;

/// Builds deterministic, realistic Indian personal-finance entries for the
/// 90 days up to [today]. The same [today] and [seed] always give the same
/// list. No entry takes an account below zero.
List<TransactionDraft> generateDemoTransactions(
  DateTime today, {
  int seed = 20261113,
}) => _DemoGenerator(today, Random(seed)).build();

class _DemoGenerator {
  _DemoGenerator(this.today, this.r);

  final DateTime today;
  final Random r;
  final List<TransactionDraft> out = <TransactionDraft>[];

  /// Random whole rupees in [lo, hi] as paise (sometimes with 50 paise).
  int _paise(int lo, int hi) {
    final int rupees = lo + r.nextInt(hi - lo + 1);
    return rupees * 100 + (hi > 200 && r.nextInt(4) == 0 ? 50 : 0);
  }

  String _pick(List<String> notes) => notes[r.nextInt(notes.length)];
  bool _chance(double p) => r.nextDouble() < p;

  void _add(
    DateTime d,
    TransactionType type,
    int paise,
    String account,
    String? category,
    String note, {
    String? to,
  }) {
    out.add(
      TransactionDraft(
        type: type,
        amount: paise,
        date: dateKey(d),
        accountId: demoAccountIds[account]!,
        toAccountId: to == null ? null : demoAccountIds[to],
        categoryId: category == null ? null : demoCategoryIds[category],
        note: note,
      ),
    );
  }

  void _spend(DateTime d, String acc, String cat, int paise, String note) =>
      _add(d, TransactionType.expense, paise, acc, cat, note);

  void _earn(DateTime d, String acc, String cat, int paise, String note) =>
      _add(d, TransactionType.income, paise, acc, cat, note);

  void _move(DateTime d, String from, String to, int paise, String note) =>
      _add(d, TransactionType.transfer, paise, from, null, note, to: to);

  List<TransactionDraft> build() {
    final DateTime start = DateTime(
      today.year,
      today.month,
      today.day - (demoDays - 1),
    );
    for (int i = 0; i < demoDays; i++) {
      final DateTime d = DateTime(start.year, start.month, start.day + i);
      _monthly(d);
      _daily(d);
    }
    _oneOffs(start);
    return _keepBalancesPositive(out);
  }

  void _monthly(DateTime d) {
    switch (d.day) {
      case 1:
        _earn(d, 'SBI', 'Salary', 8500000, 'Monthly salary credit');
        _move(d, 'SBI', 'Food Card', 350000, 'Food card top-up');
        _move(d, 'SBI', 'PF', 500000, 'PF contribution (monthly SIP)');
      case 2:
        _spend(d, 'SBI', 'Rent', 2200000, 'House rent - UPI to landlord');
        _move(d, 'SBI', 'Axis', 1500000, 'Money for daily spending');
      case 3:
        _spend(d, 'SBI', 'EMI', 650000, 'Bike loan EMI - auto debit');
      case 4:
        _spend(d, 'Outside', 'Family Support', 400000, 'Sent home to parents');
      case 5:
        _spend(d, 'SBI', 'Mobile & Internet', 39900, 'Jio mobile recharge');
        _move(d, 'SBI', 'Hand', 500000, 'ATM withdrawal');
      case 8:
        _spend(
          d,
          'SBI',
          'Electricity & Water',
          _paise(1400, 2200),
          'BESCOM electricity bill',
        );
      case 10:
        _spend(
          d,
          'SBI',
          'Mobile & Internet',
          104900,
          'Broadband - ACT Fibernet',
        );
      case 12:
        if (d.month.isEven) {
          _spend(d, 'SBI', 'Gas (LPG)', 90300, 'LPG cylinder refill');
        }
      case 14:
        _spend(d, 'SCB', 'Entertainment & OTT', 19900, 'Netflix subscription');
      case 15:
        _spend(d, 'SBI', 'Insurance', 125000, 'Health insurance premium');
      case 18:
        _move(d, 'SBI', 'SCB', _paise(8000, 11000), 'Credit card bill payment');
      case 20:
        _earn(d, 'Axis', 'Business / Freelance', 1200000, 'Freelance project');
        _move(d, 'SBI', 'Hand', 400000, 'ATM withdrawal');
      case 28:
        _earn(d, 'Axis', 'Interest', _paise(320, 420), 'Savings interest');
        _earn(d, 'PF', 'Interest', 190000, 'PF interest credit');
    }
  }

  void _daily(DateTime d) {
    final bool weekday = d.weekday <= DateTime.friday;
    final bool weekend = !weekday;
    if (weekday && _chance(0.8)) {
      _spend(d, 'Hand', 'Tea & Snacks', _paise(20, 120), _pick(_tea));
    }
    if (_chance(0.5)) {
      _spend(d, 'Food Card', 'Food & Dining', _paise(180, 480), _pick(_food));
    }
    if (weekend && _chance(0.3)) {
      _spend(d, 'Axis', 'Food & Dining', _paise(600, 1500), 'Dinner out');
    }
    if (_chance(0.3)) {
      _spend(d, 'Axis', 'Groceries', _paise(400, 2600), _pick(_grocery));
    }
    if (_chance(0.28)) {
      _spend(d, 'Hand', 'Groceries', _paise(80, 320), 'Sabzi from the market');
    }
    if (weekday && _chance(0.6)) {
      _spend(d, 'Axis', 'Transport', _paise(120, 380), _pick(_ride));
    }
    if (_chance(0.4)) {
      _spend(d, 'Hand', 'Transport', _paise(30, 150), _pick(_local));
    }
    if (_chance(0.07)) {
      _spend(d, 'Axis', 'Fuel', _paise(500, 800), 'HP petrol pump');
    }
    if (_chance(0.06)) {
      _spend(
        d,
        'Hand',
        'Health & Medicine',
        _paise(120, 900),
        'Apollo Pharmacy',
      );
    }
    if (_chance(0.06)) {
      _spend(d, 'SCB', 'Entertainment & OTT', _paise(250, 650), _pick(_fun));
    }
    if (_chance(0.07)) {
      _spend(d, 'SCB', 'Shopping', _paise(800, 3500), _pick(_shop));
    }
    if (_chance(0.04)) {
      _spend(d, 'Hand', 'Personal Care', _paise(150, 500), 'Salon haircut');
    }
    if (_chance(0.04)) {
      _spend(
        d,
        'Axis',
        'Household',
        _paise(200, 1200),
        'DMart household items',
      );
    }
    if (_chance(0.03)) {
      _earn(d, 'Axis', 'Refund / Cashback', _paise(50, 400), 'Paytm cashback');
    }
  }

  /// One entry for every category the random rules might miss, so every
  /// category is used.
  void _oneOffs(DateTime start) {
    DateTime at(int offset) =>
        DateTime(start.year, start.month, start.day + offset);
    _earn(at(5), 'Outside', 'Loan Received', 1000000, 'Borrowed from brother');
    _earn(at(9), 'Outside', 'Gifts Received', 200000, 'Birthday gift money');
    _earn(at(14), 'Axis', 'Other Income', 80000, 'Sold old books');
    _earn(
      at(40),
      'Outside',
      'Loan Repayment Received',
      600000,
      'Friend paid back',
    );
    _spend(at(11), 'Outside', 'Loan Given', 500000, 'Lent to a friend');
    _spend(at(35), 'SBI', 'Loan Repayment', 400000, 'Repaid brother');
    _spend(at(17), 'Axis', 'Education', 149900, 'Online course - Udemy');
    _spend(at(22), 'Hand', 'Repairs & Maintenance', 60000, 'Plumber visit');
    _spend(at(27), 'SCB', 'Clothes', 249900, 'Myntra - kurta and jeans');
    _spend(at(31), 'SCB', 'Travel', 112000, 'IRCTC train tickets');
    _spend(at(45), 'Outside', 'Gifts & Festivals', 300000, 'Diwali gifts');
    _spend(at(50), 'Hand', 'Donations', 50100, 'Temple donation');
    _spend(
      at(55),
      'Hand',
      'Other Expense',
      35000,
      'Passport photo and courier',
    );
    _spend(at(60), 'SBI', 'Gas (LPG)', 90300, 'LPG cylinder refill');
    _spend(at(3), 'Axis', 'Fuel', 62000, 'HP petrol pump');
    _spend(at(8), 'Hand', 'Health & Medicine', 48000, 'Apollo Pharmacy');
    _spend(at(12), 'Hand', 'Personal Care', 25000, 'Salon haircut');
    _spend(at(19), 'Axis', 'Household', 84000, 'DMart household items');
    _spend(at(24), 'SCB', 'Shopping', 189900, 'Amazon order');
    _spend(at(29), 'SCB', 'Entertainment & OTT', 78000, 'PVR movies');
    _spend(at(4), 'Hand', 'Tea & Snacks', 6000, 'Chai and samosa');
    _spend(at(6), 'Food Card', 'Food & Dining', 38000, 'Swiggy - biryani');
    _spend(at(7), 'Axis', 'Groceries', 142050, 'BigBasket monthly order');
    _spend(at(2), 'Axis', 'Transport', 21000, 'Uber to office');
    _spend(at(1), 'SBI', 'Mobile & Internet', 39900, 'Jio mobile recharge');
    _earn(at(33), 'Axis', 'Refund / Cashback', 15000, 'Amazon refund');
    _earn(at(0), 'Axis', 'Interest', 36000, 'Savings interest');
  }

  /// Drops any expense or transfer that would take its account below zero.
  List<TransactionDraft> _keepBalancesPositive(List<TransactionDraft> all) {
    int rank(TransactionDraft t) => switch (t.type) {
      TransactionType.income => 0,
      TransactionType.transfer => 1,
      TransactionType.expense => 2,
    };
    final List<TransactionDraft> sorted = List<TransactionDraft>.of(all)
      ..sort((a, b) {
        final int byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : rank(a).compareTo(rank(b));
      });
    final Map<String, int> bal = <String, int>{
      for (final MapEntry<String, int> e in demoOpeningBalances.entries)
        demoAccountIds[e.key]!: e.value,
    };
    final List<TransactionDraft> kept = <TransactionDraft>[];
    for (final TransactionDraft t in sorted) {
      if (t.type == TransactionType.income) {
        bal[t.accountId] = bal[t.accountId]! + t.amount;
      } else {
        if (bal[t.accountId]! < t.amount) continue;
        bal[t.accountId] = bal[t.accountId]! - t.amount;
        if (t.type == TransactionType.transfer) {
          bal[t.toAccountId!] = bal[t.toAccountId!]! + t.amount;
        }
      }
      kept.add(t);
    }
    return kept;
  }
}

const List<String> _tea = <String>[
  'Chai and samosa',
  'Tea stall',
  'Filter coffee',
  'Chai and biscuits',
];
const List<String> _food = <String>[
  'Swiggy - biryani',
  'Zomato - paneer thali',
  'Swiggy - dosa combo',
  'Zomato - veg meals',
  'Lunch at office canteen',
];
const List<String> _grocery = <String>[
  'BigBasket order',
  'DMart monthly stock',
  'BigBasket - milk and fruits',
  'DMart - atta and dal',
];
const List<String> _ride = <String>[
  'Uber to office',
  'Ola cab',
  'Uber ride home',
];
const List<String> _local = <String>[
  'Ola auto',
  'Metro card recharge',
  'Auto to station',
  'Bus pass top-up',
];
const List<String> _fun = <String>[
  'PVR movies',
  'BookMyShow tickets',
  'Spotify',
];
const List<String> _shop = <String>[
  'Amazon order',
  'Myntra order',
  'Flipkart sale',
];
