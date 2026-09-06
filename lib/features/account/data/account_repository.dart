import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

class AccountRepository {
  final AppDatabase _db;
  const AccountRepository(this._db);

  // ─── Watch (stream reaktif) ─────────────────────────────────────────────────

  Stream<List<Account>> watchAllAccounts() {
    return (_db.select(_db.accounts)
          ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
        .watch();
  }

  // ─── Read ───────────────────────────────────────────────────────────────────

  Future<List<Account>> getAllAccounts() {
    return (_db.select(_db.accounts)
          ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
        .get();
  }

  Future<Account?> getAccountById(int id) {
    return (_db.select(_db.accounts)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  Future<double> getTotalBalance() async {
    final accounts = await getAllAccounts();
    return accounts.fold<double>(0.0, (sum, a) => sum + a.currentBalance);
  }

  // ─── Write ──────────────────────────────────────────────────────────────────

  Future<int> createAccount({
    required String name,
    required String type,
    required double initialBalance,
  }) async {
    final id = await _db.into(_db.accounts).insert(
          AccountsCompanion.insert(
            name: name,
            type: Value(type),
            initialBalance: Value(initialBalance),
            currentBalance: Value(initialBalance),
          ),
        );
    return id;
  }

  Future<void> updateAccount({
    required int id,
    String? name,
    String? type,
    double? currentBalance,
  }) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        currentBalance: currentBalance != null
            ? Value(currentBalance)
            : const Value.absent(),
      ),
    );
  }

  Future<void> adjustBalance(int accountId, double delta) async {
    final account = await getAccountById(accountId);
    if (account == null) return;
    await updateAccount(
      id: accountId,
      currentBalance: account.currentBalance + delta,
    );
  }

  Future<void> deleteAccount(int id) async {
    await (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();
  }

  // ─── Cek apakah akun bisa dihapus (tidak ada transaksi terkait) ─────────────
  Future<bool> canDelete(int id) async {
    final txCount = await (_db.select(_db.transactions)
          ..where((t) => t.accountId.equals(id)))
        .get()
        .then((list) => list.length);
    return txCount == 0;
  }
}
