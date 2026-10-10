import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:svenska/core/constants/app_mode.dart';
import 'package:svenska/core/services/auth_service.dart';
import 'package:svenska/features/auth/presentation/login_page.dart';
import 'package:svenska/features/main/presentation/pages/backup_page.dart';
import 'package:svenska/injection.dart';
import 'package:svenska/features/main/presentation/pages/desktop_view_page.dart';
import 'package:svenska/features/main/presentation/pages/masters_page.dart';
import 'package:svenska/features/main/presentation/pages/reports_page.dart';
import 'package:svenska/features/main/presentation/pages/trial_expired_page.dart';
import 'package:svenska/features/main/presentation/pages/workstation_shell.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'routes_name.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        redirect: (context, state) {
          if (!kUseLocalDataStore) return AppRoutes.workstationMain;
          AuthService.ensureDefaultCredentials();
          if (sl<AuthService>().isLoggedIn()) return AppRoutes.workstationMain;
          return null;
        },
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        redirect: (context, state) {
          if (!kUseLocalDataStore) return null;
          AuthService.ensureDefaultCredentials();
          if (!sl<AuthService>().isLoggedIn()) return AppRoutes.login;
          return null;
        },
        builder: (context, state, child) => WorkstationShell(child: child),
        routes: [
          GoRoute(
            path: '/workstation/main',
            builder: (context, state) => const VehicleQRWorkstationPage(),
          ),
          GoRoute(
            path: '/workstation/masters',
            builder: (context, state) => const MastersPage(),
          ),
          GoRoute(
            path: '/workstation/transactions',
            redirect: (_, __) => AppRoutes.workstationMain,
          ),
          GoRoute(
            path: '/workstation/reports',
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: '/workstation/backup',
            builder: (context, state) => const BackupPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.desktopViewPage,
        redirect: (_, __) => AppRoutes.workstationMain,
      ),
      GoRoute(
        path: AppRoutes.trialExpiredPage,
        builder: (context, state) => const TrialExpiredPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
