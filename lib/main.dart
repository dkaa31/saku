import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/database/app_database.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Wrap seluruh app dalam zone error handler
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        // Tampilkan error screen daripada crash diam-diam
        _runErrorApp(details.exceptionAsString());
      };

      try {
        await initializeDateFormatting('id_ID', null);
      } catch (_) {
        // Jika locale gagal load, lanjutkan saja
      }

      late AppDatabase db;
      try {
        db = AppDatabase();
      } catch (e) {
        _runErrorApp('Database gagal dibuka: $e');
        return;
      }

      runApp(SakuApp(db: db));
    },
    (error, stack) {
      // Tangkap uncaught async errors
      _runErrorApp(error.toString());
    },
  );
}

void _runErrorApp(String message) {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: Color(0xFFDC2626)),
              const SizedBox(height: 16),
              const Text(
                'Saku gagal memuat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Coba uninstall lalu install ulang aplikasi.',
                style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Tampilkan pesan error untuk debug
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDC2626)),
                ),
                child: SelectableText(
                  message,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7F1D1D),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ));
}

class SakuApp extends StatelessWidget {
  final AppDatabase db;
  const SakuApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Saku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light, // selalu light mode, tidak ikut dark mode sistem
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router(db),
    );
  }
}
