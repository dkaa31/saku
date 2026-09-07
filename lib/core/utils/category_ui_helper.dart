import 'package:flutter/material.dart';

// ─── Icon option model ────────────────────────────────────────────────────────

class CategoryIconOption {
  final String name;
  final IconData icon;
  final String label;
  const CategoryIconOption(this.name, this.icon, this.label);
}

// ─── Color option model ───────────────────────────────────────────────────────

class CategoryColorOption {
  final String hex;
  final String label;
  const CategoryColorOption(this.hex, this.label);
}

// ─── Icons ────────────────────────────────────────────────────────────────────

/// Daftar ikon yang bisa dipilih user untuk kategori
class CategoryIcons {
  CategoryIcons._();

  static const List<CategoryIconOption> all = [
    // Makanan & minuman
    CategoryIconOption('restaurant',          Icons.restaurant,            'Restoran'),
    CategoryIconOption('coffee',              Icons.coffee,                'Kopi'),
    CategoryIconOption('fastfood',            Icons.fastfood,              'Fastfood'),
    CategoryIconOption('local_grocery_store', Icons.local_grocery_store,   'Groceries'),
    // Transport
    CategoryIconOption('directions_car',      Icons.directions_car,        'Mobil'),
    CategoryIconOption('directions_bus',      Icons.directions_bus,        'Bus'),
    CategoryIconOption('motorcycle',          Icons.motorcycle,            'Motor'),
    CategoryIconOption('train',               Icons.train,                 'KRL'),
    // Tagihan & rumah
    CategoryIconOption('home',                Icons.home,                  'Rumah'),
    CategoryIconOption('receipt_long',        Icons.receipt_long,          'Tagihan'),
    CategoryIconOption('bolt',                Icons.bolt,                  'Listrik'),
    CategoryIconOption('water_drop',          Icons.water_drop,            'Air'),
    CategoryIconOption('wifi',                Icons.wifi,                  'Internet'),
    CategoryIconOption('phone_android',       Icons.phone_android,         'Pulsa'),
    // Belanja
    CategoryIconOption('shopping_bag',        Icons.shopping_bag,          'Belanja'),
    CategoryIconOption('checkroom',           Icons.checkroom,             'Pakaian'),
    // Hiburan & gaya hidup
    CategoryIconOption('movie',               Icons.movie,                 'Film'),
    CategoryIconOption('sports_esports',      Icons.sports_esports,        'Game'),
    CategoryIconOption('fitness_center',      Icons.fitness_center,        'Gym'),
    CategoryIconOption('music_note',          Icons.music_note,            'Musik'),
    CategoryIconOption('travel_explore',      Icons.travel_explore,        'Jalan-jalan'),
    // Kesehatan
    CategoryIconOption('health_and_safety',   Icons.health_and_safety,     'Kesehatan'),
    CategoryIconOption('local_hospital',      Icons.local_hospital,        'RS/Klinik'),
    CategoryIconOption('medication',          Icons.medication,            'Obat'),
    // Pendidikan
    CategoryIconOption('school',              Icons.school,                'Pendidikan'),
    CategoryIconOption('menu_book',           Icons.menu_book,             'Buku'),
    // Keuangan
    CategoryIconOption('savings',             Icons.savings,               'Tabungan'),
    CategoryIconOption('account_balance',     Icons.account_balance,       'Bank'),
    CategoryIconOption('payments',            Icons.payments,              'Cash'),
    // Pemasukan
    CategoryIconOption('work',                Icons.work,                  'Kerja'),
    CategoryIconOption('wallet',              Icons.wallet,                'Dompet'),
    CategoryIconOption('store',               Icons.store,                 'Bisnis'),
    CategoryIconOption('card_giftcard',       Icons.card_giftcard,         'Hadiah'),
    // Lainnya
    CategoryIconOption('more_horiz',          Icons.more_horiz,            'Lainnya'),
    CategoryIconOption('category',            Icons.category,              'Kategori'),
    CategoryIconOption('add_circle',          Icons.add_circle,            'Tambahan'),
  ];

  static IconData fromName(String name) {
    final match = all.where((o) => o.name == name).firstOrNull;
    return match?.icon ?? Icons.category;
  }
}

// ─── Colors ───────────────────────────────────────────────────────────────────

/// Daftar warna yang bisa dipilih user
class CategoryColors {
  CategoryColors._();

  static const List<CategoryColorOption> all = [
    CategoryColorOption('#EF4444', 'Merah'),
    CategoryColorOption('#F97316', 'Oranye'),
    CategoryColorOption('#F59E0B', 'Kuning'),
    CategoryColorOption('#10B981', 'Hijau'),
    CategoryColorOption('#06B6D4', 'Cyan'),
    CategoryColorOption('#0EA5E9', 'Biru Muda'),
    CategoryColorOption('#2563EB', 'Biru'),
    CategoryColorOption('#6366F1', 'Indigo'),
    CategoryColorOption('#8B5CF6', 'Ungu'),
    CategoryColorOption('#EC4899', 'Pink'),
    CategoryColorOption('#14B8A6', 'Teal'),
    CategoryColorOption('#64748B', 'Abu'),
    CategoryColorOption('#94A3B8', 'Abu Muda'),
    CategoryColorOption('#1E293B', 'Hitam'),
  ];

  static Color fromHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }

  static String toHex(Color color) {
    final argb = color.toARGB32();
    final hex  = (argb & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    return '#$hex';
  }
}
