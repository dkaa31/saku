import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../data/category_repository.dart';
import 'add_edit_category_screen.dart';
import 'widgets/category_budget_card.dart';

class CategoryScreen extends StatefulWidget {
  final AppDatabase db;
  const CategoryScreen({super.key, required this.db});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = CategoryRepository(widget.db);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kategori'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: AppTextStyles.labelMedium,
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah kategori',
            onPressed: () => _openAddCategory(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryTab(
            db: widget.db,
            repo: repo,
            type: 'expense',
            year: now.year,
            month: now.month,
          ),
          _CategoryTab(
            db: widget.db,
            repo: repo,
            type: 'income',
            year: now.year,
            month: now.month,
          ),
        ],
      ),
    );
  }

  void _openAddCategory(BuildContext context) {
    final type =
        _tabController.index == 0 ? 'expense' : 'income';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditCategoryScreen(
          db: widget.db,
          initialType: type,
        ),
      ),
    );
  }
}

// ─── Tab konten per tipe ──────────────────────────────────────────────────────

class _CategoryTab extends StatelessWidget {
  final AppDatabase db;
  final CategoryRepository repo;
  final String type;
  final int year;
  final int month;

  const _CategoryTab({
    required this.db,
    required this.repo,
    required this.type,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Category>>(
      stream: repo.watchByType(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return _EmptyState(
            onAdd: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditCategoryScreen(
                  db: db,
                  initialType: type,
                ),
              ),
            ),
          );
        }

        return FutureBuilder<Map<int, double>>(
          future: repo.getSpendingByCategory(year: year, month: month),
          builder: (context, spendSnap) {
            final spending = spendSnap.data ?? {};

            return ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              itemCount: categories.length,
              separatorBuilder: (_, i) =>
                  const SizedBox(height: AppTheme.spacingSm),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return CategoryBudgetCard(
                  category: cat,
                  spent: spending[cat.id] ?? 0.0,
                  showBudget: type == 'expense',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditCategoryScreen(
                        db: db,
                        category: cat,
                      ),
                    ),
                  ),
                  onDelete: () => _confirmDelete(context, cat),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Category cat) async {
    final canDelete = await repo.canDelete(cat.id);

    if (!context.mounted) return;

    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Kategori tidak bisa dihapus karena masih digunakan transaksi.'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kategori'),
        content: Text(
            'Hapus "${cat.name}"? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await repo.delete(cat.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.category_outlined,
                size: 56, color: AppColors.textDisabled),
            const SizedBox(height: AppTheme.spacingMd),
            Text('Belum ada kategori',
                style: AppTextStyles.headingMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Tambahkan kategori untuk mengelompokkan transaksimu.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah kategori'),
            ),
          ],
        ),
      ),
    );
  }
}
