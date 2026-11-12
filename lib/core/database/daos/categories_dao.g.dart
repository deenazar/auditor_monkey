// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories_dao.dart';

// ignore_for_file: type=lint
mixin _$CategoriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $LoansTable get loans => attachedDatabase.loans;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  CategoriesDaoManager get managers => CategoriesDaoManager(this);
}

class CategoriesDaoManager {
  final _$CategoriesDaoMixin _db;
  CategoriesDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$LoansTableTableManager get loans =>
      $$LoansTableTableManager(_db.attachedDatabase, _db.loans);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
}
