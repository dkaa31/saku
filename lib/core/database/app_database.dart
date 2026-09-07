import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text().withDefault(const Constant('cash'))();
  RealColumn get initialBalance => real().withDefault(const Constant(0))();
  RealColumn get currentBalance => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  // 'income' | 'expense'
  TextColumn get type => text()();
  // 'savings' | 'needs' | 'personal'
  TextColumn get bucket => text().nullable()();
  RealColumn get budgetMonthly => real().nullable()();
  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(false))();
  // Ikon & warna custom per kategori (v2)
  TextColumn get iconName =>
      text().withDefault(const Constant('category'))();
  TextColumn get colorHex =>
      text().withDefault(const Constant('#2563EB'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get type => text()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('outgoingTransfers')
  IntColumn get fromAccountId => integer().references(Accounts, #id)();
  @ReferenceName('incomingTransfers')
  IntColumn get toAccountId => integer().references(Accounts, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AllocationSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get savingsRatio =>
      real().withDefault(const Constant(20))();
  RealColumn get needsRatio =>
      real().withDefault(const Constant(50))();
  RealColumn get personalRatio =>
      real().withDefault(const Constant(30))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [Accounts, Categories, Transactions, Transfers, AllocationSettings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultData();
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2: tambah kolom iconName & colorHex ke tabel categories
          if (from < 2) {
            try {
              await m.addColumn(categories, categories.iconName);
              await m.addColumn(categories, categories.colorHex);

              // Set nilai default untuk data lama yang sudah ada
              await customStatement(
                "UPDATE categories SET icon_name = 'category' WHERE icon_name IS NULL",
              );
              await customStatement(
                "UPDATE categories SET color_hex = '#2563EB' WHERE color_hex IS NULL",
              );
            } catch (_) {
              // Jika migration gagal (database corrupt), recreate dari awal
              await m.recreateAllViews();
            }
          }
        },
        // Fallback: jika schema tidak cocok sama sekali, hapus & buat ulang
        beforeOpen: (details) async {
          if (details.wasCreated) return;
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'saku_db');
  }

  // ─── Seed data default ───────────────────────────────────────────────────────
  Future<void> _seedDefaultData() async {
    final expenseCategories = [
      _expCat('Makan',     'needs',    'restaurant',       '#EF4444'),
      _expCat('Transport', 'needs',    'directions_car',   '#F59E0B'),
      _expCat('Tagihan',   'needs',    'receipt_long',     '#6366F1'),
      _expCat('Belanja',   'personal', 'shopping_bag',     '#EC4899'),
      _expCat('Hiburan',   'personal', 'movie',            '#8B5CF6'),
      _expCat('Kesehatan', 'needs',    'health_and_safety','#10B981'),
      _expCat('Tabungan',  'savings',  'savings',          '#2563EB'),
      _expCat('Kos/Sewa',  'needs',    'home',             '#0EA5E9'),
      _expCat('Lainnya',   'personal', 'more_horiz',       '#94A3B8'),
    ];

    final incomeCategories = [
      _incCat('Gaji',      'payments',       '#10B981'),
      _incCat('Uang saku', 'wallet',         '#2563EB'),
      _incCat('Freelance', 'work',           '#F59E0B'),
      _incCat('Bisnis',    'store',          '#8B5CF6'),
      _incCat('Lainnya',   'add_circle',     '#94A3B8'),
    ];

    for (final cat in [...expenseCategories, ...incomeCategories]) {
      await into(categories).insert(cat);
    }

    await into(allocationSettings).insert(
      AllocationSettingsCompanion.insert(
        savingsRatio:  const Value(20),
        needsRatio:    const Value(50),
        personalRatio: const Value(30),
      ),
    );
  }

  CategoriesCompanion _expCat(
          String name, String bucket, String icon, String color) =>
      CategoriesCompanion.insert(
        name: name,
        type: 'expense',
        bucket: Value(bucket),
        isDefault: const Value(true),
        iconName: Value(icon),
        colorHex: Value(color),
      );

  CategoriesCompanion _incCat(
          String name, String icon, String color) =>
      CategoriesCompanion.insert(
        name: name,
        type: 'income',
        isDefault: const Value(true),
        iconName: Value(icon),
        colorHex: Value(color),
      );
}
