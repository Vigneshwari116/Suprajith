import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:svenska/features/main/presentation/pages/desktop_view_page.dart';
import '../../core/utils/routes_name.dart';
import '../../features/main/presentation/pages/trial_expired_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,

    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),

      GoRoute(
        path: AppRoutes.desktopViewPage,
        builder: (context, state) => const VehicleQRWorkstationPage(),
      ),
      GoRoute(
        path: AppRoutes.trialExpiredPage,
        builder: (context, state) => const TrialExpiredPage(),
      ),


    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text("Page not found: ${state.error}")),
    ),
  );
}