import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:svenska/core/database/local_vehicle_database.dart';
import 'package:svenska/core/services/auth_service.dart';
import 'package:svenska/core/services/login_attempt_gate.dart';
import 'package:svenska/core/services/password_hasher.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    LocalVehicleDatabase.dispose();
    tempDir = Directory.systemTemp.createTempSync('svenska_auth_test_');
    LocalVehicleDatabase.init(databasePath: p.join(tempDir.path, 'test.db'));
    AuthService.ensureDefaultCredentials();
  });

  tearDown(() {
    LocalVehicleDatabase.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('password hash verify accepts correct password and rejects wrong', () {
    expect(
      verifyPasswordHash(
        password: 'Suprajit@123',
        saltBase64: AuthService.defaultSaltBase64,
        expectedHashBase64: AuthService.defaultHashBase64,
      ),
      isTrue,
    );
    expect(
      verifyPasswordHash(
        password: 'wrong',
        saltBase64: AuthService.defaultSaltBase64,
        expectedHashBase64: AuthService.defaultHashBase64,
      ),
      isFalse,
    );
  });

  test('username is case insensitive with trim; password is case sensitive', () {
    final auth = AuthService();
    expect(auth.tryLogin('  SUPRAJIT  ', 'Suprajit@123').kind, AuthLoginResultKind.success);
    auth.logout();
    expect(auth.tryLogin('Suprajit', 'suprajit@123').kind, AuthLoginResultKind.wrongCredentials);
  });

  test('five failed attempts block login for 30 seconds', () {
    var now = DateTime(2026, 1, 1, 12, 0, 0);
    final gate = LoginAttemptGate(now: () => now);
    final auth = AuthService(attemptGate: gate);

    for (var i = 0; i < 4; i++) {
      expect(auth.tryLogin('bad', 'bad').kind, AuthLoginResultKind.wrongCredentials);
    }
    expect(auth.tryLogin('bad', 'bad').kind, AuthLoginResultKind.blocked);

    final blocked = auth.tryLogin('Suprajit', 'Suprajit@123');
    expect(blocked.kind, AuthLoginResultKind.blocked);
    expect(blocked.remainingBlock, const Duration(seconds: 30));

    now = now.add(const Duration(seconds: 29));
    expect(auth.tryLogin('Suprajit', 'Suprajit@123').kind, AuthLoginResultKind.blocked);

    now = now.add(const Duration(seconds: 2));
    expect(auth.tryLogin('Suprajit', 'Suprajit@123').kind, AuthLoginResultKind.success);
  });

  test('login sets session; logout clears session', () {
    final auth = AuthService();
    expect(auth.isLoggedIn(), isFalse);

    expect(auth.tryLogin('Suprajit', 'Suprajit@123').kind, AuthLoginResultKind.success);
    expect(auth.isLoggedIn(), isTrue);
    expect(LocalVehicleDatabase.getConfig(AuthService.sessionConfigKey), isNotEmpty);

    auth.logout();
    expect(auth.isLoggedIn(), isFalse);
    expect(LocalVehicleDatabase.getConfig(AuthService.sessionConfigKey), isNull);
  });

  test('ensureDefaultCredentials after missing auth keys', () {
    LocalVehicleDatabase.deleteConfig(AuthService.passwordSaltConfigKey);
    LocalVehicleDatabase.deleteConfig(AuthService.passwordHashConfigKey);
    AuthService.ensureDefaultCredentials();
    expect(LocalVehicleDatabase.getConfig(AuthService.passwordSaltConfigKey), AuthService.defaultSaltBase64);
    expect(LocalVehicleDatabase.getConfig(AuthService.passwordHashConfigKey), AuthService.defaultHashBase64);
    final auth = AuthService();
    expect(auth.tryLogin('Suprajit', 'Suprajit@123').kind, AuthLoginResultKind.success);
  });
}
