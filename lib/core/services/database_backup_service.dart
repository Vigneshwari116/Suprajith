import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:svenska/core/database/local_vehicle_database.dart';

class DatabaseBackupService {
  static const requiredTables = [
    'vehicle_master',
    'serial_tracker',
    'print_history',
    'app_config',
  ];

  static String get databasePath => LocalVehicleDatabase.databaseFilePath;

  static Future<String> backupToDirectory(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final fileName = 'svenska_vehicle_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db';
    final target = p.join(directoryPath, fileName);
    await File(databasePath).copy(target);
    return target;
  }

  static bool validateBackupDatabase(String filePath) {
    try {
      return LocalVehicleDatabase.validateExternalDatabase(filePath);
    } catch (_) {
      return false;
    }
  }

  /// Safety copy of current DB, then replace with [sourcePath]. Caller must re-init DB.
  static Future<String> restoreFromFile(String sourcePath) async {
    if (!validateBackupDatabase(sourcePath)) {
      throw StateError('Invalid database: missing required tables');
    }
    final dbFile = File(databasePath);
    final safetyName =
        'svenska_vehicle_safety_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db';
    final safetyPath = p.join(p.dirname(databasePath), safetyName);
    if (dbFile.existsSync()) {
      await dbFile.copy(safetyPath);
    }
    LocalVehicleDatabase.dispose();
    await File(sourcePath).copy(databasePath);
    LocalVehicleDatabase.init(databasePath: databasePath);
    return safetyPath;
  }
}
