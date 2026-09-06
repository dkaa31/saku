import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import 'account_repository.dart';

class TransferRepository {
  final AppDatabase _db;
  final AccountRepository _accountRepo;

  TransferRepository(this._db) : _accountRepo = AccountRepository(_db);

  // ─── Buat transfer antar akun ─────────────────────────────────────────────
  Future<void> createTransfer({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    await _db.transaction(() async {
      // Catat transfer
      await _db.into(_db.transfers).insert(
            TransfersCompanion.insert(
              fromAccountId: fromAccountId,
              toAccountId: toAccountId,
              amount: amount,
              date: date,
              note: Value(note),
            ),
          );

      // Kurangi saldo akun asal
      await _accountRepo.adjustBalance(fromAccountId, -amount);

      // Tambah saldo akun tujuan
      await _accountRepo.adjustBalance(toAccountId, amount);
    });
  }

  // ─── Hapus transfer (rollback saldo) ──────────────────────────────────────
  Future<void> deleteTransfer(int transferId) async {
    final transfer = await (_db.select(_db.transfers)
          ..where((t) => t.id.equals(transferId)))
        .getSingleOrNull();
    if (transfer == null) return;

    await _db.transaction(() async {
      await _accountRepo.adjustBalance(
          transfer.fromAccountId, transfer.amount);
      await _accountRepo.adjustBalance(
          transfer.toAccountId, -transfer.amount);
      await (_db.delete(_db.transfers)
            ..where((t) => t.id.equals(transferId)))
          .go();
    });
  }

  // ─── Watch transfer ───────────────────────────────────────────────────────
  Stream<List<Transfer>> watchAllTransfers() {
    return (_db.select(_db.transfers)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }
}
