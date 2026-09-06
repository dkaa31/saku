import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/allocation_service.dart';

class RatioEditScreen extends StatefulWidget {
  final AppDatabase db;
  const RatioEditScreen({super.key, required this.db});

  @override
  State<RatioEditScreen> createState() => _RatioEditScreenState();
}

class _RatioEditScreenState extends State<RatioEditScreen> {
  double _needs    = 50;
  double _savings  = 20;
  double _personal = 30;
  bool   _loading  = true;
  bool   _saving   = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings =
        await widget.db.select(widget.db.allocationSettings).get();
    if (settings.isNotEmpty && mounted) {
      setState(() {
        _needs    = settings.first.needsRatio;
        _savings  = settings.first.savingsRatio;
        _personal = settings.first.personalRatio;
        _loading  = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  double get _total => _needs + _savings + _personal;
  bool  get _valid => (_total - 100).abs() < 0.01;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Atur rasio alokasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              children: [
                // ── Info ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.0),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    'Total ketiga rasio harus tepat 100%. '
                    'Contoh populer: 50/30/20 (kebutuhan/pribadi/tabungan).',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // ── Sliders ───────────────────────────────────────────
                _RatioSlider(
                  label: 'Kebutuhan pokok',
                  value: _needs,
                  color: AppColors.primary,
                  onChanged: (v) => setState(() => _needs = v),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _RatioSlider(
                  label: 'Tabungan',
                  value: _savings,
                  color: AppColors.income,
                  onChanged: (v) => setState(() => _savings = v),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _RatioSlider(
                  label: 'Keperluan pribadi',
                  value: _personal,
                  color: const Color(0xFF7C3AED),
                  onChanged: (v) => setState(() => _personal = v),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // ── Total indikator ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: AppTextStyles.labelMedium),
                    Text(
                      '${_total.toStringAsFixed(0)}%',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: _valid
                            ? AppColors.income
                            : AppColors.expense,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (!_valid) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Total harus 100%. Sekarang: ${_total.toStringAsFixed(0)}%',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.expense),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingXl),

                // ── Preset buttons ────────────────────────────────────
                Text('Preset populer',
                    style: AppTextStyles.labelMedium),
                const SizedBox(height: AppTheme.spacingSm),
                Wrap(
                  spacing: AppTheme.spacingSm,
                  children: [
                    _PresetChip(
                      label: '50/30/20',
                      onTap: () => setState(() {
                        _needs    = 50;
                        _personal = 30;
                        _savings  = 20;
                      }),
                    ),
                    _PresetChip(
                      label: '60/20/20',
                      onTap: () => setState(() {
                        _needs    = 60;
                        _personal = 20;
                        _savings  = 20;
                      }),
                    ),
                    _PresetChip(
                      label: '40/30/30',
                      onTap: () => setState(() {
                        _needs    = 40;
                        _personal = 30;
                        _savings  = 30;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // ── Save button ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _valid && !_saving ? _save : null,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : const Text('Simpan rasio'),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AllocationService(widget.db).updateRatios(
        savings:  _savings,
        needs:    _needs,
        personal: _personal,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _RatioSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _RatioSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.labelMedium),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                '${value.toInt()}%',
                style: AppTextStyles.labelMedium
                    .copyWith(color: color),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: AppColors.border,
            overlayColor: color.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: 5,
            max: 90,
            divisions: 17,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border:
              Border.all(color: AppColors.border, width: 0.8),
          borderRadius:
              BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Text(label, style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
