import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/report_repository.dart';

class MonthlyBarChart extends StatefulWidget {
  final List<MonthlyBarData> data;
  const MonthlyBarChart({super.key, required this.data});

  @override
  State<MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<MonthlyBarChart> {
  int _touchedIndex = -1;

  static const _monthLabels = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.data.fold<double>(
      0,
      (m, d) => [m, d.income, d.expense].reduce(
          (a, b) => a > b ? a : b),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMd,
          AppTheme.spacingMd,
          AppTheme.spacingMd,
          AppTheme.spacingXs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Legend ───────────────────────────────────────────────────
            Row(
              children: [
                _LegendDot(color: AppColors.income,   label: 'Pemasukan'),
                const SizedBox(width: AppTheme.spacingMd),
                _LegendDot(color: AppColors.expense, label: 'Pengeluaran'),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Bar chart ────────────────────────────────────────────────
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY:        maxVal * 1.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: AppColors.border,
                      strokeWidth: 0.8,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 ||
                              idx >= widget.data.length) {
                            return const SizedBox.shrink();
                          }
                          final m = widget.data[idx].month.month;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _monthLabels[m],
                              style: AppTextStyles.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.spot == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            response.spot!.touchedBarGroupIndex;
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.textPrimary,
                      getTooltipItem: (group, groupIdx, rod, rodIdx) {
                        final d = widget.data[groupIdx];
                        final label =
                            rodIdx == 0 ? 'Masuk' : 'Keluar';
                        final val =
                            rodIdx == 0 ? d.income : d.expense;
                        return BarTooltipItem(
                          '$label\n',
                          AppTextStyles.labelSmall.copyWith(
                              color: Colors.white),
                          children: [
                            TextSpan(
                              text: CurrencyFormatter.formatCompact(val),
                              style: AppTextStyles.bodyMedium
                                  .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  barGroups:
                      List.generate(widget.data.length, (i) {
                    final d       = widget.data[i];
                    final touched = _touchedIndex == i;

                    return BarChartGroupData(
                      x:            i,
                      groupVertically: false,
                      barRods: [
                        // Income bar
                        BarChartRodData(
                          toY: d.income,
                          color: touched
                              ? AppColors.income
                              : AppColors.income.withValues(alpha: 0.7),
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                        // Expense bar
                        BarChartRodData(
                          toY: d.expense,
                          color: touched
                              ? AppColors.expense
                              : AppColors.expense.withValues(alpha: 0.7),
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
