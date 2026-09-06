import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/account_repository.dart';
import 'widgets/account_card.dart';
import 'add_edit_account_screen.dart';
import 'transfer_screen.dart';

class AccountScreen extends StatelessWidget {
  final AppDatabase db;
  const AccountScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    final repo = AccountRepository(db);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Akun & dompet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_outlined),
            tooltip: 'Transfer antar akun',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransferScreen(db: db),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah akun',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditAccountScreen(db: db),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Account>>(
        stream: repo.watchAllAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final accounts = snapshot.data ?? [];

          if (accounts.isEmpty) {
            return _EmptyState(
              onAdd: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditAccountScreen(db: db),
                ),
              ),
            );
          }

          final totalBalance =
              accounts.fold(0.0, (sum, a) => sum + a.currentBalance);

          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            children: [
              // ── Total saldo ────────────────────────────────────────────────
              _TotalBalanceCard(totalBalance: totalBalance),
              const SizedBox(height: AppTheme.spacingMd),

              // ── Daftar akun ────────────────────────────────────────────────
              Text(
                'Semua akun',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ...accounts.map(
                (account) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppTheme.spacingSm),
                  child: AccountCard(
                    account: account,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEditAccountScreen(db: db, account: account),
                      ),
                    ),
                    onDelete: () =>
                        _confirmDelete(context, repo, account),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AccountRepository repo,
    Account account,
  ) async {
    final canDelete = await repo.canDelete(account.id);

    if (!context.mounted) return;

    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Akun tidak bisa dihapus karena masih memiliki transaksi.',
          ),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus akun'),
        content: Text(
          'Hapus "${account.name}"? Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await repo.deleteAccount(account.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              'Hapus',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Total balance card ────────────────────────────────────────────────────────

class _TotalBalanceCard extends StatelessWidget {
  final double totalBalance;
  const _TotalBalanceCard({required this.totalBalance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total saldo',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            CurrencyFormatter.format(totalBalance),
            style: AppTextStyles.amountLarge.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 56,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Belum ada akun',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Tambahkan akun pertamamu untuk mulai mencatat keuangan.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah akun'),
            ),
          ],
        ),
      ),
    );
  }
}
