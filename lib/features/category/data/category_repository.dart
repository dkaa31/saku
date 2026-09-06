import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

class CategoryRepository {
  final AppDatabase _db;
  const CategoryRepository(this._db);

  // ─── Watch ──────────────────────────────────────────────────────────────────

  Stream<List<Category>> watchAll() {
    return (_db.select(_db.categories)
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Stream<List<Category>> watchByType(String type) {
    return (_db.select(_db.categories)
          ..where((c) => c.type.equals(type))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  // ─── Read ────────────────────────────────────────────────────────────────────

  Future<List<Category>> getAll() {
    return (_db.select(_db.categories)
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  Future<List<Category>> getByType(String type) {
    return (_db.select(_db.categories)
          ..where((c) => c.type.equals(type))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  Future<Category?> getById(int id) {
    return (_db.select(_db.categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  // ─── Spending per kategori di bulan tertentu ─────────────────────────────────

  Future<Map<int, double>> getSpendingByCategory({
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final txList = await (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.type.equals('expense') &
                t.date.isBiggerOrEqualValue(startDate) &
                t.date.isSmallerThanValue(endDate),
          ))
        .get();

    final result = <int, double>{};
    for (final tx in txList) {
      result[tx.categoryId] =
          (result[tx.categoryId] ?? 0.0) + tx.amount;
    }
    return result;
  }

  // ─── Write ───────────────────────────────────────────────────────────────────

  Future<int> create({
    required String name,
    required String type,
    String? bucket,
    double? budgetMonthly,
    String iconName  = 'category',
    String colorHex  = '#2563EB',
  }) {
    return _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            name:          name,
            type:          type,
            bucket:        Value(bucket),
            budgetMonthly: Value(budgetMonthly),
            iconName:      Value(iconName),
            colorHex:      Value(colorHex),
          ),
        );
  }

  Future<void> update({
    required int id,
    String? name,
    String? bucket,
    double? budgetMonthly,
    bool clearBudget = false,
    String? iconName,
    String? colorHex,
  }) async {
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        bucket: bucket != null ? Value(bucket) : const Value.absent(),
        budgetMonthly: clearBudget
            ? const Value(null)
            : budgetMonthly != null
                ? Value(budgetMonthly)
                : const Value.absent(),
        iconName: iconName != null ? Value(iconName) : const Value.absent(),
        colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
      ),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }

  Future<bool> canDelete(int id) async {
    final count = await (_db.select(_db.transactions)
          ..where((t) => t.categoryId.equals(id)))
        .get()
        .then((l) => l.length);
    return count == 0;
  }
}
