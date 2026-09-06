import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/report_repository.dart';

class MonthComparisonCard extends StatelessWidget {
  final MonthComparison data;
  const MonthComparisonCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Bulan ini vs bulan lalu',
                    style: AppTextStyles.headingMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Saving rate highlight ──────────────────────────────────────
            _SavingRateBar(
              thisRate: data.thisSavingRate,
              prevRate: data.prevSavingRate,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const Divider(),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Income row ────────────────────────────────────────────────
            _CompareRow(
              label:       'Pemasukan',
              thisAmount:  data.thisIncome,
              prevAmount:  data.prevIncome,
              changePercent: data.incomeChange,
              isExpense:   false,
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Expense row ───────────────────────────────────────────────
            _CompareRow(
              label:       'Pengeluaran',
              thisAmount:  data.thisExpense,
              prevAmount:  data.prevExpense,
              changePercent: data.expenseChange,
              isExpense:   true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingRateBar extends StatelessWidget {
  final double thisRate;
  final double prevRate;
  const _SavingRateBar({required this.thisRate, required this.prevRate});

  Color get _rateColor {
    if (thisRate >= 20) return AppColors.income;
    if (thisRate >= 0)  return AppColors.warning;
    return AppColors.expense;
  }

  @override
  Widget build(BuildContext context) {
    final displayRate = thisRate.clamp(-100.0, 100.0);
    final barValue    = (displayRate / 100).clamp(0.0, 1.0);

    return Container(
      padding:    const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color:        _rateColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border:       Border.all(
          color: _rateColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saving rate bulan ini',
                      style: AppTextStyles.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Target minimal 20%',
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
              Text(
                '${thisRate.toStringAsFixed(1)}%',
                style: AppTextStyles.displayMedium.copyWith(
                  color:      _rateColor,
                  fontSize:   22,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Stack(
            children: [
              // Background bar (target 20%)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:           0.2,
                  minHeight:       8,
                  backgroundColor: AppColors.border,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.border),
                ),
              ),
              // Actual rate bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:           barValue,
                  minHeight:       8,
                  backgroundColor: Colors.transparent,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_rateColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: AppTextStyles.labelSmall),
              Text(
                'Bulan lalu: ${prevRate.toStringAsFixed(1)}%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text('100%', style: AppTextStyles.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final double thisAmount;
  final double prevAmount;
  final double changePercent;
  final bool   isExpense;

  const _CompareRow({
    required this.label,
    required this.thisAmount,
    required this.prevAmount,
    required this.changePercent,
    required this.isExpense,
  });

  // Untuk expense: naik = buruk (merah), turun = baik (hijau)
  // Untuk income:  naik = baik (hijau), turun = buruk (merah)
  Color get _changeColor {
    if (changePercent == 0) return AppColors.textSecondary;
    final isUp = changePercent > 0;
    if (isExpense) return isUp ? AppColors.expense : AppColors.income;
    return isUp ? AppColors.income : AppColors.expense;
  }

  @override
  Widget build(BuildContext context) {
    final hasChange = prevAmount > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelMedium),
              if (hasChange)
                Text(
                  'Lalu: ${CurrencyFormatter.formatCompact(prevAmount)}',
                  style: AppTextStyles.labelSmall,
                ),
            ],
          ),
        ),

        // Jumlah bulan ini
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatCompact(thisAmount),
                style: AppTextStyles.amountMedium.copyWith(
                  color: isExpense ? AppColors.expense : AppColors.income,
                  fontSize: 15,
                ),
              ),
              if (hasChange && changePercent != 0) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      changePercent > 0
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size:  12,
                      color: _changeColor,
                    ),
                    Text(
                      '${changePercent.abs().toStringAsFixed(1)}% vs bln lalu',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: _changeColor),
                    ),
                  ],
                ),
              ] else if (!hasChange) ...[
                Text(
                  'Tidak ada data bln lalu',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
