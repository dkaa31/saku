import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/allocation_service.dart';
import 'widgets/bucket_card.dart';
import 'ratio_edit_screen.dart';

class RecommendationScreen extends StatefulWidget {
  final AppDatabase db;
  const RecommendationScreen({super.key, required this.db});

  @override
  State<RecommendationScreen> createState() =>
      _RecommendationScreenState();
}

class _RecommendationScreenState
    extends State<RecommendationScreen> {
  late Future<AllocationResult?> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = AllocationService(widget.db).calculate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rekomendasi alokasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Sesuaikan rasio',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RatioEditScreen(db: widget.db),
                ),
              );
              _refresh();
            },
          ),
        ],
      ),
      body: FutureBuilder<AllocationResult?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final result = snap.data;

          if (result == null) {
            return _NoDataState(db: widget.db, onRefresh: _refresh);
          }

          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            children: [
              // ── Header income dasar ──────────────────────────────────
              _IncomeHeader(
                income:      result.baseIncome,
                usedAverage: result.usedAverage,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // ── Rasio yang dipakai ───────────────────────────────────
              _RatioChips(setting: result.setting),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Bucket cards ─────────────────────────────────────────
              Text('Analisis per kelompok',
                  style: AppTextStyles.headingMedium),
              const SizedBox(height: AppTheme.spacingMd),
              ...result.buckets.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppTheme.spacingSm),
                  child: BucketCard(bucket: b),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // ── Penjelasan singkat ───────────────────────────────────
              _InfoBox(),
              const SizedBox(height: AppTheme.spacingXl),
            ],
          );
        },
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _IncomeHeader extends StatelessWidget {
  final double income;
  final bool usedAverage;

  const _IncomeHeader(
      {required this.income, required this.usedAverage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius:
            BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            usedAverage
                ? 'Rata-rata income 3 bulan'
                : 'Income bulan ini',
            style: AppTextStyles.bodyMedium
                .copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(income),
            style: AppTextStyles.amountLarge
                .copyWith(color: Colors.white),
          ),
          if (usedAverage) ...[
            const SizedBox(height: 4),
            Text(
              'Menggunakan rata-rata karena belum ada income bulan ini.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatioChips extends StatelessWidget {
  final AllocationSetting setting;
  const _RatioChips({required this.setting});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
            label: 'Kebutuhan',
            value: '${setting.needsRatio.toInt()}%',
            color: AppColors.primary,
            softColor: AppColors.primarySoft),
        const SizedBox(width: AppTheme.spacingXs),
        _Chip(
            label: 'Tabungan',
            value: '${setting.savingsRatio.toInt()}%',
            color: AppColors.income,
            softColor: AppColors.incomeSoft),
        const SizedBox(width: AppTheme.spacingXs),
        _Chip(
            label: 'Pribadi',
            value: '${setting.personalRatio.toInt()}%',
            color: const Color(0xFF7C3AED),
            softColor: const Color(0xFFF5F3FF)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color softColor;
  const _Chip(
      {required this.label, required this.value, required this.color, required this.softColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: softColor,
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.0),
          borderRadius:
              BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.headingMedium
                    .copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.labelSmall
                    .copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 0.8),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text('Cara membaca rekomendasi ini',
                style: AppTextStyles.labelMedium),
          ]),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Angka rekomendasi dihitung dari income bulan ini (atau rata-rata 3 bulan) '
            'dikalikan rasio yang sudah kamu tentukan.\n\n'
            'Setiap kategori transaksi dipetakan ke kelompok Kebutuhan, Tabungan, atau Pribadi. '
            'Kamu bisa mengubah pemetaan ini di menu Kategori.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NoDataState extends StatelessWidget {
  final AppDatabase db;
  final VoidCallback onRefresh;
  const _NoDataState({required this.db, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tips_and_updates_outlined,
                size: 56, color: AppColors.textDisabled),
            const SizedBox(height: AppTheme.spacingMd),
            Text('Belum ada data income',
                style: AppTextStyles.headingMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Catat minimal satu transaksi pemasukan agar rekomendasi bisa dihitung.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Perbarui'),
            ),
          ],
        ),
      ),
    );
  }
}
