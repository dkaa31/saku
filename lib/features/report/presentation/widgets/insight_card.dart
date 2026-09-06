import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/report_repository.dart';

class InsightCard extends StatelessWidget {
  final List<FinancialInsight> insights;
  const InsightCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 18, color: AppColors.warning),
                const SizedBox(width: 6),
                Text('Analisis & saran', style: AppTextStyles.headingMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...List.generate(insights.length, (i) => _InsightItem(
                  insight: insights[i],
                  isLast: i == insights.length - 1,
                )),
          ],
        ),
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final FinancialInsight insight;
  final bool isLast;
  const _InsightItem({required this.insight, required this.isLast});

  Color get _bgColor {
    switch (insight.type) {
      case InsightType.good:    return AppColors.incomeSoft;
      case InsightType.warning: return AppColors.warningSoft;
      case InsightType.info:    return AppColors.primarySoft;
    }
  }

  Color get _accentColor {
    switch (insight.type) {
      case InsightType.good:    return AppColors.income;
      case InsightType.warning: return AppColors.warning;
      case InsightType.info:    return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (insight.type) {
      case InsightType.good:    return Icons.check_circle_rounded;
      case InsightType.warning: return Icons.warning_amber_rounded;
      case InsightType.info:    return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color:        _bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: _accentColor.withValues(alpha: 0.25),
              width: 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon, size: 18, color: _accentColor),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const SizedBox(height: AppTheme.spacingSm),
      ],
    );
  }
}
