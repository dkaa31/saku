import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/allocation_service.dart';

class BucketCard extends StatelessWidget {
  final BucketResult bucket;
  const BucketCard({super.key, required this.bucket});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(bucket.status, bucket.key);
    final ratio = bucket.recommended > 0
        ? (bucket.actual / bucket.recommended).clamp(0.0, 1.2)
        : 0.0;

    Color barColor;
    if (bucket.key == 'savings') {
      // Tabungan: makin penuh makin hijau
      barColor = bucket.status == BucketStatus.boros
          ? AppColors.expense
          : bucket.status == BucketStatus.onTrack
              ? AppColors.warning
              : AppColors.income;
    } else {
      barColor = bucket.status == BucketStatus.boros
          ? AppColors.expense
          : bucket.status == BucketStatus.onTrack
              ? AppColors.primary
              : AppColors.income;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bucket.label,
                    style: AppTextStyles.headingMedium),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                        AppTheme.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusInfo.icon,
                          size: 14, color: statusInfo.color),
                      const SizedBox(width: 4),
                      Text(statusInfo.label,
                          style: AppTextStyles.labelSmall.copyWith(
                              color: statusInfo.color,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Nominal rekomendasi vs aktual ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: _AmountColumn(
                    label: 'Rekomendasi',
                    amount: bucket.recommended,
                    color: AppColors.textPrimary,
                  ),
                ),
                Expanded(
                  child: _AmountColumn(
                    label: 'Aktual',
                    amount: bucket.actual,
                    color: barColor,
                  ),
                ),
                Expanded(
                  child: _AmountColumn(
                    label: bucket.diff >= 0 ? 'Sisa' : 'Lebih',
                    amount: bucket.diff.abs(),
                    color: bucket.diff >= 0
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Progress bar ────────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusSmall),
              child: LinearProgressIndicator(
                value: ratio.toDouble(),
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${bucket.ratio.toInt()}% dari income',
                    style: AppTextStyles.labelSmall),
                Text(
                  '${(ratio * 100).toStringAsFixed(0)}% terpakai',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: barColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusInfo(this.label, this.color, this.icon);
}

_StatusInfo _statusInfo(BucketStatus status, String key) {
  // Untuk tabungan: hemat = bagus, boros = kurang menabung
  if (key == 'savings') {
    switch (status) {
      case BucketStatus.hemat:
        return const _StatusInfo(
            'Bagus', AppColors.income, Icons.savings_outlined);
      case BucketStatus.onTrack:
        return const _StatusInfo(
            'On track', AppColors.primary, Icons.check_circle_outline);
      case BucketStatus.boros:
        return const _StatusInfo(
            'Kurang', AppColors.expense, Icons.trending_down_outlined);
    }
  }

  switch (status) {
    case BucketStatus.hemat:
      return const _StatusInfo(
          'Hemat', AppColors.income, Icons.thumb_up_outlined);
    case BucketStatus.onTrack:
      return const _StatusInfo(
          'On track', AppColors.primary, Icons.check_circle_outline);
    case BucketStatus.boros:
      return const _StatusInfo(
          'Boros', AppColors.expense, Icons.warning_amber_outlined);
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountColumn({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.formatCompact(amount),
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
