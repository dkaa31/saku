import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_ui_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/report_repository.dart';

class TopCategoryCard extends StatelessWidget {
  final List<TopCategory> items;
  const TopCategoryCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Top pengeluaran', style: AppTextStyles.headingMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...List.generate(items.length, (i) {
              final item  = items[i];
              final color = CategoryColors.fromHex(item.colorHex);
              return _TopItem(
                rank:  i + 1,
                item:  item,
                color: color,
                isLast: i == items.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TopItem extends StatelessWidget {
  final int rank;
  final TopCategory item;
  final Color color;
  final bool isLast;

  const _TopItem({
    required this.rank,
    required this.item,
    required this.color,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final change    = item.changePercent;
    final hasChange = item.prevAmount != null && item.prevAmount! > 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // Rank badge
              Container(
                width:  24,
                height: 24,
                decoration: BoxDecoration(
                  color: rank == 1
                      ? const Color(0xFFFEF3C7)
                      : AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: rank == 1
                          ? const Color(0xFFD97706)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),

              // Ikon kategori
              Container(
                width:  36,
                height: 36,
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  CategoryIcons.fromName(item.iconName),
                  size:  18,
                  color: color,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Nama & porsi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppTextStyles.bodyLarge),
                    // Progress bar porsi
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value:           item.ratio,
                        minHeight:       4,
                        backgroundColor: AppColors.border,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(item.ratio * 100).toStringAsFixed(0)}% dari total',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Jumlah & perubahan
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatCompact(item.amount),
                    style: AppTextStyles.amountMedium.copyWith(
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  if (hasChange) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          change > 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size:  11,
                          color: change > 0
                              ? AppColors.expense
                              : AppColors.income,
                        ),
                        Text(
                          '${change.abs().toStringAsFixed(0)}%',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: change > 0
                                ? AppColors.expense
                                : AppColors.income,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1),
      ],
    );
  }
}
