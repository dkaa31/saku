# 💰 Saku — Manajemen Keuangan Personal

> **"Setiap rupiah ada tujuannya"**

Saku adalah aplikasi manajemen keuangan personal berbasis mobile yang dibangun dengan Flutter. Dirancang khusus untuk mahasiswa dan anak kos yang ingin mulai mengelola keuangan dengan cara yang mudah, visual, dan terstruktur.

---

## 📱 Tampilan

| Splash | Beranda | Laporan | Rekomendasi |
|--------|---------|---------|-------------|
| Logo + animasi masuk | Ringkasan saldo & transaksi | Pie chart, bar chart, analisis | Alokasi 50/30/20 |

---

## ✨ Fitur Utama

### 🏦 Multi-Akun / Dompet
- Tambah akun tunai, rekening bank, atau e-wallet
- Transfer antar akun dengan satu tap
- Saldo otomatis terupdate setiap transaksi

### 🏷️ Kategori Kustom
- Buat kategori dengan **ikon** (36 pilihan) dan **warna** sendiri
- Set budget bulanan per kategori
- Pengelompokan ke bucket *Kebutuhan / Tabungan / Pribadi* untuk analisis 50/30/20
- Notifikasi in-app saat mendekati atau melebihi budget

### 💸 Catat Transaksi
- Input cepat: nominal → kategori → akun → tanggal
- Tab pemasukan / pengeluaran
- Catatan opsional per transaksi
- List transaksi dikelompokkan per tanggal

### 📊 Laporan & Analisis (3 Tab)
**Tab Ringkasan**
- Kartu surplus/defisit bulan ini
- Grafik tren income vs pengeluaran 6 bulan

**Tab Kategori**
- Donut chart interaktif pengeluaran per kategori (warna sesuai kustom)
- Ranking top 5 pengeluaran + perbandingan vs bulan lalu (%)

**Tab Analisis**
- Saving rate bulan ini dengan visual progress bar dan target 20%
- Perbandingan lengkap bulan ini vs bulan lalu (income & expense)
- Insight otomatis: saran berdasarkan pola keuangan nyata

### 🎯 Rekomendasi Alokasi
- Kalkulasi otomatis berbasis metode **50/30/20**
- Rasio bisa disesuaikan (preset populer tersedia)
- Analisis per bucket: Hemat / On Track / Boros
- Menggunakan rata-rata 3 bulan jika income bulan ini belum ada

### 🚀 Onboarding
- 3 langkah: Welcome → Buat akun pertama → Atur rasio alokasi
- Hanya muncul sekali saat install pertama

### 🎨 Desain
- Splash screen dengan animasi logo + slogan
- Light & Dark mode otomatis (ikut sistem)
- Tipografi: **Inter** via Google Fonts
- Warna: Royal Blue (`#2563EB`) sebagai primary

---

## 🛠️ Tech Stack

| Kategori | Teknologi |
|----------|-----------|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| Database | SQLite via **Drift** (type-safe ORM) |
| Navigasi | **go_router** |
| Grafik | **fl_chart** |
| Font | **Google Fonts** (Inter) |
| State | `setState` + `StreamBuilder` |
| Lokal Storage | **shared_preferences** |

---

## 🏗️ Struktur Proyek

```
lib/
├── core/
│   ├── database/
│   │   ├── app_database.dart       # Schema Drift (Accounts, Categories, Transactions, dll)
│   │   └── app_database.g.dart     # Generated — jangan edit manual
│   ├── router/
│   │   └── app_router.dart         # GoRouter + MainShell (bottom nav)
│   ├── theme/
│   │   ├── app_colors.dart         # Semua token warna (semantic)
│   │   ├── app_text_styles.dart    # Skala tipografi
│   │   └── app_theme.dart          # ThemeData light & dark
│   └── utils/
│       ├── category_ui_helper.dart # Daftar ikon & warna kategori
│       ├── currency_formatter.dart # Format & parse Rupiah
│       └── date_formatter.dart     # Format tanggal Indonesia
│
├── features/
│   ├── splash/
│   │   └── presentation/
│   │       └── splash_screen.dart  # Animasi logo + routing awal
│   ├── onboarding/
│   │   └── presentation/
│   │       └── onboarding_screen.dart
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart    # Ringkasan bulan + list transaksi
│   ├── account/
│   │   ├── data/
│   │   │   ├── account_repository.dart
│   │   │   └── transfer_repository.dart
│   │   └── presentation/
│   │       ├── account_screen.dart
│   │       ├── add_edit_account_screen.dart
│   │       ├── transfer_screen.dart
│   │       └── widgets/account_card.dart
│   ├── category/
│   │   ├── data/category_repository.dart
│   │   ├── domain/budget_alert_service.dart
│   │   └── presentation/
│   │       ├── category_screen.dart
│   │       ├── add_edit_category_screen.dart  # Icon & color picker
│   │       └── widgets/
│   │           ├── category_budget_card.dart
│   │           └── budget_alert_banner.dart
│   ├── transaction/
│   │   ├── data/transaction_repository.dart
│   │   └── presentation/
│   │       ├── add_transaction_screen.dart
│   │       └── widgets/
│   │           ├── transaction_list_item.dart
│   │           └── transaction_grouped_list.dart
│   ├── report/
│   │   ├── data/report_repository.dart        # Semua kalkulasi laporan & insight
│   │   └── presentation/
│   │       ├── report_screen.dart             # 3 tab: Ringkasan, Kategori, Analisis
│   │       └── widgets/
│   │           ├── category_pie_chart.dart
│   │           ├── monthly_bar_chart.dart
│   │           ├── top_category_card.dart
│   │           ├── month_comparison_card.dart
│   │           └── insight_card.dart
│   └── recommendation/
│       ├── domain/allocation_service.dart
│       └── presentation/
│           ├── recommendation_screen.dart
│           ├── ratio_edit_screen.dart
│           └── widgets/bucket_card.dart
│
assets/
└── images/
    └── logo.png
```

---

## 🚀 Cara Menjalankan

### Prasyarat
- [Flutter SDK](https://flutter.dev/docs/get-started/install) versi 3.x ke atas
- Android Studio atau VS Code
- Android Emulator atau perangkat fisik (Android 6.0+)

### Langkah Setup

**1. Clone repositori**
```bash
git clone https://github.com/username/saku.git
cd saku
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Generate kode database (Drift)**
```bash
dart run build_runner build
```

> File `app_database.g.dart` tidak di-commit ke repo. Wajib dijalankan setelah clone.

**4. Jalankan aplikasi**
```bash
# Di emulator/device Android
flutter run

# Di Windows (desktop)
flutter run -d windows
```

**5. Build APK**
```bash
# Debug APK
flutter build apk --debug

# Release APK (butuh signing config)
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-debug.apk`

---

## 🗄️ Database Schema

Menggunakan **Drift** (SQLite) dengan schema version 2.

| Tabel | Keterangan |
|-------|-----------|
| `accounts` | Akun/dompet user (tunai, bank, e-wallet) |
| `categories` | Kategori transaksi dengan ikon, warna, dan bucket alokasi |
| `transactions` | Catatan pemasukan & pengeluaran |
| `transfers` | Transfer antar akun |
| `allocation_settings` | Rasio 50/30/20 yang bisa dikustomisasi |

Migration otomatis berjalan saat schema version naik.

---

## 📦 Dependencies

```yaml
# Runtime
go_router: ^18.0.1        # Navigasi deklaratif
drift: ^2.34.4             # ORM SQLite type-safe
drift_flutter: ^0.3.1      # Adapter Drift untuk Flutter
fl_chart: ^1.2.0           # Grafik (pie chart, bar chart)
google_fonts: ^8.2.1       # Inter font
intl: ^0.20.3              # Format tanggal Indonesia
shared_preferences: ^2.5.5 # Simpan status onboarding

# Dev
drift_dev: ^2.34.6         # Code generator Drift
build_runner: ^2.16.1      # Runner code generation
```

---

## 🔄 Alur Aplikasi

```
Buka App
    └─► Splash Screen (2.6 detik)
            ├─► [Pertama kali] Onboarding
            │       ├─► Buat akun pertama
            │       └─► Set rasio alokasi
            └─► [Sudah pernah] Home
                    ├─► Catat Transaksi (FAB)
                    ├─► Laporan (Tab)
                    │       ├─► Ringkasan bulan
                    │       ├─► Analisis kategori
                    │       └─► Insight otomatis
                    ├─► Rekomendasi Alokasi (Tab)
                    └─► Kelola Akun (Tab)
```

---

## 🧑‍💻 Tentang Proyek

Proyek ini dibuat sebagai **portofolio pengembangan mobile** dengan Flutter, menampilkan:

- Arsitektur **feature-first** yang terstruktur
- Database lokal dengan **Drift** (type-safe, reactive streams)
- Navigasi modern dengan **GoRouter** (deep link, shell routes)
- Sistem desain konsisten (token warna, tipografi, spacing)
- Animasi UI yang smooth (splash, loading states, transitions)
- Analisis keuangan berbasis data nyata

---

## 📄 Lisensi

MIT License — bebas digunakan sebagai referensi atau template.

---

*Dibuat dengan ❤️ menggunakan Flutter*
