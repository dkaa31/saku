import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../account/data/account_repository.dart';
import '../../category/data/category_repository.dart';
import '../../category/presentation/widgets/budget_alert_banner.dart';
import '../../transaction/data/transaction_repository.dart';
import '../../transaction/presentation/add_transaction_screen.dart';
import '../../transaction/presentation/widgets/transaction_grouped_list.dart';

class HomeScreen extends StatefulWidget {
  final AppDatabase db;
  const HomeScreen({super.key, required this.db});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  @override
  Widget build(BuildContext context) {
    final txRepo  = TransactionRepository(widget.db);
    final catRepo = CategoryRepository(widget.db);
    final accRepo = AccountRepository(widget.db);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<Transaction>>(
          stream: txRepo.watchByMonth(
              _currentMonth.year, _currentMonth.month),
          builder: (context, txSnap) {
            final transactions = txSnap.data ?? [];

            return FutureBuilder<_HomeData>(
              future: _loadHomeData(catRepo, accRepo, transactions),
              builder: (context, dataSnap) {
                final data = dataSnap.data;

                return CustomScrollView(
                  slivers: [
                    // ── App bar custom ─────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spacingMd,
                          AppTheme.spacingMd,
                          AppTheme.spacingMd,
                          0,
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Saku',
                                    style:
                                        AppTextStyles.headingLarge),
                                Text(
                                  DateFormatter.formatMonthYear(
                                      _currentMonth),
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                            // Navigasi bulan
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.chevron_left,
                                      size: 22),
                                  onPressed: () => setState(() {
                                    _currentMonth = DateTime(
                                      _currentMonth.year,
                                      _currentMonth.month - 1,
                                    );
                                  }),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.chevron_right,
                                      size: 22),
                                  onPressed: _currentMonth.month ==
                                          DateTime.now().month &&
                                      _currentMonth.year ==
                                          DateTime.now().year
                                      ? null
                                      : () => setState(() {
                                            _currentMonth = DateTime(
                                              _currentMonth.year,
                                              _currentMonth.month + 1,
                                            );
                                          }),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Kartu ringkasan bulan ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        child: _MonthlySummaryCard(
                          income:  data?.income  ?? 0,
                          expense: data?.expense ?? 0,
                          totalBalance: data?.totalBalance ?? 0,
                        ),
                      ),
                    ),

                    // ── Budget alert banner ────────────────────────────────
                    SliverToBoxAdapter(
                      child: BudgetAlertBanner(db: widget.db),
                    ),

                    // ── Header list transaksi ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spacingMd,
                          AppTheme.spacingMd,
                          AppTheme.spacingMd,
                          0,
                        ),
                        child: Text(
                          'Transaksi',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),

                    // ── List transaksi ─────────────────────────────────────
                    SliverToBoxAdapter(
                      child: TransactionGroupedList(
                        transactions: transactions,
                        categoryNames: data?.categoryNames ?? {},
                        accountNames:  data?.accountNames  ?? {},
                        db: widget.db,
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),

      // ── FAB tambah transaksi ─────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(db: widget.db),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<_HomeData> _loadHomeData(
    CategoryRepository catRepo,
    AccountRepository accRepo,
    List<Transaction> transactions,
  ) async {
    final cats     = await catRepo.getAll();
    final accounts = await accRepo.getAllAccounts();

    final catMap = {for (final c in cats) c.id: c.name};
    final accMap = {for (final a in accounts) a.id: a.name};

    double income  = 0;
    double expense = 0;
    for (final tx in transactions) {
      if (tx.type == 'income') {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    final totalBalance = accounts.fold<double>(
        0, (s, a) => s + a.currentBalance);

    return _HomeData(
      categoryNames: catMap,
      accountNames:  accMap,
      income:        income,
      expense:       expense,
      totalBalance:  totalBalance,
    );
  }
}

class _HomeData {
  final Map<int, String> categoryNames;
  final Map<int, String> accountNames;
  final double income;
  final double expense;
  final double totalBalance;

  const _HomeData({
    required this.categoryNames,
    required this.accountNames,
    required this.income,
    required this.expense,
    required this.totalBalance,
  });
}

// ─── Kartu ringkasan bulanan ──────────────────────────────────────────────────

class _MonthlySummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double totalBalance;

  const _MonthlySummaryCard({
    required this.income,
    required this.expense,
    required this.totalBalance,
  });

  @override
  Widget build(BuildContext context) {
    final net = income - expense;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total saldo semua akun
            Text(
              'Total saldo',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(totalBalance),
              style: AppTextStyles.amountLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Divider putih tipis
            Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: AppTheme.spacingMd),

            // Income / Expense / Net bulan ini
            Row(
              children: [
                _SummaryItem(
                  label: 'Pemasukan',
                  amount: income,
                  amountColor: const Color(0xFF6EE7B7), // hijau mint di atas biru
                  icon: Icons.arrow_downward_rounded,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                _SummaryItem(
                  label: 'Pengeluaran',
                  amount: expense,
                  amountColor: const Color(0xFFFCA5A5), // merah muda di atas biru
                  icon: Icons.arrow_upward_rounded,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                _SummaryItem(
                  label: 'Selisih',
                  amount: net,
                  amountColor: net >= 0
                      ? const Color(0xFF6EE7B7)
                      : const Color(0xFFFCA5A5),
                  icon: net >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
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
  final String label;
  final double amount;
  final Color amountColor;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.amountColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: AppTextStyles.amountMedium.copyWith(
              color: amountColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
