import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/account_repository.dart';
import '../data/transfer_repository.dart';

class TransferScreen extends StatefulWidget {
  final AppDatabase db;
  const TransferScreen({super.key, required this.db});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  List<Account> _accounts = [];
  Account? _fromAccount;
  Account? _toAccount;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final repo = AccountRepository(widget.db);
    final accounts = await repo.getAllAccounts();
    setState(() {
      _accounts = accounts;
      if (accounts.length >= 2) {
        _fromAccount = accounts[0];
        _toAccount = accounts[1];
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transfer antar akun'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _accounts.length < 2
          ? _NotEnoughAccounts()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Dari & ke akun ─────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _AccountDropdown(
                            label: 'Dari',
                            accounts: _accounts,
                            selected: _fromAccount,
                            exclude: _toAccount,
                            onChanged: (a) =>
                                setState(() => _fromAccount = a),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSm),
                          child: Icon(
                            Icons.arrow_forward,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: _AccountDropdown(
                            label: 'Ke',
                            accounts: _accounts,
                            selected: _toAccount,
                            exclude: _fromAccount,
                            onChanged: (a) =>
                                setState(() => _toAccount = a),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Jumlah ─────────────────────────────────────────────
                    Text('Jumlah', style: AppTextStyles.labelMedium),
                    const SizedBox(height: AppTheme.spacingXs),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                      onChanged: (v) {
                        final formatted =
                            CurrencyFormatter.formatInput(v);
                        if (formatted != v) {
                          _amountController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                                offset: formatted.length),
                          );
                        }
                      },
                      validator: (v) {
                        final amount = CurrencyFormatter.parse(v ?? '');
                        if (amount == null || amount <= 0) {
                          return 'Masukkan jumlah yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Tanggal ────────────────────────────────────────────
                    Text('Tanggal', style: AppTextStyles.labelMedium),
                    const SizedBox(height: AppTheme.spacingXs),
                    _DatePicker(
                      date: _date,
                      onChanged: (d) => setState(() => _date = d),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Catatan ────────────────────────────────────────────
                    Text('Catatan (opsional)',
                        style: AppTextStyles.labelMedium),
                    const SizedBox(height: AppTheme.spacingXs),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: tarik tunai ATM',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // ── Tombol simpan ──────────────────────────────────────
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
                            : const Text('Proses transfer'),
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
    if (_fromAccount == null || _toAccount == null) return;
    if (_fromAccount!.id == _toAccount!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun asal dan tujuan tidak boleh sama.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = TransferRepository(widget.db);
      final amount =
          CurrencyFormatter.parse(_amountController.text) ?? 0.0;
      await repo.createTransfer(
        fromAccountId: _fromAccount!.id,
        toAccountId: _toAccount!.id,
        amount: amount,
        date: _date,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal transfer: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _NotEnoughAccounts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingXl),
        child: Text(
          'Kamu perlu minimal 2 akun untuk melakukan transfer.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final String label;
  final List<Account> accounts;
  final Account? selected;
  final Account? exclude;
  final ValueChanged<Account?> onChanged;

  const _AccountDropdown({
    required this.label,
    required this.accounts,
    required this.selected,
    required this.exclude,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = accounts.where((a) => a.id != exclude?.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: AppTheme.spacingXs),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border:
                Border.all(color: AppColors.border, width: 0.8),
            borderRadius:
                BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Account>(
              value: filtered.contains(selected) ? selected : null,
              isExpanded: true,
              hint: Text('Pilih akun',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDisabled)),
              items: filtered
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(a.name,
                          style: AppTextStyles.bodyMedium,
                          overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePicker({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 0.8),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              DateFormatter.formatRelative(date),
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
