import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../category/data/category_repository.dart';
import '../../transaction/data/transaction_repository.dart';

/// Status per bucket: on track, hemat, atau boros
enum BucketStatus { onTrack, hemat, boros }

/// Hasil analisis satu bucket (Kebutuhan / Tabungan / Pribadi)
class BucketResult {
  final String key;       // 'needs' | 'savings' | 'personal'
  final String label;
  final double ratio;     // persentase (0–100)
  final double recommended; // nominal rekomendasi
  final double actual;      // pengeluaran aktual
  final BucketStatus status;

  const BucketResult({
    required this.key,
    required this.label,
    required this.ratio,
    required this.recommended,
    required this.actual,
    required this.status,
  });

  double get diff => recommended - actual; // positif = sisa, negatif = over
}

/// Hasil lengkap rekomendasi untuk ditampilkan di UI
class AllocationResult {
  final double baseIncome;        // income yang dipakai sebagai dasar
  final bool usedAverage;         // true = pakai rata-rata 3 bulan
  final List<BucketResult> buckets;
  final AllocationSetting setting;

  const AllocationResult({
    required this.baseIncome,
    required this.usedAverage,
    required this.buckets,
    required this.setting,
  });
}

class AllocationService {
  final AppDatabase _db;

  AllocationService(this._db);

  Future<AllocationResult?> calculate() async {
    // 1. Ambil pengaturan rasio
    final settings = await (_db.select(_db.allocationSettings)).get();
    if (settings.isEmpty) return null;
    final setting = settings.first;

    // 2. Income bulan ini
    final now    = DateTime.now();
    final txRepo = TransactionRepository(_db);
    final monthSummary =
        await txRepo.getMonthlySummary(now.year, now.month);

    // Gunakan rata-rata 3 bulan jika income bulan ini = 0
    double baseIncome  = monthSummary.income;
    bool   usedAverage = false;
    if (baseIncome == 0) {
      baseIncome  = await txRepo.getAverageMonthlyIncome(months: 3);
      usedAverage = true;
    }

    if (baseIncome == 0) return null; // belum ada data income sama sekali

    // 3. Spending aktual per bucket bulan ini
    final catRepo = CategoryRepository(_db);
    final spending =
        await catRepo.getSpendingByCategory(year: now.year, month: now.month);
    final allCats = await catRepo.getAll();

    final Map<String, double> actualByBucket = {
      'needs':    0,
      'savings':  0,
      'personal': 0,
    };
    for (final cat in allCats) {
      final bucket = cat.bucket;
      if (bucket == null) continue;
      actualByBucket[bucket] =
          (actualByBucket[bucket] ?? 0) + (spending[cat.id] ?? 0);
    }

    // 4. Hitung rekomendasi
    final buckets = [
      _buildBucket(
        key:         'needs',
        label:       'Kebutuhan pokok',
        ratio:       setting.needsRatio,
        income:      baseIncome,
        actual:      actualByBucket['needs']!,
      ),
      _buildBucket(
        key:         'savings',
        label:       'Tabungan',
        ratio:       setting.savingsRatio,
        income:      baseIncome,
        actual:      actualByBucket['savings']!,
      ),
      _buildBucket(
        key:         'personal',
        label:       'Keperluan pribadi',
        ratio:       setting.personalRatio,
        income:      baseIncome,
        actual:      actualByBucket['personal']!,
      ),
    ];

    return AllocationResult(
      baseIncome:  baseIncome,
      usedAverage: usedAverage,
      buckets:     buckets,
      setting:     setting,
    );
  }

  BucketResult _buildBucket({
    required String key,
    required String label,
    required double ratio,
    required double income,
    required double actual,
  }) {
    final recommended = income * ratio / 100;
    final pct         = recommended > 0 ? actual / recommended : 0.0;

    BucketStatus status;
    if (pct <= 0.9) {
      status = BucketStatus.hemat;
    } else if (pct <= 1.05) {
      status = BucketStatus.onTrack;
    } else {
      status = BucketStatus.boros;
    }

    // Untuk tabungan: logika terbalik — makin besar actual makin bagus
    if (key == 'savings') {
      if (pct >= 1.0) {
        status = BucketStatus.hemat; // lebih hemat = lebih bagus
      } else if (pct >= 0.8) {
        status = BucketStatus.onTrack;
      } else {
        status = BucketStatus.boros; // tabungan kurang = "boros" (tidak menabung cukup)
      }
    }

    return BucketResult(
      key:         key,
      label:       label,
      ratio:       ratio,
      recommended: recommended,
      actual:      actual,
      status:      status,
    );
  }

  // ─── Update rasio ─────────────────────────────────────────────────────────

  Future<void> updateRatios({
    required double savings,
    required double needs,
    required double personal,
  }) async {
    final settings = await (_db.select(_db.allocationSettings)).get();
    if (settings.isEmpty) {
      await _db.into(_db.allocationSettings).insert(
            AllocationSettingsCompanion.insert(
              savingsRatio:  Value(savings),
              needsRatio:    Value(needs),
              personalRatio: Value(personal),
            ),
          );
    } else {
      await (_db.update(_db.allocationSettings)
            ..where((s) => s.id.equals(settings.first.id)))
          .write(AllocationSettingsCompanion(
            savingsRatio:  Value(savings),
            needsRatio:    Value(needs),
            personalRatio: Value(personal),
            updatedAt:     Value(DateTime.now()),
          ));
    }
  }
}
