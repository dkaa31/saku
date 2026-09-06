import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_ui_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/category_repository.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final AppDatabase db;
  final Category? category;
  final String? initialType;

  const AddEditCategoryScreen({
    super.key,
    required this.db,
    this.category,
    this.initialType,
  });

  @override
  State<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState
    extends State<AddEditCategoryScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();

  late String _type;
  String? _bucket;
  bool _isSaving  = false;
  bool _hasBudget = false;

  // Icon & warna
  String _selectedIcon  = 'category';
  String _selectedColor = '#2563EB';

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final c = widget.category!;
      _nameController.text = c.name;
      _type                = c.type;
      _bucket              = c.bucket;
      _selectedIcon        = c.iconName;
      _selectedColor       = c.colorHex;
      if (c.budgetMonthly != null && c.budgetMonthly! > 0) {
        _hasBudget = true;
        _budgetController.text = CurrencyFormatter.formatInput(
            c.budgetMonthly!.toStringAsFixed(0));
      }
    } else {
      _type = widget.initialType ?? 'expense';
      // Pilih warna default sesuai tipe
      _selectedColor = _type == 'income' ? '#10B981' : '#2563EB';
      _selectedIcon  = _type == 'income' ? 'payments' : 'category';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Color get _accentColor => CategoryColors.fromHex(_selectedColor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit kategori' : 'Tambah kategori'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Preview ─────────────────────────────────────────────────
              _CategoryPreview(
                name:  _nameController.text.isEmpty
                    ? 'Nama kategori'
                    : _nameController.text,
                icon:  _selectedIcon,
                color: _selectedColor,
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Tipe ────────────────────────────────────────────────────
              if (!_isEdit) ...[
                Text('Tipe', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppTheme.spacingXs),
                _ToggleRow(
                  options: const [
                    _Option('expense', 'Pengeluaran'),
                    _Option('income',  'Pemasukan'),
                  ],
                  selected: _type,
                  accentColor: _accentColor,
                  onChanged: (v) => setState(() {
                    _type = v;
                    if (v == 'income') {
                      _bucket        = null;
                      _selectedColor = '#10B981';
                      _selectedIcon  = 'payments';
                    } else {
                      _selectedColor = '#2563EB';
                      _selectedIcon  = 'category';
                    }
                  }),
                ),
                const SizedBox(height: AppTheme.spacingLg),
              ],

              // ── Nama ────────────────────────────────────────────────────
              Text('Nama kategori', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppTheme.spacingXs),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    hintText: 'Contoh: Kopi, Bensin, Kos'),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Pilih ikon ───────────────────────────────────────────────
              Text('Ikon', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppTheme.spacingXs),
              _IconPicker(
                selected:   _selectedIcon,
                accentColor: _accentColor,
                onChanged:  (v) => setState(() => _selectedIcon = v),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Pilih warna ──────────────────────────────────────────────
              Text('Warna', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppTheme.spacingXs),
              _ColorPicker(
                selected:  _selectedColor,
                onChanged: (v) => setState(() => _selectedColor = v),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Bucket (hanya expense) ───────────────────────────────────
              if (_type == 'expense') ...[
                Text('Kelompok alokasi',
                    style: AppTextStyles.labelMedium),
                const SizedBox(height: 4),
                Text(
                  'Dipakai untuk menghitung rekomendasi 50/30/20',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                _ToggleRow(
                  options: const [
                    _Option('needs',    'Kebutuhan'),
                    _Option('savings',  'Tabungan'),
                    _Option('personal', 'Pribadi'),
                  ],
                  selected:    _bucket ?? '',
                  accentColor: _accentColor,
                  onChanged:   (v) => setState(() => _bucket = v),
                  allowDeselect: true,
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // ── Budget bulanan ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Budget bulanan',
                        style: AppTextStyles.labelMedium),
                    Switch(
                      value: _hasBudget,
                      activeThumbColor: _accentColor,
                      onChanged: (v) => setState(() {
                        _hasBudget = v;
                        if (!v) _budgetController.clear();
                      }),
                    ),
                  ],
                ),
                if (_hasBudget) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      hintText:   '0',
                    ),
                    onChanged: (v) {
                      final fmt = CurrencyFormatter.formatInput(v);
                      if (fmt != v) {
                        _budgetController.value = TextEditingValue(
                          text:      fmt,
                          selection: TextSelection.collapsed(
                              offset: fmt.length),
                        );
                      }
                    },
                    validator: (v) {
                      if (!_hasBudget) return null;
                      final amount =
                          CurrencyFormatter.parse(v ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Masukkan nominal budget yang valid';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: AppTheme.spacingLg),
              ],

              // ── Tombol simpan ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width:  20,
                          child:  CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEdit
                          ? 'Simpan perubahan'
                          : 'Tambah kategori'),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final repo   = CategoryRepository(widget.db);
    final name   = _nameController.text.trim();
    final budget = _hasBudget
        ? CurrencyFormatter.parse(_budgetController.text)
        : null;

    try {
      if (_isEdit) {
        await repo.update(
          id:           widget.category!.id,
          name:         name,
          bucket:       _bucket,
          budgetMonthly: budget,
          clearBudget:  !_hasBudget,
          iconName:     _selectedIcon,
          colorHex:     _selectedColor,
        );
      } else {
        await repo.create(
          name:         name,
          type:         _type,
          bucket:       _bucket,
          budgetMonthly: budget,
          iconName:     _selectedIcon,
          colorHex:     _selectedColor,
        );
      }
      if (mounted) Navigator.pop(context);
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

// ─── Preview ──────────────────────────────────────────────────────────────────

class _CategoryPreview extends StatelessWidget {
  final String name;
  final String icon;
  final String color;
  const _CategoryPreview(
      {required this.name, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = CategoryColors.fromHex(color);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            width:  48,
            height: 48,
            decoration: BoxDecoration(
              color:        c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              CategoryIcons.fromName(icon),
              color: c,
              size:  24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preview', style: AppTextStyles.labelSmall),
              Text(name,      style: AppTextStyles.bodyLarge
                  .copyWith(color: c, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Icon Picker ──────────────────────────────────────────────────────────────

class _IconPicker extends StatelessWidget {
  final String selected;
  final Color  accentColor;
  final ValueChanged<String> onChanged;

  const _IconPicker(
      {required this.selected,
      required this.accentColor,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        border:       Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Wrap(
        spacing:    AppTheme.spacingXs,
        runSpacing: AppTheme.spacingXs,
        children:   CategoryIcons.all.map((opt) {
          final isSelected = selected == opt.name;
          return GestureDetector(
            onTap: () => onChanged(opt.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width:  42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.transparent,
                  width: 1.5,
                ),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                opt.icon,
                size:  20,
                color: isSelected ? accentColor : AppColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Color Picker ─────────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ColorPicker(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing:    AppTheme.spacingSm,
      runSpacing: AppTheme.spacingSm,
      children:   CategoryColors.all.map((opt) {
        final isSelected = selected == opt.hex;
        final color      = CategoryColors.fromHex(opt.hex);
        return GestureDetector(
          onTap: () => onChanged(opt.hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color:  color,
              shape:  BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color:       color.withValues(alpha: 0.4),
                        blurRadius:  6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ─── Toggle Row ───────────────────────────────────────────────────────────────

class _Option {
  final String value;
  final String label;
  const _Option(this.value, this.label);
}

class _ToggleRow extends StatelessWidget {
  final List<_Option>        options;
  final String               selected;
  final Color                accentColor;
  final ValueChanged<String> onChanged;
  final bool                 allowDeselect;

  const _ToggleRow({
    required this.options,
    required this.selected,
    required this.accentColor,
    required this.onChanged,
    this.allowDeselect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt.value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                if (allowDeselect && isSelected) {
                  onChanged('');
                } else {
                  onChanged(opt.value);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.1)
                      : AppColors.surface,
                  border: Border.all(
                    color: isSelected ? accentColor : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Text(
                  opt.label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected
                        ? accentColor
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
