import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ServerProcessService {
  static const String _pinStorageKey = 'svenska_supervisor_pin';
  static const String defaultPin = '123456';
  static const String masterRecoveryPin = '990022';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

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

  /// Saved 6-Digit PIN read karein
  static Future<String> getPin() async {
    try {
      final val = await _storage.read(key: _pinStorageKey);
      if (val != null && val.trim().length == 6) {
        return val.trim();
      }
    } catch (_) {}
    return defaultPin;
  }

  /// Naya 6-Digit PIN update karein
  static Future<bool> updatePin(String newPin) async {
    if (newPin.trim().length != 6) return false;
    try {
      await _storage.write(key: _pinStorageKey, value: newPin.trim());
      return true;
    } catch (e) {
      debugPrint('[PIN STORAGE ERROR] $e');
      return false;
    }
  }

  static Future<bool> verifyPin(String enteredPin) async {
    final clean = enteredPin.trim();
    if (clean == masterRecoveryPin) return true;
    final currentPin = await getPin();
    return clean == currentPin;
  }

  /// Pure Dart standard Socket/HttpClient se check karein (No Dio / ApiClient dependency)
  static Future<bool> isServerRunning() async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1000);
      final request = await client.getUrl(Uri.parse('http://127.0.0.1:8080/api/ping'));
      final response = await request.close().timeout(const Duration(milliseconds: 1200));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client?.close(force: true);
    }
  }


  /// Server ko completely silent (0% CMD window) background me start karta hai
  static Future<bool> startServer() async {
    try {
      if (await isServerRunning()) return true;

      String exePath = serverPath;
      final file = File(exePath);

      if (!file.existsSync()) {
        debugPrint('[SERVER START ERROR] Executable not found at: $exePath');
        return false;
      }

      final workDir = file.parent.path;
      debugPrint('[SERVER START] Target: $exePath');
      debugPrint('[SERVER START] Working Directory: $workDir');

      // Windows temp folder me ek invisible launcher VBScript create karein
      final tempDir = Directory.systemTemp.path;
      final vbsFile = File('$tempDir\\svenska_silent_launcher.vbs');

      // 0 ka matlab: SW_HIDE (Zero console window allocation)
      // False ka matlab: Don't wait for completion (Fully detached)
      final vbsContent = '''
Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "$workDir"
WshShell.Run """$exePath""", 0, False
''';

      await vbsFile.writeAsString(vbsContent);

      // wscript.exe bina kisi black box ya CMD window ke silently run karta hai
      await Process.start(
        'wscript.exe',
        [vbsFile.path],
        mode: ProcessStartMode.detached,
      );

      // Server online hone tak wait karein
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (await isServerRunning()) {
          debugPrint('[SERVER START] Server verified ONLINE at port 8080');
          return true;
        }
      }

      debugPrint('[SERVER START FAILED] Ping timed out.');
      return false;
    } catch (e) {
      debugPrint('[SERVER START EXCEPTION] $e');
      return false;
    }
  }

  static Future<bool> stopServer() async {
    try {
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/F', '/IM', 'server.exe']);
      }
      await Future.delayed(const Duration(milliseconds: 500));
      return !(await isServerRunning());
    } catch (e) {
      debugPrint('[SERVER STOP ERROR] $e');
      return false;
    }
  }
}