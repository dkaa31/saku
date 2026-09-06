import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../account/data/account_repository.dart';
import '../../recommendation/domain/allocation_service.dart';

class OnboardingScreen extends StatefulWidget {
  final AppDatabase db;
  const OnboardingScreen({super.key, required this.db});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1 — akun pertama
  final _accountNameController  = TextEditingController();
  final _balanceController      = TextEditingController();
  String _accountType           = 'cash';
  final _formKey                = GlobalKey<FormState>();

  // Step 2 — rasio alokasi
  double _needs    = 50;
  double _savings  = 20;
  double _personal = 30;

  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _accountNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  // ─── Total & validasi rasio ─────────────────────────────────────────────────
  double get _total => _needs + _savings + _personal;
  bool   get _ratioValid => (_total - 100).abs() < 0.01;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Indikator halaman ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                0,
              ),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      height: 3,
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Konten halaman ─────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(onNext: _goToPage1),
                  _AccountPage(
                    formKey:            _formKey,
                    nameController:     _accountNameController,
                    balanceController:  _balanceController,
                    accountType:        _accountType,
                    onTypeChanged: (t) =>
                        setState(() => _accountType = t),
                    onNext: _goToPage2,
                  ),
                  _RatioPage(
                    needs:    _needs,
                    savings:  _savings,
                    personal: _personal,
                    total:    _total,
                    isValid:  _ratioValid,
                    isSaving: _isSaving,
                    onNeedsChanged:    (v) => setState(() => _needs    = v),
                    onSavingsChanged:  (v) => setState(() => _savings  = v),
                    onPersonalChanged: (v) => setState(() => _personal = v),
                    onPreset: (n, s, p) => setState(() {
                      _needs    = n;
                      _savings  = s;
                      _personal = p;
                    }),
                    onFinish: _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPage1() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPage2() {
    if (!_formKey.currentState!.validate()) return;
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    if (!_ratioValid) return;
    setState(() => _isSaving = true);

    try {
      // Simpan akun pertama
      final accRepo = AccountRepository(widget.db);
      final balance =
          CurrencyFormatter.parse(_balanceController.text) ?? 0.0;
      await accRepo.createAccount(
        name:           _accountNameController.text.trim(),
        type:           _accountType,
        initialBalance: balance,
      );

      // Simpan rasio alokasi
      await AllocationService(widget.db).updateRatios(
        savings:  _savings,
        needs:    _needs,
        personal: _personal,
      );

      // Tandai onboarding selesai
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ─── Halaman 0: Selamat datang ────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),

          // Ikon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          Text('Selamat datang\ndi Saku',
              style: AppTextStyles.displayLarge),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Catat pemasukan dan pengeluaran harian, '
            'pantau budget, dan dapatkan rekomendasi alokasi keuangan '
            'yang sesuai dengan kondisimu.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(flex: 3),

          // Fitur highlights
          ...[
            _FeatureRow(
              icon: Icons.edit_note_outlined,
              label: 'Catat transaksi dalam hitungan detik',
            ),
            _FeatureRow(
              icon: Icons.bar_chart_outlined,
              label: 'Laporan visual pengeluaran bulanan',
            ),
            _FeatureRow(
              icon: Icons.tips_and_updates_outlined,
              label: 'Rekomendasi alokasi otomatis 50/30/20',
            ),
          ],

          const Spacer(flex: 2),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Mulai'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child:
                Text(label, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ─── Halaman 1: Buat akun pertama ─────────────────────────────────────────────

class _AccountPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController balanceController;
  final String accountType;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onNext;

  const _AccountPage({
    required this.formKey,
    required this.nameController,
    required this.balanceController,
    required this.accountType,
    required this.onTypeChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacingMd),
            Text('Buat akun pertama', style: AppTextStyles.displayMedium),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Akun adalah tempat menyimpan uangmu — bisa tunai, rekening bank, atau dompet digital.',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingXl),

            // ── Nama akun ────────────────────────────────────────────────
            Text('Nama akun', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppTheme.spacingXs),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Contoh: Dompet, BCA, GoPay',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nama akun tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Jenis akun ───────────────────────────────────────────────
            Text('Jenis akun', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppTheme.spacingXs),
            Row(
              children: [
                _typeChip('cash',    Icons.payments_outlined,          'Tunai',    accountType, onTypeChanged),
                const SizedBox(width: 8),
                _typeChip('bank',    Icons.account_balance_outlined,   'Bank',     accountType, onTypeChanged),
                const SizedBox(width: 8),
                _typeChip('ewallet', Icons.phone_android_outlined,     'E-wallet', accountType, onTypeChanged),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Saldo awal ───────────────────────────────────────────────
            Text('Saldo awal', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppTheme.spacingXs),
            TextFormField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
              ),
              onChanged: (v) {
                final fmt = CurrencyFormatter.formatInput(v);
                if (fmt != v) {
                  balanceController.value = TextEditingValue(
                    text: fmt,
                    selection:
                        TextSelection.collapsed(offset: fmt.length),
                  );
                }
              },
            ),
            const SizedBox(height: AppTheme.spacingXl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                child: const Text('Lanjut'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(
    String value,
    IconData icon,
    String label,
    String selected,
    ValueChanged<String> onChange,
  ) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChange(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 0.8,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: isSelected
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Halaman 2: Atur rasio alokasi ────────────────────────────────────────────

class _RatioPage extends StatelessWidget {
  final double needs;
  final double savings;
  final double personal;
  final double total;
  final bool   isValid;
  final bool   isSaving;
  final ValueChanged<double> onNeedsChanged;
  final ValueChanged<double> onSavingsChanged;
  final ValueChanged<double> onPersonalChanged;
  final void Function(double n, double s, double p) onPreset;
  final VoidCallback onFinish;

  const _RatioPage({
    required this.needs,
    required this.savings,
    required this.personal,
    required this.total,
    required this.isValid,
    required this.isSaving,
    required this.onNeedsChanged,
    required this.onSavingsChanged,
    required this.onPersonalChanged,
    required this.onPreset,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingMd),
          Text('Atur alokasi keuangan',
              style: AppTextStyles.displayMedium),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Tentukan berapa persen income yang ideal untuk kebutuhan, '
            'tabungan, dan keperluan pribadi. Kamu bisa ubah ini kapan saja.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // ── Preset cepat ─────────────────────────────────────────────
          Text('Preset cepat', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppTheme.spacingXs),
          Row(
            children: [
              _PresetBtn(
                label: '50/30/20',
                sublabel: 'Populer',
                onTap: () => onPreset(50, 20, 30),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _PresetBtn(
                label: '60/20/20',
                sublabel: 'Konservatif',
                onTap: () => onPreset(60, 20, 20),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _PresetBtn(
                label: '40/30/30',
                sublabel: 'Agresif',
                onTap: () => onPreset(40, 30, 30),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // ── Sliders ──────────────────────────────────────────────────
          _SliderRow(
            label: 'Kebutuhan pokok',
            sublabel: 'Makan, transport, tagihan',
            value: needs,
            color: AppColors.primary,
            onChanged: onNeedsChanged,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _SliderRow(
            label: 'Tabungan',
            sublabel: 'Simpan untuk masa depan',
            value: savings,
            color: AppColors.income,
            onChanged: onSavingsChanged,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _SliderRow(
            label: 'Keperluan pribadi',
            sublabel: 'Hiburan, belanja, dll',
            value: personal,
            color: const Color(0xFF7C3AED),
            onChanged: onPersonalChanged,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // ── Total ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: isValid
                  ? AppColors.incomeSoft
                  : AppColors.expenseSoft,
              border: Border.all(
                color: isValid
                    ? AppColors.income.withValues(alpha: 0.35)
                    : AppColors.expense.withValues(alpha: 0.35),
                width: 1.0,
              ),
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total rasio',
                    style: AppTextStyles.labelMedium),
                Text(
                  '${total.toInt()}%',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isValid
                        ? AppColors.income
                        : AppColors.expense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // ── Tombol selesai ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isValid && !isSaving ? onFinish : null,
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Mulai pakai Saku'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slider row ───────────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.sublabel,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelMedium),
                Text(sublabel, style: AppTextStyles.labelSmall),
              ],
            ),
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
            activeTrackColor:   color,
            thumbColor:         color,
            inactiveTrackColor: AppColors.border,
            overlayColor:       color.withValues(alpha: 0.12),
            trackHeight:        4,
          ),
          child: Slider(
            value:     value,
            min:       5,
            max:       90,
            divisions: 17,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─── Preset button ────────────────────────────────────────────────────────────

class _PresetBtn extends StatelessWidget {
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _PresetBtn({
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingSm, horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border, width: 0.8),
            borderRadius:
                BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            children: [
              Text(label,
                  style: AppTextStyles.labelMedium,
                  textAlign: TextAlign.center),
              Text(sublabel,
                  style: AppTextStyles.labelSmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
