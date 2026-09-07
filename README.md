<div align="center">

<img src="assets/images/logo.png" width="100" alt="Saku Logo"/>

# Saku

### *"Setiap rupiah ada tujuannya"*

Aplikasi manajemen keuangan personal untuk Android — catat pengeluaran, pantau budget, dan dapatkan rekomendasi alokasi otomatis.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://developer.android.com)

</div>

---

## Tentang Saku

Saku dirancang untuk mahasiswa dan anak kos yang ingin mulai mengelola keuangan secara sederhana namun terstruktur. Tidak perlu akun, tidak perlu internet — semua data tersimpan lokal di HP.

---

## Fitur

### Splash Screen & Onboarding
- Animasi splash screen dengan logo dan slogan
- Onboarding 3 langkah (hanya muncul saat install pertama): setup akun → atur rasio alokasi
- Setelah selesai langsung masuk ke beranda

### Multi-Akun / Dompet
- Tambah akun tunai, rekening bank, e-wallet, atau lainnya
- Setiap akun tampil dengan **warna unik** (8 warna berbeda berdasarkan urutan)
- Transfer antar akun dengan pencatatan otomatis
- Saldo terupdate otomatis setiap ada transaksi

### Kategori Kustom
- Buat kategori dengan **ikon** (36 pilihan) dan **warna** sendiri
- Preview real-time saat membuat/mengedit
- Set budget bulanan per kategori dengan progress bar
- Kelompokkan ke bucket *Kebutuhan / Tabungan / Pribadi* untuk analisis 50/30/20
- Alert in-app saat mendekati (≥80%) atau melebihi budget

### Catat Transaksi
- Input cepat: nominal → kategori → akun → tanggal → catatan
- Tab pemasukan / pengeluaran
- List transaksi dikelompokkan per tanggal dengan total harian

### Laporan (3 Tab)

**Ringkasan**
- Kartu surplus/defisit bulan ini
- Grafik tren income vs pengeluaran 6 bulan terakhir (bar chart interaktif)

**Kategori**
- Donut chart pengeluaran per kategori dengan warna sesuai setting
- Ranking top 5 kategori pengeluaran + perbandingan vs bulan lalu (%)

**Analisis**
- Saving rate visual dengan target 20%
- Perbandingan bulan ini vs bulan lalu (income & expense)
- Insight otomatis: saran singkat berdasarkan pola keuangan nyata

### Rekomendasi Alokasi 50/30/20
- Kalkulasi otomatis berbasis income bulan ini atau rata-rata 3 bulan
- Rasio dapat dikustomisasi (preset populer tersedia)
- Status per bucket: Hemat / On Track / Boros
- Penjelasan cara membaca rekomendasi

---

## Tech Stack

| Kategori | Teknologi |
|---|---|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| Database | SQLite via **Drift** (type-safe, reactive) |
| Navigasi | **go_router** (declarative, shell routes) |
| Grafik | **fl_chart** |
| State | `setState` + `StreamBuilder` |
| Local storage | **shared_preferences** |
| Font | Roboto (system font) |

---

## Struktur Proyek

```
lib/
├── main.dart                          # Entry point, error handler global
│
├── core/
│   ├── database/
│   │   ├── app_database.dart          # Schema Drift + seed data + migration
│   │   └── app_database.g.dart        # Generated — jangan edit manual
│   ├── router/
│   │   └── app_router.dart            # GoRouter + MainShell (bottom nav 4 tab)
│   ├── theme/
│   │   ├── app_colors.dart            # Token warna semantic (light & dark)
│   │   ├── app_text_styles.dart       # Skala tipografi
│   │   └── app_theme.dart             # ThemeData light (always light mode)
│   └── utils/
│       ├── category_ui_helper.dart    # Palet ikon & warna kategori
│       ├── currency_formatter.dart    # Format & parse Rupiah
│       └── date_formatter.dart        # Format tanggal (Indonesia)
│
└── features/
    ├── splash/
    │   └── presentation/
    │       └── splash_screen.dart     # Animasi logo → routing ke onboarding/home
    │
    ├── onboarding/
    │   └── presentation/
    │       └── onboarding_screen.dart # 3 langkah setup awal
    │
    ├── home/
    │   └── presentation/
    │       └── home_screen.dart       # Ringkasan saldo + list transaksi bulan ini
    │
    ├── account/
    │   ├── data/
    │   │   ├── account_repository.dart
    │   │   └── transfer_repository.dart
    │   └── presentation/
    │       ├── account_screen.dart
    │       ├── add_edit_account_screen.dart
    │       ├── transfer_screen.dart
    │       └── widgets/account_card.dart   # Kartu berwarna-warni per akun
    │
    ├── category/
    │   ├── data/category_repository.dart
    │   ├── domain/budget_alert_service.dart
    │   └── presentation/
    │       ├── category_screen.dart
    │       ├── add_edit_category_screen.dart  # Icon picker + color picker
    │       └── widgets/
    │           ├── category_budget_card.dart
    │           └── budget_alert_banner.dart
    │
    ├── transaction/
    │   ├── data/transaction_repository.dart
    │   └── presentation/
    │       ├── add_transaction_screen.dart
    │       └── widgets/
    │           ├── transaction_grouped_list.dart
    │           └── transaction_list_item.dart
    │
    ├── report/
    │   ├── data/report_repository.dart        # Kalkulasi laporan + insight otomatis
    │   └── presentation/
    │       ├── report_screen.dart             # 3 tab laporan
    │       └── widgets/
    │           ├── category_pie_chart.dart
    │           ├── monthly_bar_chart.dart
    │           ├── top_category_card.dart
    │           ├── month_comparison_card.dart
    │           └── insight_card.dart
    │
    └── recommendation/
        ├── domain/allocation_service.dart
        └── presentation/
            ├── recommendation_screen.dart
            ├── ratio_edit_screen.dart
            └── widgets/bucket_card.dart
```

---

## Cara Menjalankan

### Prasyarat

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.x
- Android Studio + Android SDK
- NDK 28.x (install via Android Studio → SDK Manager → SDK Tools → NDK Side by side)
- Device Android atau Emulator (API 21+)

### Setup

**1. Clone repo**
```bash
git clone https://github.com/username/saku.git
cd saku
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Generate kode database**

> File `app_database.g.dart` tidak di-commit ke repo — wajib dijalankan setelah clone.

```bash
dart run build_runner build
```

**4. Jalankan di device/emulator**
```bash
flutter run
```

**5. Jalankan di Windows (tanpa HP)**
```bash
flutter run -d windows
```

---

## Build APK

### Debug APK (untuk testing)
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (untuk distribusi)
```bash
flutter build apk --release --split-per-abi
```

Output 3 file di `build/app/outputs/flutter-apk/`:

| File | Arsitektur | Digunakan untuk |
|---|---|---|
| `app-arm64-v8a-release.apk` | 64-bit | **HP modern (2017+) — pakai ini** |
| `app-armeabi-v7a-release.apk` | 32-bit | HP lawas |
| `app-x86_64-release.apk` | x86 64-bit | Emulator |

### Cara install APK ke HP
1. Transfer APK ke HP (via USB, Google Drive, WhatsApp, dll)
2. Di HP: Settings → Biometrics & Security → **Install unknown apps** → aktifkan
3. Buka file APK → Install

---

## Database Schema

Drift (SQLite) dengan **schema version 2**.

| Tabel | Kolom utama | Keterangan |
|---|---|---|
| `accounts` | id, name, type, currentBalance | Akun/dompet user |
| `categories` | id, name, type, bucket, iconName, colorHex, budgetMonthly | Kategori dengan ikon & warna kustom |
| `transactions` | id, amount, type, categoryId, accountId, date, note | Pemasukan & pengeluaran |
| `transfers` | id, fromAccountId, toAccountId, amount, date | Transfer antar akun |
| `allocation_settings` | savingsRatio, needsRatio, personalRatio | Rasio 50/30/20 |

Migration otomatis dari v1 → v2 (menambah kolom `iconName` & `colorHex` ke categories).

---

## Catatan Teknis

- **Impeller dinonaktifkan** di `AndroidManifest.xml` (`EnableImpeller=false`) untuk kompatibilitas dengan beberapa device Samsung yang bermasalah dengan Vulkan renderer
- **Always light mode** — `ThemeMode.light` dipaksa agar tampilan konsisten di semua HP
- **Offline-first** — semua data tersimpan lokal, tidak butuh internet
- **No login required** — langsung pakai setelah install

---

## Dependencies

```yaml
# Runtime
go_router: ^18.0.1        # Navigasi deklaratif
drift: ^2.34.4            # ORM SQLite type-safe
drift_flutter: ^0.3.1     # SQLite adapter Flutter
fl_chart: ^1.2.0          # Pie chart & bar chart
intl: ^0.20.3             # Format tanggal Indonesia
shared_preferences: ^2.5.5 # Simpan flag onboarding

# Dev
drift_dev: ^2.34.6        # Code generator Drift
build_runner: ^2.16.1     # Runner code generation
```

---

## Lisensi

MIT License — bebas digunakan sebagai referensi atau template portofolio.

---

<div align="center">
Dibuat dengan Flutter · Portofolio project
</div>
