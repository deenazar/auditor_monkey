// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loans_dao.dart';

// ignore_for_file: type=lint
mixin _$LoansDaoMixin on DatabaseAccessor<AppDatabase> {
  $LoansTable get loans => attachedDatabase.loans;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $CategoriesTable get categories => attachedDatabase.categories;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  LoansDaoManager get managers => LoansDaoManager(this);
}

class LoansDaoManager {
  final _$LoansDaoMixin _db;
  LoansDaoManager(this._db);
  $$LoansTableTableManager get loans =>
      $$LoansTableTableManager(_db.attachedDatabase, _db.loans);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
}
