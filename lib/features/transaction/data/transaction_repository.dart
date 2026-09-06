import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../account/data/account_repository.dart';

class TransactionRepository {
  final AppDatabase _db;
  final AccountRepository _accountRepo;

  TransactionRepository(this._db)
      : _accountRepo = AccountRepository(_db);

  // ─── Watch ──────────────────────────────────────────────────────────────────

  /// Stream semua transaksi, terbaru di atas
  Stream<List<Transaction>> watchAll() {
    return (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date),
                     (t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Stream transaksi bulan tertentu
  Stream<List<Transaction>> watchByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end   = DateTime(year, month + 1, 1);
    return (_db.select(_db.transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date),
                     (t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  // ─── Read ────────────────────────────────────────────────────────────────────

  Future<List<Transaction>> getByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end   = DateTime(year, month + 1, 1);
    return (_db.select(_db.transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date),
                     (t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<Transaction>> getByDateRange(
      DateTime start, DateTime end) {
    return (_db.select(_db.transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<Transaction?> getById(int id) {
    return (_db.select(_db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Ringkasan bulan: total income, expense, net
  Future<MonthlySummary> getMonthlySummary(int year, int month) async {
    final txList = await getByMonth(year, month);
    double income  = 0;
    double expense = 0;
    for (final tx in txList) {
      if (tx.type == 'income') {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    return MonthlySummary(income: income, expense: expense);
  }

  /// Rata-rata income 3 bulan terakhir (untuk rekomendasi alokasi)
  Future<double> getAverageMonthlyIncome({int months = 3}) async {
    final now   = DateTime.now();
    double total = 0;
    int    count = 0;
    for (int i = 0; i < months; i++) {
      int m = now.month - i;
      int y = now.year;
      while (m <= 0) { m += 12; y--; }
      final summary = await getMonthlySummary(y, m);
      if (summary.income > 0) {
        total += summary.income;
        count++;
      }
    }
    if (count == 0) return 0;
    return total / count;
  }

  // ─── Write ───────────────────────────────────────────────────────────────────

  Future<int> create({
    required double amount,
    required String type,
    required int categoryId,
    required int accountId,
    required DateTime date,
    String? note,
  }) async {
    int id = 0;
    await _db.transaction(() async {
      id = await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              amount:     amount,
              type:       type,
              categoryId: categoryId,
              accountId:  accountId,
              date:       date,
              note:       Value(note),
            ),
          );
      // Update saldo akun
      final delta = type == 'income' ? amount : -amount;
      await _accountRepo.adjustBalance(accountId, delta);
    });
    return id;
  }

  Future<void> update({
    required int id,
    required double amount,
    required String type,
    required int categoryId,
    required int accountId,
    required DateTime date,
    String? note,
  }) async {
    final old = await getById(id);
    if (old == null) return;

    await _db.transaction(() async {
      // Rollback saldo lama
      final oldDelta = old.type == 'income' ? -old.amount : old.amount;
      await _accountRepo.adjustBalance(old.accountId, oldDelta);

      // Jika akun berubah, rollback dari akun lama sudah di atas
      // Apply saldo baru
      final newDelta = type == 'income' ? amount : -amount;
      await _accountRepo.adjustBalance(accountId, newDelta);

      await (_db.update(_db.transactions)
            ..where((t) => t.id.equals(id)))
          .write(TransactionsCompanion(
            amount:     Value(amount),
            type:       Value(type),
            categoryId: Value(categoryId),
            accountId:  Value(accountId),
            date:       Value(date),
            note:       Value(note),
          ));
    });
  }

  Future<void> delete(int id) async {
    final tx = await getById(id);
    if (tx == null) return;

    await _db.transaction(() async {
      // Rollback saldo
      final delta = tx.type == 'income' ? -tx.amount : tx.amount;
      await _accountRepo.adjustBalance(tx.accountId, delta);

      await (_db.delete(_db.transactions)
            ..where((t) => t.id.equals(id)))
          .go();
    });
  }
}

class MonthlySummary {
  final double income;
  final double expense;
  double get net => income - expense;

  const MonthlySummary({required this.income, required this.expense});
}
