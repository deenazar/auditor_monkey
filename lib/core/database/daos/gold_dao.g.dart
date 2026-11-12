// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gold_dao.dart';

// ignore_for_file: type=lint
mixin _$GoldDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountsTable get accounts => attachedDatabase.accounts;
  $GoldHoldingsTable get goldHoldings => attachedDatabase.goldHoldings;
  $GoldRatesTable get goldRates => attachedDatabase.goldRates;
  GoldDaoManager get managers => GoldDaoManager(this);
}

class GoldDaoManager {
  final _$GoldDaoMixin _db;
  GoldDaoManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$GoldHoldingsTableTableManager get goldHoldings =>
      $$GoldHoldingsTableTableManager(_db.attachedDatabase, _db.goldHoldings);
  $$GoldRatesTableTableManager get goldRates =>
      $$GoldRatesTableTableManager(_db.attachedDatabase, _db.goldRates);
}
