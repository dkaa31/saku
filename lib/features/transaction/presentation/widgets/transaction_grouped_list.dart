import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../add_transaction_screen.dart';
import '../../../transaction/data/transaction_repository.dart';
import 'transaction_list_item.dart';

/// Daftar transaksi dikelompokkan per tanggal.
/// Menerima map: kategori & akun untuk ditampilkan di tiap item.
class TransactionGroupedList extends StatelessWidget {
  final List<Transaction> transactions;
  final Map<int, String> categoryNames; // categoryId → name
  final Map<int, String> accountNames;  // accountId  → name
  final AppDatabase db;

  const TransactionGroupedList({
    super.key,
    required this.transactions,
    required this.categoryNames,
    required this.accountNames,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const _EmptyTransactions();
    }

    // Kelompokkan per tanggal
    final grouped = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, i) {
        final date = sortedDates[i];
        final dayTxs = grouped[date]!;

        final dayTotal = dayTxs.fold<double>(0, (sum, tx) {
          return tx.type == 'income'
              ? sum + tx.amount
              : sum - tx.amount;
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header tanggal ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingXs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.formatRelative(date),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${dayTotal >= 0 ? '+' : ''}${CurrencyFormatter.format(dayTotal)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: dayTotal >= 0
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),

            // ── Item transaksi ───────────────────────────────────────────
            Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd),
              child: Column(
                children: [
                  for (int j = 0; j < dayTxs.length; j++) ...[
                    if (j > 0)
                      const Divider(
                          height: 1,
                          indent: AppTheme.spacingMd,
                          endIndent: AppTheme.spacingMd),
                    TransactionListItem(
                      transaction: dayTxs[j],
                      categoryName: categoryNames[dayTxs[j].categoryId] ??
                          'Kategori',
                      accountName:
                          accountNames[dayTxs[j].accountId] ?? 'Akun',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTransactionScreen(
                            db: db,
                            transaction: dayTxs[j],
                          ),
                        ),
                      ),
                      onDelete: () =>
                          _confirmDelete(context, dayTxs[j]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Transaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi'),
        content: const Text(
            'Hapus transaksi ini? Saldo akun akan disesuaikan kembali.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = TransactionRepository(db);
      await repo.delete(tx.id);
    }
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 56, color: AppColors.textDisabled),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Belum ada transaksi',
              style: AppTextStyles.headingMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Tekan tombol + untuk mencatat transaksi pertamamu.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
