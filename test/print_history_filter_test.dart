import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:svenska/core/database/local_vehicle_database.dart';
import 'package:svenska/core/utils/print_timestamp_formatter.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    LocalVehicleDatabase.dispose();
    tempDir = Directory.systemTemp.createTempSync('svenska_filter_test_');
    LocalVehicleDatabase.init(databasePath: p.join(tempDir.path, 'test.db'));
  });

  tearDown(() {
    LocalVehicleDatabase.dispose();
    tempDir.deleteSync(recursive: true);
  });

  test('filters by model and local date range', () {
    LocalVehicleDatabase.logPrint(
      model: 'U350',
      custPart: 'A',
      partNo: 'B',
      mfgDate: '01.01.2026',
      serial: '0001',
      qrPayload: '0000N822126000203659A26AA0001',
    );
    LocalVehicleDatabase.logPrint(
      model: 'U200',
      custPart: 'A',
      partNo: 'B',
      mfgDate: '01.01.2026',
      serial: '0002',
      qrPayload: '0000N822126000203659A26AA0002',
    );

    final u350Only = LocalVehicleDatabase.queryPrintHistory(vehicleModel: 'U350');
    expect(u350Only.length, 1);
    expect(u350Only.first['vehicle_model'], 'U350');

    final today = LocalVehicleDatabase.queryPrintHistory(
      todayOnly: true,
      todayReference: DateTime.now(),
    );
    expect(today.length, greaterThanOrEqualTo(2));

    expect(PrintTimestampFormatter.formatForStorage(DateTime.now()).length, 19);
  });
}
