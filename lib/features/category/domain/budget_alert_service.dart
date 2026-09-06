import '../../../core/database/app_database.dart';
import '../data/category_repository.dart';

/// Model untuk satu peringatan budget yang terlampaui
class BudgetAlert {
  final Category category;
  final double spent;
  final double budget;

  const BudgetAlert({
    required this.category,
    required this.spent,
    required this.budget,
  });

  double get ratio => spent / budget;
  bool get isOver => spent > budget;
  bool get isNear => !isOver && ratio >= 0.8;
}

/// Service yang mengecek kategori mana yang over/mendekati budget bulan ini
class BudgetAlertService {
  final CategoryRepository _repo;
  BudgetAlertService(AppDatabase db) : _repo = CategoryRepository(db);

  Future<List<BudgetAlert>> getAlerts({
    required int year,
    required int month,
  }) async {
    final categories = await _repo.getByType('expense');
    final spending =
        await _repo.getSpendingByCategory(year: year, month: month);

    final alerts = <BudgetAlert>[];

    for (final cat in categories) {
      final budget = cat.budgetMonthly;
      if (budget == null || budget <= 0) continue;

      final spent = spending[cat.id] ?? 0.0;
      final ratio = spent / budget;

      // Tampilkan alert jika >= 80% atau sudah over
      if (ratio >= 0.8) {
        alerts.add(BudgetAlert(
          category: cat,
          spent: spent,
          budget: budget,
        ));
      }
    }

    // Urutkan: over-budget dulu, lalu mendekati
    alerts.sort((a, b) => b.ratio.compareTo(a.ratio));
    return alerts;
  }
}
