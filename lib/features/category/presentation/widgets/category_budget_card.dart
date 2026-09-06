import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_ui_helper.dart';
import '../../../../core/utils/currency_formatter.dart';

class CategoryBudgetCard extends StatelessWidget {
  final Category category;
  final double spent;
  final bool showBudget;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CategoryBudgetCard({
    super.key,
    required this.category,
    required this.spent,
    required this.showBudget,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final budget   = category.budgetMonthly;
    final hasBudget = showBudget && budget != null && budget > 0;
    final ratio    = hasBudget ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOver   = hasBudget && spent > budget;
    final isNear   = hasBudget && !isOver && ratio >= 0.8;

    // Warna custom kategori
    final catColor = CategoryColors.fromHex(category.colorHex);

    Color progressColor = catColor;
    if (isOver) progressColor = AppColors.expense;
    if (isNear) progressColor = AppColors.warning;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Row(
                children: [
                  // Ikon custom
                  Container(
                    width:  40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:        catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(
                      CategoryIcons.fromName(category.iconName),
                      color: catColor,
                      size:  20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name, style: AppTextStyles.bodyLarge),
                        if (category.bucket != null)
                          Text(
                            _bucketLabel(category.bucket!),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: catColor,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Label bucket badge
                  if (category.bucket != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        _bucketLabel(category.bucket!),
                        style: AppTextStyles.labelSmall.copyWith(
                          color:      catColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textSecondary, size: 18),
                    onSelected: (v) {
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: AppColors.expense, size: 18),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Spending / budget ──────────────────────────────────────
              if (showBudget) ...[
                const SizedBox(height: AppTheme.spacingMd),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(spent),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isOver
                            ? AppColors.expense
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasBudget)
                      Text(
                        'dari ${CurrencyFormatter.format(budget)}',
                        style: AppTextStyles.bodySmall,
                      )
                    else
                      Text(
                        'Belum ada budget',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textDisabled,
                        ),
                      ),
                  ],
                ),

                // Progress bar
                if (hasBudget) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSmall),
                    child: LinearProgressIndicator(
                      value:       ratio,
                      minHeight:   6,
                      backgroundColor: AppColors.border,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),

                  if (isOver) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 13, color: AppColors.expense),
                        const SizedBox(width: 4),
                        Text(
                          'Melebihi budget ${CurrencyFormatter.format(spent - budget)}',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.expense),
                        ),
                      ],
                    ),
                  ] else if (isNear) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 13, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          'Mendekati batas budget (${(ratio * 100).toStringAsFixed(0)}%)',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.warning),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _bucketLabel(String bucket) {
  switch (bucket) {
    case 'savings':  return 'Tabungan';
    case 'needs':    return 'Kebutuhan';
    case 'personal': return 'Pribadi';
    default:         return bucket;
  }
}
