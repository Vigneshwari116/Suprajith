import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:svenska/core/database/local_vehicle_database.dart';
import 'package:svenska/core/services/local_label_service.dart';
import 'package:svenska/injection.dart' as di;

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('svenska_widget_test_');
    LocalVehicleDatabase.dispose();
    LocalVehicleDatabase.init(databasePath: p.join(dir.path, 'widget.db'));
    await di.init();
  });

  tearDownAll(() {
    LocalVehicleDatabase.dispose();
  });

  test('local label service is registered after init', () {
    expect(di.sl<LocalLabelService>(), isA<LocalLabelService>());
  });
}
