import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/account_repository.dart';

class AddEditAccountScreen extends StatefulWidget {
  final AppDatabase db;
  final Account? account; // null = tambah baru, non-null = edit

  const AddEditAccountScreen({super.key, required this.db, this.account});

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  String _selectedType = 'cash';
  bool _isSaving = false;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final a = widget.account!;
      _nameController.text = a.name;
      _selectedType = a.type;
      // Edit: tampilkan current balance
      _balanceController.text =
          CurrencyFormatter.formatInput(a.currentBalance.toStringAsFixed(0));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit akun' : 'Tambah akun'),
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
              // ── Nama akun ──────────────────────────────────────────────────
              Text('Nama akun', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppTheme.spacingXs),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Contoh: BCA, GoPay, Dompet',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nama akun tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Tipe akun ──────────────────────────────────────────────────
              Text('Jenis akun', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppTheme.spacingXs),
              _AccountTypeSelector(
                selected: _selectedType,
                onChanged: (t) => setState(() => _selectedType = t),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Saldo awal / saldo saat ini ────────────────────────────────
              Text(
                _isEdit ? 'Saldo saat ini' : 'Saldo awal',
                style: AppTextStyles.labelMedium,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '0',
                ),
                onChanged: (v) {
                  final formatted = CurrencyFormatter.formatInput(v);
                  if (formatted != v) {
                    _balanceController.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // boleh 0
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // ── Tombol simpan ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEdit ? 'Simpan perubahan' : 'Tambah akun'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final repo = AccountRepository(widget.db);
    final name = _nameController.text.trim();
    final balance =
        CurrencyFormatter.parse(_balanceController.text) ?? 0.0;

    try {
      if (_isEdit) {
        await repo.updateAccount(
          id: widget.account!.id,
          name: name,
          type: _selectedType,
          currentBalance: balance,
        );
      } else {
        await repo.createAccount(
          name: name,
          type: _selectedType,
          initialBalance: balance,
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

// ─── Account type selector ────────────────────────────────────────────────────

class _AccountTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _AccountTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _types = [
    _TypeOption('cash', Icons.payments_outlined, 'Tunai'),
    _TypeOption('bank', Icons.account_balance_outlined, 'Bank'),
    _TypeOption('ewallet', Icons.phone_android_outlined, 'E-wallet'),
    _TypeOption('other', Icons.category_outlined, 'Lainnya'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _types
          .map(
            (t) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacingXs),
                child: _TypeChip(
                  option: t,
                  isSelected: selected == t.value,
                  onTap: () => onChanged(t.value),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TypeOption {
  final String value;
  final IconData icon;
  final String label;
  const _TypeOption(this.value, this.icon, this.label);
}

class _TypeChip extends StatelessWidget {
  final _TypeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          border: Border.all(
            color:
                isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              size: 20,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              option.label,
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
    );
  }
}
