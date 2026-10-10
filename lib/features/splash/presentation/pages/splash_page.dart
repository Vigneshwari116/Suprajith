import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_mode.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/client_discovery_helper.dart';
import '../../../../core/services/server_config_storage.dart';
import '../../../../core/utils/routes_name.dart';
import '../../../../injection.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _statusText = kUseLocalDataStore
      ? 'Starting local label database...'
      : 'Searching for Svenska Print Server...';

  @override
  void initState() {
    super.initState();
    _startAppFlow();
  }

  Future<void> _startAppFlow() async {
    if (kUseLocalDataStore) {
      AuthService.ensureDefaultCredentials();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      final destination =
          sl<AuthService>().isLoggedIn() ? AppRoutes.workstationMain : AppRoutes.login;
      context.go(destination);
      return;
    }

    final configStorage = sl<ServerConfigStorage>();

    final cachedUrl = await configStorage.getServerUrl();
    sl<ApiClient>().updateBaseUrl(cachedUrl);

    if (!kIsWeb) {
      final discoveredUrl = await ClientDiscoveryHelper.findServer(
        timeout: const Duration(seconds: 2),
      );

      if (discoveredUrl != null && discoveredUrl != cachedUrl) {
        sl<ApiClient>().updateBaseUrl(discoveredUrl);
        await configStorage.saveServerUrl(discoveredUrl);
        debugPrint("Secure Storage updated with Server: $discoveredUrl");
      }
    }

    if (!mounted) return;

    final bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    if (kIsWeb || isDesktop) {
      context.go(AppRoutes.workstationMain);
    } else {
      context.go(AppRoutes.workstationMain);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 1000),
              tween: Tween<double>(begin: 0.7, end: 1.0),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00FFFF).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00FFFF).withOpacity(0.05),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Image.asset(
                          'assets/icons/scanner_icon.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Color(0xFF00FFFF),
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              _statusText,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
