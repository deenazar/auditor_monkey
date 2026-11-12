import '../../../core/sync/synced_entity.dart';

/// Kind of account. Stored as the enum name (lower case).
enum AccountType { cash, bank, card, wallet, pf, other }

/// Allowed account colours: DESIGN.md token names (accounts + chart base).
const Set<String> accountColourTokens = <String>{
  'primary',
  'lime',
  'sun',
  'accountAxis',
  'accountSbi',
  'accountScb',
  'accountHand',
  'accountFoodCard',
  'accountOutside',
  'accountPf',
};

/// An account (Hand, SBI, Axis...). The balance is never stored; see
/// [AccountBalance].
final class Account extends SyncedEntity {
  const Account({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deletedAt,
    required super.syncStatus,
    required this.name,
    required this.type,
    required this.colour,
    required this.openingBalance,
    required this.sortOrder,
    required this.archived,
  });

  final String name;
  final AccountType type;
  final String colour;

  /// Paise. Negative only for card accounts.
  final int openingBalance;
  final int sortOrder;
  final bool archived;
}

/// Values the user can set on an account.
class AccountDraft {
  const AccountDraft({
    required this.name,
    required this.type,
    required this.colour,
    this.openingBalance = 0,
    this.sortOrder = 0,
    this.archived = false,
  });

  final String name;
  final AccountType type;
  final String colour;
  final int openingBalance;
  final int sortOrder;
  final bool archived;
}

/// A live account with its calculated balance in paise.
class AccountBalance {
  const AccountBalance({required this.account, required this.balance});

  final Account account;
  final int balance;
}
