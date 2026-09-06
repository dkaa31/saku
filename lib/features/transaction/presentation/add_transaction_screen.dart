import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../account/data/account_repository.dart';
import '../../category/data/category_repository.dart';
import '../data/transaction_repository.dart';

class AddTransactionScreen extends StatefulWidget {
  final AppDatabase db;
  final Transaction? transaction; // null = tambah, non-null = edit

  const AddTransactionScreen({super.key, required this.db, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _noteController   = TextEditingController();

  late TabController _typeTab;
  List<Category> _categories = [];
  List<Account>  _accounts   = [];

  Category? _selectedCategory;
  Account?  _selectedAccount;
  DateTime  _date    = DateTime.now();
  bool      _isSaving = false;

  bool get _isEdit => widget.transaction != null;
  String get _type => _typeTab.index == 0 ? 'expense' : 'income';

  @override
  void initState() {
    super.initState();
    _typeTab = TabController(length: 2, vsync: this)
      ..addListener(_onTypeChanged);
    _loadData();
  }

  Future<void> _loadData() async {
    final catRepo  = CategoryRepository(widget.db);
    final accRepo  = AccountRepository(widget.db);
    final cats     = await catRepo.getAll();
    final accounts = await accRepo.getAllAccounts();

    if (!mounted) return;

    // Jika edit, pre-fill semua field
    if (_isEdit) {
      final tx = widget.transaction!;
      _amountController.text =
          CurrencyFormatter.formatInput(tx.amount.toStringAsFixed(0));
      _noteController.text = tx.note ?? '';
      _date = tx.date;

      final tabIdx = tx.type == 'expense' ? 0 : 1;
      _typeTab.animateTo(tabIdx);

      final filtered =
          cats.where((c) => c.type == tx.type).toList();
      setState(() {
        _categories      = filtered;
        _accounts        = accounts;
        _selectedCategory =
            cats.firstWhere((c) => c.id == tx.categoryId,
                orElse: () => cats.first);
        _selectedAccount =
            accounts.firstWhere((a) => a.id == tx.accountId,
                orElse: () => accounts.first);
      });
    } else {
      final expCats =
          cats.where((c) => c.type == 'expense').toList();
      setState(() {
        _categories      = expCats;
        _accounts        = accounts;
        _selectedAccount =
            accounts.isNotEmpty ? accounts.first : null;
      });
    }
  }

  void _onTypeChanged() {
    if (!mounted) return;
    final type     = _type;
    final filtered = <Category>[];

    CategoryRepository(widget.db).getByType(type).then((cats) {
      if (!mounted) return;
      setState(() {
        _categories       = cats;
        _selectedCategory = cats.isNotEmpty ? cats.first : null;
      });
    });
    setState(() => _categories = filtered);
  }

  @override
  void dispose() {
    _typeTab.removeListener(_onTypeChanged);
    _typeTab.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit transaksi' : 'Catat transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Tab income / expense ─────────────────────────────────────────
          if (!_isEdit)
            _TypeTabBar(controller: _typeTab),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Input jumlah (paling menonjol) ─────────────────────
                  _AmountInput(controller: _amountController),
                  const SizedBox(height: AppTheme.spacingLg),

                  // ── Kategori ───────────────────────────────────────────
                  Text('Kategori', style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppTheme.spacingXs),
                  _CategoryGrid(
                    categories: _categories,
                    selected: _selectedCategory,
                    onSelected: (c) =>
                        setState(() => _selectedCategory = c),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // ── Akun ───────────────────────────────────────────────
                  Text('Akun', style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppTheme.spacingXs),
                  _AccountSelector(
                    accounts: _accounts,
                    selected: _selectedAccount,
                    onChanged: (a) =>
                        setState(() => _selectedAccount = a),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // ── Tanggal ────────────────────────────────────────────
                  Text('Tanggal', style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppTheme.spacingXs),
                  _DatePickerField(
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
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Tambahkan catatan...',
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
                                  color: Colors.white),
                            )
                          : Text(_isEdit
                              ? 'Simpan perubahan'
                              : 'Simpan transaksi'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amountRaw = CurrencyFormatter.parse(_amountController.text);
    if (amountRaw == null || amountRaw <= 0) {
      _showError('Masukkan jumlah yang valid');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Pilih kategori terlebih dahulu');
      return;
    }
    if (_selectedAccount == null) {
      _showError('Pilih akun terlebih dahulu');
      return;
    }

    setState(() => _isSaving = true);
    final repo = TransactionRepository(widget.db);
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    try {
      if (_isEdit) {
        await repo.update(
          id:         widget.transaction!.id,
          amount:     amountRaw,
          type:       _type,
          categoryId: _selectedCategory!.id,
          accountId:  _selectedAccount!.id,
          date:       _date,
          note:       note,
        );
      } else {
        await repo.create(
          amount:     amountRaw,
          type:       _type,
          categoryId: _selectedCategory!.id,
          accountId:  _selectedAccount!.id,
          date:       _date,
          note:       note,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.expense,
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _TypeTabBar extends StatelessWidget {
  final TabController controller;
  const _TypeTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: controller,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          color: controller.index == 0
              ? AppColors.expense
              : AppColors.income,
        ),
        labelStyle: AppTextStyles.labelMedium,
        tabs: const [
          Tab(text: 'Pengeluaran'),
          Tab(text: 'Pemasukan'),
        ],
      ),
    );
  }
}

class _AmountInput extends StatelessWidget {
  final TextEditingController controller;
  const _AmountInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            'Rp',
            style: AppTextStyles.amountLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.amountLarge,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '0',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) {
                final fmt = CurrencyFormatter.formatInput(v);
                if (fmt != v) {
                  controller.value = TextEditingValue(
                    text: fmt,
                    selection:
                        TextSelection.collapsed(offset: fmt.length),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category> onSelected;

  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Text(
        'Belum ada kategori. Tambahkan dulu di menu Kategori.',
        style: AppTextStyles.bodySmall,
      );
    }

    return Wrap(
      spacing: AppTheme.spacingXs,
      runSpacing: AppTheme.spacingXs,
      children: categories.map((cat) {
        final isSelected = selected?.id == cat.id;
        return GestureDetector(
          onTap: () => onSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border,
                width: isSelected ? 1.5 : 0.8,
              ),
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              cat.name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimary,
                fontWeight: isSelected
                    ? FontWeight.w500
                    : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AccountSelector extends StatelessWidget {
  final List<Account> accounts;
  final Account? selected;
  final ValueChanged<Account?> onChanged;

  const _AccountSelector({
    required this.accounts,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Text(
        'Belum ada akun. Tambahkan dulu di menu Akun.',
        style: AppTextStyles.bodySmall,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 0.8),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Account>(
          value: accounts.contains(selected) ? selected : null,
          isExpanded: true,
          hint: Text('Pilih akun',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textDisabled)),
          items: accounts
              .map((a) => DropdownMenuItem(
                    value: a,
                    child: Row(
                      children: [
                        Icon(_accountIcon(a.type),
                            size: 16,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(a.name,
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  IconData _accountIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance_outlined;
      case 'ewallet':
        return Icons.phone_android_outlined;
      default:
        return Icons.payments_outlined;
    }
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField(
      {required this.date, required this.onChanged});

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
