import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/loans_dao.dart';
import '../../../core/database/repository_support.dart';
import '../../../core/database/row_ops.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/utils/validation_failure.dart';
import '../domain/loan.dart';
import '../domain/loan_validator.dart';

const String _tag = 'loans';

extension LoanRowMapper on LoanRow {
  Loan toDomain() => Loan(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    syncStatus: SyncStatus.parse(syncStatus),
    direction: LoanDirection.values.byName(direction),
    person: person,
    principal: principal,
    startDate: startDate,
    dueDate: dueDate,
    note: note,
    closed: closed,
  );
}

class LoansRepository {
  const LoansRepository(this._ctx);

  final RepositoryContext _ctx;

  LoansDao get _dao => _ctx.db.loansDao;

  Future<Loan> create(LoanDraft draft) => _ctx.run(_tag, 'create', () async {
    final LoanDraft d = validateLoanDraft(draft);
    final int now = _ctx.clock.nowMs();
    final String id = _ctx.ids.newId();
    await _dao.insertRow(
      LoansCompanion.insert(
        id: id,
        createdAt: now,
        updatedAt: now,
        direction: d.direction.name,
        person: d.person,
        principal: d.principal,
        startDate: d.startDate,
        dueDate: Value<String?>(d.dueDate),
        note: Value<String?>(d.note),
        closed: Value<bool>(d.closed),
      ),
    );
    return (await _dao.findById(id))!.toDomain();
  }, idOf: (Loan l) => l.id);

  Future<Loan> update(String id, LoanDraft draft) =>
      _ctx.run(_tag, 'update', () async {
        final LoanDraft d = validateLoanDraft(draft);
        return _ctx.db.transaction(() async {
          final LoanRow? existing = await _dao.findById(id);
          if (existing == null) throw const NotFoundFailure();
          await _dao.updateRow(
            id,
            LoansCompanion(
              direction: Value<String>(d.direction.name),
              person: Value<String>(d.person),
              principal: Value<int>(d.principal),
              startDate: Value<String>(d.startDate),
              dueDate: Value<String?>(d.dueDate),
              note: Value<String?>(d.note),
              closed: Value<bool>(d.closed),
              updatedAt: Value<int>(
                updatedAtFor(existing.createdAt, _ctx.clock.nowMs()),
              ),
              syncStatus: const Value<String>('pending'),
            ),
          );
          return (await _dao.findById(id))!.toDomain();
        });
      }, idOf: (_) => id);

  /// Soft delete. Refused while live transactions are linked to the loan;
  /// close the loan instead.
  Future<void> softDelete(String id) => _ctx.run(_tag, 'softDelete', () async {
    await _ctx.db.transaction(() async {
      if (await _dao.findById(id) == null) throw const NotFoundFailure();
      if (await _dao.hasLiveTransactions(id)) {
        throw const InUseFailure(
          'This loan has entries. Close it instead of deleting it.',
        );
      }
      await _dao.softDelete(id, _ctx.clock.nowMs());
    });
  }, idOf: (_) => id);

  Future<Loan> restore(String id) => _ctx.run(_tag, 'restore', () async {
    if (await _dao.findById(id, includeDeleted: true) == null) {
      throw const NotFoundFailure();
    }
    await _dao.restore(id, _ctx.clock.nowMs());
    return (await _dao.findById(id))!.toDomain();
  }, idOf: (_) => id);

  Future<Loan?> getById(String id, {bool includeDeleted = false}) =>
      _ctx.run(_tag, 'getById', () async {
        final LoanRow? row = await _dao.findById(
          id,
          includeDeleted: includeDeleted,
        );
        return row?.toDomain();
      });

  /// Live loans with what is still owed, kept up to date. Open loans first.
  Stream<List<LoanSummary>> watchSummaries() => _ctx.guardStream(
    _tag,
    'watchSummaries',
    _dao.outstanding().watch().map(_toSummaries),
  );

  Future<List<LoanSummary>> getSummaries() => _ctx.run(
    _tag,
    'getSummaries',
    () async => _toSummaries(await _dao.outstanding().get()),
  );

  List<LoanSummary> _toSummaries(List<LoanOutstandingRow> rows) => rows
      .map(
        (LoanOutstandingRow r) =>
            LoanSummary(loan: r.row.toDomain(), outstanding: r.outstanding),
      )
      .toList(growable: false);
}
