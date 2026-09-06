import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../account/data/account_repository.dart';
import '../../transaction/data/transaction_repository.dart';
import '../data/report_repository.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/monthly_bar_chart.dart';
import 'widgets/top_category_card.dart';
import 'widgets/month_comparison_card.dart';
import 'widgets/insight_card.dart';

class ReportScreen extends StatefulWidget {
  final AppDatabase db;
  const ReportScreen({super.key, required this.db});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  int?          _filterAccountId;
  List<Account> _accounts = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAccounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final accounts = await AccountRepository(widget.db).getAllAccounts();
    if (mounted) setState(() => _accounts = accounts);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ReportRepository(widget.db);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Kategori'),
            Tab(text: 'Analisis'),
          ],
        ),
        actions: [
          PopupMenuButton<int?>(
            icon: Icon(
              Icons.filter_list_outlined,
              color: _filterAccountId != null ? AppColors.primary : null,
            ),
            tooltip: 'Filter akun',
            onSelected: (v) => setState(() => _filterAccountId = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Semua akun')),
              ..._accounts.map(
                (a) => PopupMenuItem(value: a.id, child: Text(a.name)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Navigasi bulan (shared) ────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _MonthNavigator(
              month: _selectedMonth,
              onPrev: () => setState(() {
                _selectedMonth = DateTime(
                    _selectedMonth.year, _selectedMonth.month - 1);
              }),
              onNext: _selectedMonth.year == DateTime.now().year &&
                      _selectedMonth.month == DateTime.now().month
                  ? null
                  : () => setState(() {
                        _selectedMonth = DateTime(
                            _selectedMonth.year, _selectedMonth.month + 1);
                      }),
            ),
          ),
          const Divider(height: 1),

          // ── Tab content ───────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: Ringkasan
                _RingkasanTab(
                  db:             widget.db,
                  repo:           repo,
                  selectedMonth:  _selectedMonth,
                  filterAccountId: _filterAccountId,
                ),
                // Tab 1: Kategori
                _KategoriTab(
                  repo:          repo,
                  selectedMonth: _selectedMonth,
                ),
                // Tab 2: Analisis
                _AnalisisTab(
                  repo:          repo,
                  selectedMonth: _selectedMonth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Ringkasan ────────────────────────────────────────────────────────────

class _RingkasanTab extends StatelessWidget {
  final AppDatabase db;
  final ReportRepository repo;
  final DateTime selectedMonth;
  final int? filterAccountId;

  const _RingkasanTab({
    required this.db,
    required this.repo,
    required this.selectedMonth,
    required this.filterAccountId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Ringkasan income/expense/net
        FutureBuilder<MonthlySummary>(
          future: repo.getSummaryFiltered(
            start: DateTime(selectedMonth.year, selectedMonth.month, 1),
            end:   DateTime(selectedMonth.year, selectedMonth.month + 1, 1),
            accountId: filterAccountId,
          ),
          builder: (context, snap) {
            final s = snap.data;
            return _SummaryCard(
              income:  s?.income  ?? 0,
              expense: s?.expense ?? 0,
              net:     s?.net     ?? 0,
            );
          },
        ),
        const SizedBox(height: AppTheme.spacingLg),

        // Tren 6 bulan
        Text('Tren 6 bulan', style: AppTextStyles.headingMedium),
        const SizedBox(height: AppTheme.spacingMd),
        FutureBuilder(
          future: repo.getMonthlyTrend(months: 6),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _LoadingBox();
            }
            final trend = snap.data ?? [];
            if (trend.every((d) => d.income == 0 && d.expense == 0)) {
              return const _EmptyChart(label: 'Belum ada data tren');
            }
            return MonthlyBarChart(data: trend);
          },
        ),
        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }
}

// ─── Tab Kategori ─────────────────────────────────────────────────────────────

class _KategoriTab extends StatelessWidget {
  final ReportRepository repo;
  final DateTime selectedMonth;

  const _KategoriTab(
      {required this.repo, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Donut chart
        Text('Pengeluaran per kategori',
            style: AppTextStyles.headingMedium),
        const SizedBox(height: AppTheme.spacingMd),
        FutureBuilder(
          future: repo.getCategorySlices(
            year:  selectedMonth.year,
            month: selectedMonth.month,
          ),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _LoadingBox();
            }
            final slices = snap.data ?? [];
            if (slices.isEmpty) {
              return const _EmptyChart(
                  label: 'Belum ada pengeluaran bulan ini');
            }
            return CategoryPieChart(slices: slices);
          },
        ),
        const SizedBox(height: AppTheme.spacingLg),

        // Top pengeluaran
        FutureBuilder(
          future: repo.getTopExpenseCategories(
            year:  selectedMonth.year,
            month: selectedMonth.month,
          ),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _LoadingBox();
            }
            final tops = snap.data ?? [];
            if (tops.isEmpty) return const SizedBox.shrink();
            return TopCategoryCard(items: tops);
          },
        ),
        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }
}

// ─── Tab Analisis ─────────────────────────────────────────────────────────────

class _AnalisisTab extends StatelessWidget {
  final ReportRepository repo;
  final DateTime selectedMonth;

  const _AnalisisTab(
      {required this.repo, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Perbandingan bulan ini vs lalu
        FutureBuilder(
          future: repo.getMonthComparison(
            year:  selectedMonth.year,
            month: selectedMonth.month,
          ),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _LoadingBox();
            }
            final data = snap.data;
            if (data == null) return const SizedBox.shrink();
            return MonthComparisonCard(data: data);
          },
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Insight otomatis
        FutureBuilder(
          future: repo.getInsights(
            year:  selectedMonth.year,
            month: selectedMonth.month,
          ),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _LoadingBox();
            }
            final insights = snap.data ?? [];
            return InsightCard(insights: insights);
          },
        ),
        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double net;

  const _SummaryCard(
      {required this.income, required this.expense, required this.net});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            // Net balance highlight
            Container(
              width:  double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingMd,
                  horizontal: AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: net >= 0
                    ? AppColors.incomeSoft
                    : AppColors.expenseSoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                children: [
                  Text(
                    net >= 0 ? 'Surplus bulan ini' : 'Defisit bulan ini',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: net >= 0 ? AppColors.income : AppColors.expense,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(net.abs()),
                    style: AppTextStyles.amountLarge.copyWith(
                      color: net >= 0 ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                _SummaryItem(
                  label:  'Pemasukan',
                  amount: income,
                  color:  AppColors.income,
                  icon:   Icons.arrow_downward_rounded,
                ),
                Container(
                    width: 1, height: 40, color: AppColors.border),
                _SummaryItem(
                  label:  'Pengeluaran',
                  amount: expense,
                  color:  AppColors.expense,
                  icon:   Icons.arrow_upward_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String  label;
  final double  amount;
  final Color   color;
  final IconData icon;
  const _SummaryItem(
      {required this.label,
      required this.amount,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyles.labelSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: AppTextStyles.amountMedium.copyWith(
              color:    color,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Month Navigator ──────────────────────────────────────────────────────────

class _MonthNavigator extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _MonthNavigator(
      {required this.month, required this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon:      const Icon(Icons.chevron_left),
          onPressed: onPrev,
        ),
        Text(
          DateFormatter.formatMonthYear(month),
          style: AppTextStyles.headingMedium,
        ),
        IconButton(
          icon:      const Icon(Icons.chevron_right),
          onPressed: onNext,
          color:     onNext == null ? AppColors.textDisabled : null,
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String label;
  const _EmptyChart({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color:        AppColors.surface,
        border:       Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 32, color: AppColors.textDisabled),
            const SizedBox(height: 8),
            Text(label,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
