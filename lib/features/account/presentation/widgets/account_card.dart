import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Kartu ringkasan satu akun — tampil di AccountScreen.
class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AccountCard({
    super.key,
    required this.account,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = _accountTypeInfo(account.type);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // ── Ikon tipe akun ─────────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeInfo.color.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  typeInfo.icon,
                  color: typeInfo.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // ── Nama & tipe ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      typeInfo.label,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),

              // ── Saldo ──────────────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(account.currentBalance),
                    style: AppTextStyles.amountMedium.copyWith(
                      color: account.currentBalance >= 0
                          ? AppColors.textPrimary
                          : AppColors.expense,
                    ),
                  ),
                ],
              ),

              // ── Menu hapus ─────────────────────────────────────────────────
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            color: AppColors.expense, size: 18),
                        SizedBox(width: 8),
                        Text('Hapus akun'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

class _TypeInfo {
  final IconData icon;
  final Color color;
  final String label;
  const _TypeInfo(this.icon, this.color, this.label);
}

_TypeInfo _accountTypeInfo(String type) {
  switch (type) {
    case 'bank':
      return const _TypeInfo(
        Icons.account_balance_outlined,
        AppColors.primary,
        'Rekening bank',
      );
    case 'ewallet':
      return const _TypeInfo(
        Icons.phone_android_outlined,
        Color(0xFF3B82F6), // biru muda
        'Dompet digital',
      );
    case 'cash':
    default:
      return const _TypeInfo(
        Icons.payments_outlined,
        AppColors.income,
        'Tunai',
      );
  }
}
