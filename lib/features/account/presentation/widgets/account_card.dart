import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Palet warna untuk kartu akun — setiap akun dapat warna berbeda
const _cardPalette = [
  Color(0xFF2563EB), // biru royal
  Color(0xFF7C3AED), // ungu
  Color(0xFF059669), // hijau
  Color(0xFFD97706), // amber
  Color(0xFFDB2777), // pink
  Color(0xFF0891B2), // cyan
  Color(0xFFDC2626), // merah
  Color(0xFF0D9488), // teal
];

/// Ambil warna berdasarkan id akun agar setiap akun selalu konsisten
Color _colorForAccount(int id) => _cardPalette[id % _cardPalette.length];

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
    final typeInfo   = _accountTypeInfo(account.type);
    final accentColor = _colorForAccount(account.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            gradient: LinearGradient(
              colors: [
                accentColor,
                accentColor.withValues(alpha: 0.82),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // ── Ikon tipe ────────────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  typeInfo.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // ── Nama & tipe ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeInfo.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Saldo ────────────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(account.currentBalance),
                    style: AppTextStyles.amountMedium.copyWith(
                      color: account.currentBalance >= 0
                          ? Colors.white
                          : const Color(0xFFFFCDD2), // merah muda di atas warna gelap
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Saldo',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),

              // ── Menu hapus ───────────────────────────────────────────────
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.white.withValues(alpha: 0.8),
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

// ─── Tipe info ────────────────────────────────────────────────────────────────

class _TypeInfo {
  final IconData icon;
  final String label;
  const _TypeInfo(this.icon, this.label);
}

_TypeInfo _accountTypeInfo(String type) {
  switch (type) {
    case 'bank':
      return const _TypeInfo(Icons.account_balance_outlined, 'Rekening bank');
    case 'ewallet':
      return const _TypeInfo(Icons.phone_android_outlined, 'Dompet digital');
    case 'other':
      return const _TypeInfo(Icons.category_outlined, 'Lainnya');
    case 'cash':
    default:
      return const _TypeInfo(Icons.payments_outlined, 'Tunai');
  }
}
