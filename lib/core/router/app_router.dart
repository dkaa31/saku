import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/transaction/presentation/add_transaction_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/recommendation/presentation/recommendation_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/category/presentation/category_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../database/app_database.dart';

class AppRouter {
  AppRouter._();

  static GoRouter router(AppDatabase db) {
    return GoRouter(
      // Selalu mulai dari splash — splash yang handle routing ke onboarding/home
      initialLocation: '/splash',
      routes: [
        // ── Splash ──────────────────────────────────────────────────────
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // ── Onboarding ───────────────────────────────────────────────────
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => OnboardingScreen(db: db),
        ),

        // ── Main shell (bottom nav) ──────────────────────────────────────
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => HomeScreen(db: db),
            ),
            GoRoute(
              path: '/report',
              builder: (context, state) => ReportScreen(db: db),
            ),
            GoRoute(
              path: '/accounts',
              builder: (context, state) => AccountScreen(db: db),
            ),
            GoRoute(
              path: '/recommendation',
              builder: (context, state) => RecommendationScreen(db: db),
            ),
          ],
        ),

        // ── Modal screens ────────────────────────────────────────────────
        GoRoute(
          path: '/add-transaction',
          builder: (context, state) => AddTransactionScreen(db: db),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => CategoryScreen(db: db),
        ),
      ],
    );
  }
}

// ─── Main Shell ───────────────────────────────────────────────────────────────

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/report'))          currentIndex = 1;
    if (location.startsWith('/recommendation'))  currentIndex = 2;
    if (location.startsWith('/accounts'))        currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0: context.go('/home');           break;
            case 1: context.go('/report');         break;
            case 2: context.go('/recommendation'); break;
            case 3: context.go('/accounts');       break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon:       Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.tips_and_updates_outlined),
            activeIcon: Icon(Icons.tips_and_updates_rounded),
            label: 'Alokasi',
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
