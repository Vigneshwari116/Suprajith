import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ServerConfigStorage {
  final FlutterSecureStorage _storage;
  static const String _keyConfig = 'svenska_server_config';

  ServerConfigStorage(this._storage);

  /// Default fallback configuration
  static const Map<String, dynamic> _defaultConfig = {
    'server_url': 'http://127.0.0.1:8080',
    'auto_discovery': true,
  };

  /// Saved configuration read karein
  Future<Map<String, dynamic>> getConfig() async {
    try {
      final raw = await _storage.read(key: _keyConfig);
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (_) {}
    return Map<String, dynamic>.from(_defaultConfig);
  }

  /// Server URL fetch karein
  Future<String> getServerUrl() async {
    final cfg = await getConfig();
    return cfg['server_url']?.toString() ?? 'http://127.0.0.1:8080';
  }

  /// Naya discovered ya entered URL save karein
  Future<void> saveServerUrl(String newUrl) async {
    final cfg = await getConfig();
    cfg['server_url'] = newUrl;
    await _storage.write(key: _keyConfig, value: jsonEncode(cfg));
  }
}