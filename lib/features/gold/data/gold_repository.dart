import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/gold_dao.dart';
import '../../../core/database/repository_support.dart';
import '../../../core/database/row_ops.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/utils/validation_failure.dart';
import '../domain/gold.dart';
import '../domain/gold_validator.dart';

const String _tag = 'gold';
const String _duplicateRate = 'A rate for this date and purity already exists.';

extension GoldHoldingRowMapper on GoldHoldingRow {
  GoldHolding toDomain() => GoldHolding(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    syncStatus: SyncStatus.parse(syncStatus),
    description: description,
    weightMg: weightMg,
    purity: GoldPurity.parse(purity),
    purchaseDate: purchaseDate,
    purchasePrice: purchasePrice,
    accountId: accountId,
  );
}

extension GoldRateRowMapper on GoldRateRow {
  GoldRate toDomain() => GoldRate(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    syncStatus: SyncStatus.parse(syncStatus),
    date: date,
    purity: GoldPurity.parse(purity),
    ratePerGram: ratePerGram,
  );
}

/// Gold holdings and daily gold rates.
class GoldRepository {
  const GoldRepository(this._ctx);

  final RepositoryContext _ctx;

  GoldDao get _dao => _ctx.db.goldDao;

  // Holdings.

  Future<GoldHolding> createHolding(GoldHoldingDraft draft) =>
      _ctx.run(_tag, 'createHolding', () async {
        final GoldHoldingDraft d = validateGoldHoldingDraft(draft);
        final int now = _ctx.clock.nowMs();
        final String id = _ctx.ids.newId();
        await _ctx.db.transaction(() async {
          await _requireAccount(d.accountId);
          await _dao.insertHolding(
            GoldHoldingsCompanion.insert(
              id: id,
              createdAt: now,
              updatedAt: now,
              description: d.description,
              weightMg: d.weightMg,
              purity: d.purity.dbValue,
              purchaseDate: d.purchaseDate,
              purchasePrice: d.purchasePrice,
              accountId: Value<String?>(d.accountId),
            ),
          );
        });
        return (await _dao.findHolding(id))!.toDomain();
      }, idOf: (GoldHolding h) => h.id);

  Future<GoldHolding> updateHolding(String id, GoldHoldingDraft draft) =>
      _ctx.run(_tag, 'updateHolding', () async {
        final GoldHoldingDraft d = validateGoldHoldingDraft(draft);
        await _ctx.db.transaction(() async {
          final GoldHoldingRow? existing = await _dao.findHolding(id);
          if (existing == null) throw const NotFoundFailure();
          await _requireAccount(d.accountId);
          await _dao.updateHolding(
            id,
            GoldHoldingsCompanion(
              description: Value<String>(d.description),
              weightMg: Value<int>(d.weightMg),
              purity: Value<String>(d.purity.dbValue),
              purchaseDate: Value<String>(d.purchaseDate),
              purchasePrice: Value<int>(d.purchasePrice),
              accountId: Value<String?>(d.accountId),
              updatedAt: Value<int>(
                updatedAtFor(existing.createdAt, _ctx.clock.nowMs()),
              ),
              syncStatus: const Value<String>('pending'),
            ),
          );
        });
        return (await _dao.findHolding(id))!.toDomain();
      }, idOf: (_) => id);

  Future<void> softDeleteHolding(String id) =>
      _ctx.run(_tag, 'softDeleteHolding', () async {
        if (await _dao.findHolding(id) == null) throw const NotFoundFailure();
        await _dao.softDeleteHolding(id, _ctx.clock.nowMs());
      }, idOf: (_) => id);

  Future<GoldHolding> restoreHolding(String id) =>
      _ctx.run(_tag, 'restoreHolding', () async {
        await _ctx.db.transaction(() async {
          final GoldHoldingRow? existing = await _dao.findHolding(
            id,
            includeDeleted: true,
          );
          if (existing == null) throw const NotFoundFailure();
          await _requireAccount(existing.accountId);
          await _dao.restoreHolding(id, _ctx.clock.nowMs());
        });
        return (await _dao.findHolding(id))!.toDomain();
      }, idOf: (_) => id);

  Future<GoldHolding?> getHolding(String id, {bool includeDeleted = false}) =>
      _ctx.run(_tag, 'getHolding', () async {
        final GoldHoldingRow? row = await _dao.findHolding(
          id,
          includeDeleted: includeDeleted,
        );
        return row?.toDomain();
      });

  /// Live holdings with current value (latest live rate of the same purity).
  Stream<List<GoldHoldingValue>> watchHoldingValues() => _ctx.guardStream(
    _tag,
    'watchHoldingValues',
    _dao.holdingValues().watch().map(_toValues),
  );

  Future<List<GoldHoldingValue>> getHoldingValues() => _ctx.run(
    _tag,
    'getHoldingValues',
    () async => _toValues(await _dao.holdingValues().get()),
  );

  List<GoldHoldingValue> _toValues(List<GoldValueRow> rows) => rows
      .map(
        (GoldValueRow r) => GoldHoldingValue(
          holding: r.row.toDomain(),
          currentValue: r.currentValue,
        ),
      )
      .toList(growable: false);

  // Rates.

  Future<GoldRate> createRate(GoldRateDraft draft) => _ctx.run(
    _tag,
    'createRate',
    () async {
      final GoldRateDraft d = validateGoldRateDraft(draft);
      final int now = _ctx.clock.nowMs();
      final String id = _ctx.ids.newId();
      await _dao.insertRate(
        GoldRatesCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          date: d.date,
          purity: d.purity.dbValue,
          ratePerGram: d.ratePerGram,
        ),
      );
      return (await _dao.findRate(id))!.toDomain();
    },
    idOf: (GoldRate r) => r.id,
    duplicateMessage: _duplicateRate,
  );

  Future<GoldRate> updateRate(String id, GoldRateDraft draft) => _ctx.run(
    _tag,
    'updateRate',
    () async {
      final GoldRateDraft d = validateGoldRateDraft(draft);
      return _ctx.db.transaction(() async {
        final GoldRateRow? existing = await _dao.findRate(id);
        if (existing == null) throw const NotFoundFailure();
        await _dao.updateRate(
          id,
          GoldRatesCompanion(
            date: Value<String>(d.date),
            purity: Value<String>(d.purity.dbValue),
            ratePerGram: Value<int>(d.ratePerGram),
            updatedAt: Value<int>(
              updatedAtFor(existing.createdAt, _ctx.clock.nowMs()),
            ),
            syncStatus: const Value<String>('pending'),
          ),
        );
        return (await _dao.findRate(id))!.toDomain();
      });
    },
    idOf: (_) => id,
    duplicateMessage: _duplicateRate,
  );

  Future<void> softDeleteRate(String id) =>
      _ctx.run(_tag, 'softDeleteRate', () async {
        if (await _dao.findRate(id) == null) throw const NotFoundFailure();
        await _dao.softDeleteRate(id, _ctx.clock.nowMs());
      }, idOf: (_) => id);

  Future<GoldRate> restoreRate(String id) => _ctx.run(
    _tag,
    'restoreRate',
    () async {
      if (await _dao.findRate(id, includeDeleted: true) == null) {
        throw const NotFoundFailure();
      }
      await _dao.restoreRate(id, _ctx.clock.nowMs());
      return (await _dao.findRate(id))!.toDomain();
    },
    idOf: (_) => id,
    duplicateMessage: _duplicateRate,
  );

  Future<GoldRate?> getRate(String id, {bool includeDeleted = false}) =>
      _ctx.run(_tag, 'getRate', () async {
        final GoldRateRow? row = await _dao.findRate(
          id,
          includeDeleted: includeDeleted,
        );
        return row?.toDomain();
      });

  Stream<List<GoldRate>> watchRates() => _ctx.guardStream(
    _tag,
    'watchRates',
    _dao.watchRates().map(
      (List<GoldRateRow> rows) =>
          rows.map((GoldRateRow r) => r.toDomain()).toList(growable: false),
    ),
  );

  /// Gold holdings may point to a live account (information only).
  Future<void> _requireAccount(String? accountId) async {
    if (accountId == null) return;
    if (await _ctx.db.accountsDao.findById(accountId) == null) {
      throw const ValidationFailure(
        'accountId',
        FailureCode.referenceMissing,
        'That account is not available.',
      );
    }
  }
}
