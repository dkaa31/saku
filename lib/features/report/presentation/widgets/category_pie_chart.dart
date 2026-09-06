import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_ui_helper.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/report_repository.dart';

// Fallback palette jika warna kategori tidak tersedia
const _fallbackColors = [
  Color(0xFF2563EB),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFF97316),
];

class CategoryPieChart extends StatefulWidget {
  final List<CategorySlice> slices;
  const CategoryPieChart({super.key, required this.slices});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  Color _colorFor(int i) {
    final slice = widget.slices[i];
    if (slice.colorHex.isNotEmpty) {
      return CategoryColors.fromHex(slice.colorHex);
    }
    return _fallbackColors[i % _fallbackColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            // ── Donut chart ──────────────────────────────────────────────
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace:     2,
                  centerSpaceRadius: 50,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response?.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            response!.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: _buildSections(),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Legend ───────────────────────────────────────────────────
            Wrap(
              spacing:    AppTheme.spacingMd,
              runSpacing: AppTheme.spacingXs,
              children: List.generate(widget.slices.length, (i) {
                final slice = widget.slices[i];
                final color = _colorFor(i);
                final isSelected = _touchedIndex == i;

                return GestureDetector(
                  onTap: () =>
                      setState(() => _touchedIndex = isSelected ? -1 : i),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width:  10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CategoryIcons.fromName(slice.iconName),
                        size:  12,
                        color: isSelected ? color : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${slice.categoryName} ${(slice.ratio * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? color : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            // ── Detail slice yang disentuh ────────────────────────────────
            if (_touchedIndex >= 0 &&
                _touchedIndex < widget.slices.length) ...[
              const SizedBox(height: AppTheme.spacingMd),
              const Divider(),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                children: [
                  Container(
                    width:  36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _colorFor(_touchedIndex)
                          .withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      CategoryIcons.fromName(
                          widget.slices[_touchedIndex].iconName),
                      size:  18,
                      color: _colorFor(_touchedIndex),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.slices[_touchedIndex].categoryName,
                          style: AppTextStyles.bodyLarge,
                        ),
                        Text(
                          '${(widget.slices[_touchedIndex].ratio * 100).toStringAsFixed(1)}% dari total pengeluaran',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(
                        widget.slices[_touchedIndex].amount),
                    style: AppTextStyles.amountMedium.copyWith(
                      color: _colorFor(_touchedIndex),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return List.generate(widget.slices.length, (i) {
      final slice   = widget.slices[i];
      final color   = _colorFor(i);
      final touched = _touchedIndex == i;

      return PieChartSectionData(
        color:     color,
        value:     slice.amount,
        radius:    touched ? 58 : 48,
        showTitle: touched,
        title:     '${(slice.ratio * 100).toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.w600,
          color:      Colors.white,
        ),
      );
    });
  }
}
