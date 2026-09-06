import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/budget_alert_service.dart';

/// Banner notifikasi in-app yang tampil jika ada budget mendekati/terlampaui.
/// Ditampilkan di HomeScreen saat user membuka app.
class BudgetAlertBanner extends StatelessWidget {
  final AppDatabase db;

  const BudgetAlertBanner({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final service = BudgetAlertService(db);

    return FutureBuilder<List<BudgetAlert>>(
      future: service.getAlerts(year: now.year, month: now.month),
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? [];
        if (alerts.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: alerts.any((a) => a.isOver)
                ? AppColors.expenseSoft
                : AppColors.warningSoft,
            border: Border.all(
              color: alerts.any((a) => a.isOver)
                  ? AppColors.expense.withValues(alpha: 0.35)
                  : AppColors.warning.withValues(alpha: 0.35),
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                  AppTheme.spacingXs,
                ),
                child: Row(
                  children: [
                    Icon(
                      alerts.any((a) => a.isOver)
                          ? Icons.warning_amber_outlined
                          : Icons.info_outline,
                      size: 16,
                      color: alerts.any((a) => a.isOver)
                          ? AppColors.expense
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      alerts.any((a) => a.isOver)
                          ? 'Budget terlampaui'
                          : 'Mendekati batas budget',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: alerts.any((a) => a.isOver)
                            ? AppColors.expense
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              ...alerts.map(
                (alert) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd,
                    2,
                    AppTheme.spacingMd,
                    2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alert.category.name,
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text(
                        '${CurrencyFormatter.format(alert.spent)} / ${CurrencyFormatter.format(alert.budget)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: alert.isOver
                              ? AppColors.expense
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        );
      },
    );
  }
}
