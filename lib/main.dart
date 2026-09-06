import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/database/app_database.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  final db = AppDatabase();

  runApp(SakuApp(db: db));
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
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router(db),
    );
  }
}
