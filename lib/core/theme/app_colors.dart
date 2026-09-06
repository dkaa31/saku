import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  /// Biru utama — tombol, link, aksen navigasi
  static const Color primary = Color(0xFF2563EB);

  /// Biru muda — chip, badge sekunder
  static const Color primarySoft = Color(0xFFEFF6FF);

  /// Hijau — income, tabungan, positif
  static const Color income = Color(0xFF059669);

  /// Hijau muda — latar icon income
  static const Color incomeSoft = Color(0xFFECFDF5);

  /// Merah — expense, over-budget, bahaya
  static const Color expense = Color(0xFFDC2626);

  /// Merah muda — latar icon expense
  static const Color expenseSoft = Color(0xFFFEF2F2);

  /// Kuning — warning, mendekati batas
  static const Color warning = Color(0xFFD97706);

  /// Kuning muda — latar warning
  static const Color warningSoft = Color(0xFFFFFBEB);

  // ── Neutral – Light mode ───────────────────────────────────────────────────
  /// Latar utama halaman
  static const Color background = Color(0xFFF8FAFC);

  /// Latar kartu / surface
  static const Color surface = Color(0xFFFFFFFF);

  /// Border / divider
  static const Color border = Color(0xFFE2E8F0);

  /// Teks utama — heading, label penting
  static const Color textPrimary = Color(0xFF0F172A);

  /// Teks sekunder — keterangan, placeholder
  static const Color textSecondary = Color(0xFF475569);

  /// Teks non-aktif / disabled
  static const Color textDisabled = Color(0xFF94A3B8);

  // ── Neutral – Dark mode ───────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark    = Color(0xFF1E293B);
  static const Color borderDark     = Color(0xFF334155);
  static const Color textPrimaryDark    = Color(0xFFF8FAFC);
  static const Color textSecondaryDark  = Color(0xFF94A3B8);

  // ── Alias untuk backward-compat ───────────────────────────────────────────
  static const Color accent  = income;
  static const Color danger  = expense;
  static const Color secondary = Color(0xFF3B82F6);
}
