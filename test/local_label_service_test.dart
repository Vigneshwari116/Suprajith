import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:svenska/core/database/local_vehicle_database.dart';
import 'package:svenska/core/services/local_label_service.dart';
import 'package:svenska/core/services/print_history_refresh_notifier.dart';

void main() {
  late Directory tempDir;
  late LocalLabelService service;

  setUp(() {
    LocalVehicleDatabase.dispose();
    tempDir = Directory.systemTemp.createTempSync('svenska_local_test_');
    LocalVehicleDatabase.init(databasePath: p.join(tempDir.path, 'test.db'));
    service = LocalLabelService(PrintHistoryRefreshNotifier());
  });

  tearDown(() {
    LocalVehicleDatabase.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  const fixed = '0000N82212600020365';

  void seedMaster() {
    service.saveMaster({
      'vehicle_model': 'TEST-U350',
      'customer_part_no': 'N8221260',
      'part_no': 'OFG-SPM-00033',
      'date_of_mfg': '01.01.2026',
      'fixed_qr_code': fixed,
      'company_logo': 'suprajit',
    });
  }

  test('preparePrint full QR test vectors (serial 0001)', () {
    seedMaster();
    final cases = <DateTime, String>{
      DateTime(2026, 9, 25): '0000N82212600020365S926AA0001',
      DateTime(2026, 10, 8): '0000N822126000203658A26AA0001',
      DateTime(2026, 10, 9): '0000N822126000203659A26AA0001',
      DateTime(2026, 8, 31): '0000N82212600020365Y826AA0001',
    };

    for (final entry in cases.entries) {
      LocalVehicleDatabase.resetSerial('TEST-U350');
      final res = service.preparePrint(
        modelQuery: 'TEST-U350',
        labelSize: '50x25',
        printAt: entry.key,
      );
      expect(res['status'], 'success');
      expect(res['full_payload'], entry.value);
      expect(res['full_payload'].toString().length, 29);
      expect(fixed.length, 19);
    }
  });

  test('preparePrint uses print-time MFG date not master date_of_mfg', () {
    seedMaster();
    final res = service.preparePrint(
      modelQuery: 'TEST-U350',
      labelSize: '50x25',
      printAt: DateTime(2026, 3, 15),
    );
    expect(res['status'], 'success');
    expect(res['mfg_date'], '15.03.2026');
  });

  test('fixed QR must be 19 chars and daily limit message', () {
    final bad = service.saveMaster({
      'vehicle_model': 'BAD',
      'fixed_qr_code': 'short',
    });
    expect(bad['status'], 'error');

    seedMaster();
    LocalVehicleDatabase.resetSerial('TEST-U350');
    for (var i = 0; i < 999; i++) {
      final res = service.preparePrint(
        modelQuery: 'TEST-U350',
        labelSize: '50x25',
        printAt: DateTime(2026, 10, 9),
      );
      expect(res['status'], 'success');
    }
    final over = service.preparePrint(
      modelQuery: 'TEST-U350',
      labelSize: '50x25',
      printAt: DateTime(2026, 10, 9),
    );
    expect(over['status'], 'error');
    expect(over['message'], 'Daily limit of 999 reached for this model');
  });

  test('import skips existing vehicle models', () {
    seedMaster();
    final legacyPath = p.join(tempDir.path, 'legacy.db');
    LocalVehicleDatabase.dispose();
    LocalVehicleDatabase.init(databasePath: legacyPath);
    final legacy = LocalLabelService(PrintHistoryRefreshNotifier());
    legacy.saveMaster({
      'vehicle_model': 'LEGACY-1',
      'customer_part_no': 'A',
      'part_no': 'B',
      'date_of_mfg': '01.01.2026',
      'fixed_qr_code': fixed,
    });
    LocalVehicleDatabase.dispose();

    LocalVehicleDatabase.init(databasePath: p.join(tempDir.path, 'main.db'));
    service = LocalLabelService(PrintHistoryRefreshNotifier());
    service.saveMaster({
      'vehicle_model': 'TEST-U350',
      'customer_part_no': 'X',
      'part_no': 'Y',
      'date_of_mfg': '01.01.2026',
      'fixed_qr_code': fixed,
    });

    final result = service.importMastersFromLegacyDb(legacyPath);
    expect(result.imported, 1);
    expect(result.skipped, 0);
    expect(LocalVehicleDatabase.masterExists('LEGACY-1'), isTrue);

    final again = service.importMastersFromLegacyDb(legacyPath);
    expect(again.imported, 0);
    expect(again.skipped, 1);
  });
}
