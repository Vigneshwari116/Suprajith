import 'dart:convert';
import 'dart:math';

import 'package:svenska/core/database/local_vehicle_database.dart';
import 'package:svenska/core/services/login_attempt_gate.dart';
import 'package:svenska/core/services/password_hasher.dart';

enum AuthLoginResultKind { success, wrongCredentials, blocked }

class AuthLoginResult {
  const AuthLoginResult._(this.kind, {this.remainingBlock});

  final AuthLoginResultKind kind;
  final Duration? remainingBlock;

  static const success = AuthLoginResult._(AuthLoginResultKind.success);

  static AuthLoginResult wrongCredentials() =>
      const AuthLoginResult._(AuthLoginResultKind.wrongCredentials);

  static AuthLoginResult blocked(Duration remaining) =>
      AuthLoginResult._(AuthLoginResultKind.blocked, remainingBlock: remaining);
}

class AuthService {
  AuthService({LoginAttemptGate? attemptGate}) : _attemptGate = attemptGate ?? LoginAttemptGate();

  static const sessionConfigKey = 'session_active';
  static const usernameNormConfigKey = 'auth_username_norm';
  static const passwordSaltConfigKey = 'auth_password_salt_b64';
  static const passwordHashConfigKey = 'auth_password_hash_b64';

  /// Precomputed on first run (password is not stored in source).
  static const defaultUsernameNorm = 'suprajit';
  static const defaultSaltBase64 = '0kkA9tPd4Z3zmJmCypKIvA==';
  static const defaultHashBase64 = 'ZLvwbbTii02JBnNBbXhEb44Q4bM7rLle7tDYngR/V9s=';

  final LoginAttemptGate _attemptGate;

  LoginAttemptGate get attemptGate => _attemptGate;

  static void ensureDefaultCredentials() {
    if (LocalVehicleDatabase.getConfig(passwordSaltConfigKey) == null ||
        LocalVehicleDatabase.getConfig(passwordHashConfigKey) == null) {
      LocalVehicleDatabase.setConfig(passwordSaltConfigKey, defaultSaltBase64);
      LocalVehicleDatabase.setConfig(passwordHashConfigKey, defaultHashBase64);
    }
    if (LocalVehicleDatabase.getConfig(usernameNormConfigKey) == null) {
      LocalVehicleDatabase.setConfig(usernameNormConfigKey, defaultUsernameNorm);
    }
  }

  bool isLoggedIn() {
    final token = LocalVehicleDatabase.getConfig(sessionConfigKey);
    return token != null && token.isNotEmpty;
  }

  bool verifyPassword(String password) {
    final salt = LocalVehicleDatabase.getConfig(passwordSaltConfigKey) ?? defaultSaltBase64;
    final hash = LocalVehicleDatabase.getConfig(passwordHashConfigKey) ?? defaultHashBase64;
    return verifyPasswordHash(password: password, saltBase64: salt, expectedHashBase64: hash);
  }

  bool verifyUsername(String username) {
    final norm = username.trim().toLowerCase();
    final expected =
        LocalVehicleDatabase.getConfig(usernameNormConfigKey) ?? defaultUsernameNorm;
    return norm == expected;
  }

  AuthLoginResult tryLogin(String username, String password) {
    if (_attemptGate.isBlocked) {
      final remaining = _attemptGate.remainingBlock ?? Duration.zero;
      return AuthLoginResult.blocked(remaining);
    }

    final okUser = verifyUsername(username);
    final okPass = verifyPassword(password);
    if (!okUser || !okPass) {
      _attemptGate.recordFailure();
      if (_attemptGate.isBlocked) {
        return AuthLoginResult.blocked(_attemptGate.remainingBlock ?? blockDurationFallback);
      }
      return AuthLoginResult.wrongCredentials();
    }

    _attemptGate.recordSuccess();
    _startSession();
    return AuthLoginResult.success;
  }

  static const blockDurationFallback = Duration(seconds: 30);

  void logout() {
    LocalVehicleDatabase.deleteConfig(sessionConfigKey);
  }

  void _startSession() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    LocalVehicleDatabase.setConfig(sessionConfigKey, base64Encode(bytes));
  }
}
