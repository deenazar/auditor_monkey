import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/accounts_dao.dart';
import '../../../core/database/repository_support.dart';
import '../../../core/database/row_ops.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/utils/validation_failure.dart';
import '../../../core/utils/validators.dart';
import '../domain/account.dart';
import '../domain/account_validator.dart';

const String _tag = 'accounts';
const String _duplicate = 'An account with this name already exists.';

/// Most accounts one `createAll` call may save.
const int maxAccountsPerBatch = 50;

extension AccountRowMapper on AccountRow {
  Account toDomain() => Account(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    syncStatus: SyncStatus.parse(syncStatus),
    name: name,
    type: AccountType.values.byName(type),
    colour: colour,
    openingBalance: openingBalance,
    sortOrder: sortOrder,
    archived: archived,
  );
}

/// All account reads and writes. Every write marks the row `pending`.
class AccountsRepository {
  const AccountsRepository(this._ctx);

  final RepositoryContext _ctx;

  AccountsDao get _dao => _ctx.db.accountsDao;

  Future<Account> create(AccountDraft draft) => _ctx.run(
    _tag,
    'create',
    () async {
      final AccountDraft d = validateAccountDraft(draft);
      final int now = _ctx.clock.nowMs();
      final String id = _ctx.ids.newId();
      await _dao.insertRow(
        AccountsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          name: d.name,
          type: d.type.name,
          colour: d.colour,
          openingBalance: Value<int>(d.openingBalance),
          sortOrder: Value<int>(d.sortOrder),
          archived: Value<bool>(d.archived),
        ),
      );
      return (await _dao.findById(id))!.toDomain();
    },
    idOf: (Account a) => a.id,
    duplicateMessage: _duplicate,
  );

  /// Saves all [drafts] in ONE database transaction: all or nothing.
  ///
  /// Every draft is validated and names must be unique (ignoring case),
  /// also against accounts that already exist. Sort orders are written in
  /// list order, after any existing accounts (0..n on a fresh database).
  /// [fixedIds] (same length as [drafts], `null` = random id) gives the
  /// preset accounts their hard-coded ids.
  Future<List<Account>> createAll(
    List<AccountDraft> drafts, {
    List<String?>? fixedIds,
  }) => _ctx.run(_tag, 'createAll', () async {
    ensure(
      drafts.isNotEmpty && drafts.length <= maxAccountsPerBatch,
      'accounts',
      FailureCode.outOfRange,
      'Add between 1 and $maxAccountsPerBatch accounts.',
    );
    if (fixedIds != null) {
      ensure(
        fixedIds.length == drafts.length,
        'accounts',
        FailureCode.rule,
        'Every account needs its own id.',
      );
    }
    final List<AccountDraft> cleaned = drafts
        .map(validateAccountDraft)
        .toList(growable: false);
    final Set<String> names = <String>{};
    for (final AccountDraft d in cleaned) {
      if (!names.add(d.name.toLowerCase())) {
        throw const DuplicateFailure(_duplicate);
      }
    }
    final Set<String> ids = <String>{};
    final List<String> finalIds = <String>[
      for (int i = 0; i < cleaned.length; i++) _fixedOrNewId(fixedIds?[i], ids),
    ];
    final int now = _ctx.clock.nowMs();
    final List<Account> saved = await _ctx.db.transaction(() async {
      final int first = await _dao.maxSortOrder() + 1;
      for (int i = 0; i < cleaned.length; i++) {
        final AccountDraft d = cleaned[i];
        await _dao.insertRow(
          AccountsCompanion.insert(
            id: finalIds[i],
            createdAt: now,
            updatedAt: now,
            name: d.name,
            type: d.type.name,
            colour: d.colour,
            openingBalance: Value<int>(d.openingBalance),
            sortOrder: Value<int>(first + i),
            archived: Value<bool>(d.archived),
          ),
        );
      }
      final List<Account> rows = <Account>[];
      for (final String id in finalIds) {
        rows.add((await _dao.findById(id))!.toDomain());
      }
      return rows;
    });
    _ctx.logger.info(_tag, 'createAll saved ${saved.length} accounts');
    return saved;
  }, duplicateMessage: _duplicate);

  String _fixedOrNewId(String? fixed, Set<String> used) {
    final String id = fixed ?? _ctx.ids.newId();
    ensure(
      isUuidShape(id) && used.add(id),
      'id',
      FailureCode.invalidFormat,
      'This account id is not allowed.',
    );
    return id;
  }

  /// Adds one account after setup: goes last in the list. Same checks as
  /// the wizard.
  Future<Account> addAccount(AccountDetails details) => _ctx.run(
    _tag,
    'addAccount',
    () async {
      final AccountDraft d = validateAccountDraft(details.toDraft());
      final String id = _ctx.ids.newId();
      final int now = _ctx.clock.nowMs();
      return _ctx.db.transaction(() async {
        final int next = await _dao.maxSortOrder() + 1;
        await _dao.insertRow(
          AccountsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            name: d.name,
            type: d.type.name,
            colour: d.colour,
            openingBalance: Value<int>(d.openingBalance),
            sortOrder: Value<int>(next),
          ),
        );
        return (await _dao.findById(id))!.toDomain();
      });
    },
    idOf: (Account a) => a.id,
    duplicateMessage: _duplicate,
  );

  /// Edits name, type, colour and opening balance. Sort order and archive
  /// state stay as they are. Balances and statements follow at once
  /// because they are calculated, never stored. Same checks as the wizard
  /// (also: a negative opening balance needs the card type).
  Future<Account> editAccount(String id, AccountDetails details) => _ctx.run(
    _tag,
    'editAccount',
    () async {
      final AccountDraft d = validateAccountDraft(details.toDraft());
      return _ctx.db.transaction(() async {
        final AccountRow? existing = await _dao.findById(id);
        if (existing == null) throw const NotFoundFailure();
        await _dao.updateRow(
          id,
          AccountsCompanion(
            name: Value<String>(d.name),
            type: Value<String>(d.type.name),
            colour: Value<String>(d.colour),
            openingBalance: Value<int>(d.openingBalance),
            updatedAt: Value<int>(
              updatedAtFor(existing.createdAt, _ctx.clock.nowMs()),
            ),
            syncStatus: const Value<String>('pending'),
          ),
        );
        return (await _dao.findById(id))!.toDomain();
      });
    },
    idOf: (_) => id,
    duplicateMessage: _duplicate,
  );

  Future<Account> update(String id, AccountDraft draft) => _ctx.run(
    _tag,
    'update',
    () async {
      final AccountDraft d = validateAccountDraft(draft);
      return _ctx.db.transaction(() async {
        final AccountRow? existing = await _dao.findById(id);
        if (existing == null) throw const NotFoundFailure();
        await _dao.updateRow(
          id,
          AccountsCompanion(
            name: Value<String>(d.name),
            type: Value<String>(d.type.name),
            colour: Value<String>(d.colour),
            openingBalance: Value<int>(d.openingBalance),
            sortOrder: Value<int>(d.sortOrder),
            archived: Value<bool>(d.archived),
            updatedAt: Value<int>(
              updatedAtFor(existing.createdAt, _ctx.clock.nowMs()),
            ),
            syncStatus: const Value<String>('pending'),
          ),
        );
        return (await _dao.findById(id))!.toDomain();
      });
    },
    idOf: (_) => id,
    duplicateMessage: _duplicate,
  );

  /// Soft delete. Refused while live transactions or gold holdings use it.
  Future<void> softDelete(String id) => _ctx.run(_tag, 'softDelete', () async {
    await _ctx.db.transaction(() async {
      if (await _dao.findById(id) == null) throw const NotFoundFailure();
      if (await _dao.isInUse(id)) {
        throw const InUseFailure(
          'This account is still used by entries. Delete or move them first.',
        );
      }
      await _dao.softDelete(id, _ctx.clock.nowMs());
    });
  }, idOf: (_) => id);

  Future<Account> restore(String id) => _ctx.run(
    _tag,
    'restore',
    () async {
      await _ctx.db.transaction(() async {
        final AccountRow? existing = await _dao.findById(
          id,
          includeDeleted: true,
        );
        if (existing == null) throw const NotFoundFailure();
        await _dao.restore(id, _ctx.clock.nowMs());
      });
      return (await _dao.findById(id))!.toDomain();
    },
    idOf: (_) => id,
    duplicateMessage: _duplicate,
  );

  Future<Account?> getById(String id, {bool includeDeleted = false}) =>
      _ctx.run(_tag, 'getById', () async {
        final AccountRow? row = await _dao.findById(
          id,
          includeDeleted: includeDeleted,
        );
        return row?.toDomain();
      });

  /// Live accounts in display order, kept up to date.
  Stream<List<Account>> watchAll() => _ctx.guardStream(
    _tag,
    'watchAll',
    _dao.watchLive().map(
      (List<AccountRow> rows) =>
          rows.map((AccountRow r) => r.toDomain()).toList(growable: false),
    ),
  );

  /// Live accounts with calculated balances, kept up to date.
  Stream<List<AccountBalance>> watchBalances() => _ctx.guardStream(
    _tag,
    'watchBalances',
    _dao.watchBalances().map(
      (List<BalanceRow> rows) => rows
          .map(
            (BalanceRow r) =>
                AccountBalance(account: r.row.toDomain(), balance: r.balance),
          )
          .toList(growable: false),
    ),
  );

  Future<List<AccountBalance>> getBalances() =>
      _ctx.run(_tag, 'getBalances', () async {
        final List<BalanceRow> rows = await _dao.getBalances();
        return rows
            .map(
              (BalanceRow r) =>
                  AccountBalance(account: r.row.toDomain(), balance: r.balance),
            )
            .toList(growable: false);
      });

  /// One live account with its calculated balance, or `null`.
  Future<AccountBalance?> getBalance(String id) =>
      _ctx.run(_tag, 'getBalance', () async {
        final BalanceRow? r = await _dao.getBalance(id);
        return r == null
            ? null
            : AccountBalance(account: r.row.toDomain(), balance: r.balance);
      });

  /// True when at least one live account exists (archived ones count),
  /// kept up to date. This is the "setup is done" rule.
  Stream<bool> watchHasAccounts() =>
      _ctx.guardStream(_tag, 'watchHasAccounts', _dao.watchHasLive());

  /// Sum of all live account balances, kept up to date.
  Stream<int> watchNetWorth() =>
      _ctx.guardStream(_tag, 'watchNetWorth', _dao.watchNetWorth());
}
