import '../../../core/database/app_database.dart';
import '../../transaction/data/transaction_repository.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class MonthlyBarData {
  final DateTime month;
  final double income;
  final double expense;
  const MonthlyBarData(
      {required this.month, required this.income, required this.expense});
}

class CategorySlice {
  final int categoryId;
  final String categoryName;
  final String iconName;
  final String colorHex;
  final double amount;
  final double ratio;
  const CategorySlice({
    required this.categoryId,
    required this.categoryName,
    required this.iconName,
    required this.colorHex,
    required this.amount,
    required this.ratio,
  });
}

/// Satu kategori di ranking pengeluaran terbesar
class TopCategory {
  final int categoryId;
  final String name;
  final String iconName;
  final String colorHex;
  final double amount;
  final double ratio; // porsi dari total pengeluaran
  final double? prevAmount; // bulan lalu, bisa null
  const TopCategory({
    required this.categoryId,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.amount,
    required this.ratio,
    this.prevAmount,
  });

  double get changePercent {
    if (prevAmount == null || prevAmount == 0) return 0;
    return ((amount - prevAmount!) / prevAmount!) * 100;
  }
}

/// Perbandingan bulan ini vs bulan lalu
class MonthComparison {
  final double thisIncome;
  final double prevIncome;
  final double thisExpense;
  final double prevExpense;
  const MonthComparison({
    required this.thisIncome,
    required this.prevIncome,
    required this.thisExpense,
    required this.prevExpense,
  });

  double get incomeChange =>
      prevIncome == 0 ? 0 : ((thisIncome - prevIncome) / prevIncome) * 100;
  double get expenseChange =>
      prevExpense == 0 ? 0 : ((thisExpense - prevExpense) / prevExpense) * 100;
  double get thisSavingRate =>
      thisIncome == 0 ? 0 : ((thisIncome - thisExpense) / thisIncome) * 100;
  double get prevSavingRate =>
      prevIncome == 0 ? 0 : ((prevIncome - prevExpense) / prevIncome) * 100;
}

/// Satu insight teks otomatis
class FinancialInsight {
  final InsightType type;
  final String title;
  final String message;
  const FinancialInsight(
      {required this.type, required this.title, required this.message});
}

enum InsightType { good, warning, info }

// ─── Repository ───────────────────────────────────────────────────────────────

class ReportRepository {
  final AppDatabase _db;
  final TransactionRepository _txRepo;

  ReportRepository(this._db) : _txRepo = TransactionRepository(_db);

  // ── Pie chart: spending per kategori ────────────────────────────────────────
  Future<List<CategorySlice>> getCategorySlices({
    required int year,
    required int month,
  }) async {
    final txList = await _txRepo.getByMonth(year, month);
    final expenseTxs = txList.where((t) => t.type == 'expense').toList();

    final Map<int, double> totals = {};
    for (final tx in expenseTxs) {
      totals[tx.categoryId] = (totals[tx.categoryId] ?? 0) + tx.amount;
    }
    if (totals.isEmpty) return [];

    final cats = await (_db.select(_db.categories)
          ..where((c) => c.id.isIn(totals.keys.toList())))
        .get();
    final catMap = {for (final c in cats) c.id: c};

    final grandTotal = totals.values.fold<double>(0, (a, b) => a + b);

    final slices = totals.entries.map((e) {
      final cat = catMap[e.key];
      return CategorySlice(
        categoryId:   e.key,
        categoryName: cat?.name ?? 'Lainnya',
        iconName:     cat?.iconName ?? 'category',
        colorHex:     cat?.colorHex ?? '#2563EB',
        amount:       e.value,
        ratio:        grandTotal > 0 ? e.value / grandTotal : 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return slices;
  }

  // ── Bar chart: tren N bulan ──────────────────────────────────────────────────
  Future<List<MonthlyBarData>> getMonthlyTrend({int months = 6}) async {
    final now    = DateTime.now();
    final result = <MonthlyBarData>[];
    for (int i = months - 1; i >= 0; i--) {
      int m = now.month - i;
      int y = now.year;
      while (m <= 0) { m += 12; y--; }
      final summary = await _txRepo.getMonthlySummary(y, m);
      result.add(MonthlyBarData(
          month: DateTime(y, m), income: summary.income, expense: summary.expense));
    }
    return result;
  }

  // ── Summary dengan filter akun ───────────────────────────────────────────────
  Future<MonthlySummary> getSummaryFiltered({
    required DateTime start,
    required DateTime end,
    int? accountId,
  }) async {
    final allTx = await _txRepo.getByDateRange(start, end);
    final txList = accountId != null
        ? allTx.where((t) => t.accountId == accountId).toList()
        : allTx;
    double income = 0, expense = 0;
    for (final tx in txList) {
      if (tx.type == 'income') {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    return MonthlySummary(income: income, expense: expense);
  }

  // ── Top N kategori pengeluaran terbesar ──────────────────────────────────────
  Future<List<TopCategory>> getTopExpenseCategories({
    required int year,
    required int month,
    int limit = 5,
  }) async {
    final thisTx = await _txRepo.getByMonth(year, month);
    final thisExp = thisTx.where((t) => t.type == 'expense').toList();

    // Bulan lalu
    int prevMonth = month - 1, prevYear = year;
    if (prevMonth <= 0) { prevMonth = 12; prevYear--; }
    final prevTx  = await _txRepo.getByMonth(prevYear, prevMonth);
    final prevExp = prevTx.where((t) => t.type == 'expense').toList();

    final Map<int, double> totals = {};
    for (final tx in thisExp) {
      totals[tx.categoryId] = (totals[tx.categoryId] ?? 0) + tx.amount;
    }

    final Map<int, double> prevTotals = {};
    for (final tx in prevExp) {
      prevTotals[tx.categoryId] = (prevTotals[tx.categoryId] ?? 0) + tx.amount;
    }

    if (totals.isEmpty) return [];

    final cats = await (_db.select(_db.categories)
          ..where((c) => c.id.isIn(totals.keys.toList())))
        .get();
    final catMap = {for (final c in cats) c.id: c};

    final grandTotal = totals.values.fold<double>(0, (a, b) => a + b);

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) {
      final cat = catMap[e.key];
      return TopCategory(
        categoryId: e.key,
        name:       cat?.name ?? 'Lainnya',
        iconName:   cat?.iconName ?? 'category',
        colorHex:   cat?.colorHex ?? '#2563EB',
        amount:     e.value,
        ratio:      grandTotal > 0 ? e.value / grandTotal : 0,
        prevAmount: prevTotals[e.key],
      );
    }).toList();
  }

  // ── Perbandingan bulan ini vs bulan lalu ─────────────────────────────────────
  Future<MonthComparison> getMonthComparison({
    required int year,
    required int month,
  }) async {
    int prevMonth = month - 1, prevYear = year;
    if (prevMonth <= 0) { prevMonth = 12; prevYear--; }

    final thisSummary = await _txRepo.getMonthlySummary(year, month);
    final prevSummary = await _txRepo.getMonthlySummary(prevYear, prevMonth);

    return MonthComparison(
      thisIncome:   thisSummary.income,
      prevIncome:   prevSummary.income,
      thisExpense:  thisSummary.expense,
      prevExpense:  prevSummary.expense,
    );
  }

  // ── Insight otomatis ─────────────────────────────────────────────────────────
  Future<List<FinancialInsight>> getInsights({
    required int year,
    required int month,
  }) async {
    final insights = <FinancialInsight>[];

    final comparison = await getMonthComparison(year: year, month: month);
    final topCats    = await getTopExpenseCategories(year: year, month: month);
    final savingRate = comparison.thisSavingRate;

    // 1. Saving rate
    if (comparison.thisIncome > 0) {
      if (savingRate >= 20) {
        insights.add(const FinancialInsight(
          type:    InsightType.good,
          title:   'Saving rate bagus 👍',
          message:
              'Kamu berhasil menyisihkan lebih dari 20% dari pemasukanmu bulan ini. Pertahankan!',
        ));
      } else if (savingRate >= 0) {
        insights.add(FinancialInsight(
          type:    InsightType.warning,
          title:   'Saving rate rendah',
          message:
              'Kamu menyisihkan ${savingRate.toStringAsFixed(0)}% dari pemasukan. '
              'Coba targetkan minimal 20% untuk tabungan darurat.',
        ));
      } else {
        insights.add(const FinancialInsight(
          type:    InsightType.warning,
          title:   'Pengeluaran melebihi pemasukan ⚠️',
          message:
              'Bulan ini kamu menghabiskan lebih dari yang kamu terima. '
              'Cek kategori pengeluaran terbesarmu dan pertimbangkan untuk mengurangi.',
        ));
      }
    }

    // 2. Pengeluaran naik signifikan dibanding bulan lalu
    if (comparison.expenseChange > 20 && comparison.prevExpense > 0) {
      insights.add(FinancialInsight(
        type:    InsightType.warning,
        title:   'Pengeluaran naik ${comparison.expenseChange.toStringAsFixed(0)}%',
        message:
            'Dibanding bulan lalu, pengeluaranmu naik cukup signifikan. '
            'Kategori ${topCats.isNotEmpty ? topCats.first.name : "terbesar"} jadi '
            'penyumbang terbesar.',
      ));
    }

    // 3. Pengeluaran turun — kabar baik
    if (comparison.expenseChange < -10 && comparison.prevExpense > 0) {
      insights.add(FinancialInsight(
        type:    InsightType.good,
        title:   'Pengeluaran turun ${comparison.expenseChange.abs().toStringAsFixed(0)}%',
        message:
            'Dibanding bulan lalu, kamu berhasil menekan pengeluaran. Kerja bagus!',
      ));
    }

    // 4. Satu kategori dominan (>40% dari total)
    if (topCats.isNotEmpty && topCats.first.ratio > 0.4) {
      insights.add(FinancialInsight(
        type:    InsightType.info,
        title:   '${topCats.first.name} mendominasi',
        message:
            '${(topCats.first.ratio * 100).toStringAsFixed(0)}% pengeluaranmu '
            'bulan ini berasal dari kategori ${topCats.first.name}. '
            'Pertimbangkan untuk menetapkan budget agar lebih terkontrol.',
      ));
    }

    // 5. Income naik — motivasi
    if (comparison.incomeChange > 0 && comparison.prevIncome > 0) {
      insights.add(FinancialInsight(
        type:    InsightType.good,
        title:   'Pemasukan naik ${comparison.incomeChange.toStringAsFixed(0)}%',
        message:
            'Pemasukanmu bulan ini lebih tinggi dari bulan lalu. '
            'Sisihkan sebagian kenaikan ini untuk tabungan atau investasi!',
      ));
    }

    // 6. Belum ada transaksi
    if (comparison.thisIncome == 0 && comparison.thisExpense == 0) {
      insights.add(const FinancialInsight(
        type:    InsightType.info,
        title:   'Belum ada data bulan ini',
        message:
            'Mulai catat transaksimu agar Saku bisa memberikan analisis keuangan yang akurat.',
      ));
    }

    return insights;
  }
}
