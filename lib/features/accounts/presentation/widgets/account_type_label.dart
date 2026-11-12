import '../../domain/account.dart';

/// Short label for an account type, shown as text (e.g. "Bank", "PF").
String accountTypeLabel(AccountType type) {
  return switch (type) {
    AccountType.cash => 'Cash',
    AccountType.bank => 'Bank',
    AccountType.card => 'Card',
    AccountType.wallet => 'Wallet',
    AccountType.pf => 'PF',
    AccountType.other => 'Other',
  };
}
