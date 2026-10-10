import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ServerProcessService {
  /// Dynamic path based on Windows Program Files environment
  static String get serverPath {
    final programFiles = Platform.environment['ProgramFiles'] ?? r'C:\Program Files';
    return '$programFiles\\SvenskaCoreService\\bin\\server.exe';
  }

  static bool isHostMachine() {
    if (kIsWeb || !Platform.isWindows) return false;
    final existsInProgramFiles = File(serverPath).existsSync();
    final existsInCurrentDir = File('server.exe').existsSync();
    final existsInBundle = Directory(r'build\bundle\bin').existsSync();
    return existsInProgramFiles || existsInCurrentDir || existsInBundle;
  }

  /// Pure Dart standard Socket/HttpClient se check karein (No Dio / ApiClient dependency)
  static Future<bool> isServerRunning() async {
    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://127.0.0.1:8080/api/ping'));
      final response = await request.close().timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client?.close(force: true);
    }
  }

  static Future<bool> startServer() async {
    if (!isHostMachine()) return false;

    try {
      String exePath = serverPath;
      if (!File(exePath).existsSync()) {
        if (File('server.exe').existsSync()) {
          exePath = 'server.exe';
        } else {
          debugPrint('[SERVER START] server.exe not found.');
          return false;
        }
      }

      await Process.start(
        exePath,
        [],
        mode: ProcessStartMode.detached,
        runInShell: true,
      );

      for (var i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (await isServerRunning()) {
          debugPrint('[SERVER START] Server verified ONLINE at port 8080');
          return true;
        }
      }
      debugPrint('[SERVER START FAILED] Ping timed out.');
      return false;
    } catch (e) {
      debugPrint('[SERVER START ERROR] $e');
      return false;
    }
  }

  static Future<bool> stopServer() async {
    if (!Platform.isWindows) return false;
    try {
      final result = await Process.run('taskkill', ['/F', '/IM', 'server.exe']);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('[SERVER STOP ERROR] $e');
      return false;
    }
  }
}
