import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Local SQLite store (same schema as vehicle_server). Path:
/// `%LOCALAPPDATA%\\SvenskaLabels\\svenska_vehicle.db`
class LocalVehicleDatabase {
  static Database? _db;

  static Database get db {
    final instance = _db;
    if (instance == null) {
      throw StateError('LocalVehicleDatabase.init() must be called before use');
    }
    return instance;
  }

  static String defaultDatabasePath() {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '.';
    final dirPath = p.join(localAppData, 'SvenskaLabels');
    return p.join(dirPath, 'svenska_vehicle.db');
  }

  static void init({String? databasePath}) {
    if (_db != null) return;

    final dbPath = databasePath ?? defaultDatabasePath();
    final dir = Directory(p.dirname(dbPath));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    _db = sqlite3.open(dbPath);
    _createSchema();
  }

  static void dispose() {
    _db?.dispose();
    _db = null;
  }

  static void _createSchema() {
    db.execute('''
      CREATE TABLE IF NOT EXISTS vehicle_master (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_model TEXT UNIQUE,
        customer_part_no TEXT,
        part_no TEXT,
        date_of_mfg TEXT,
        fixed_qr_code TEXT,
        company_logo TEXT DEFAULT 'none'
      );
    ''');

    try {
      db.execute("ALTER TABLE vehicle_master ADD COLUMN company_logo TEXT DEFAULT 'none';");
    } catch (_) {}

    try {
      db.execute(
        'ALTER TABLE vehicle_master ADD COLUMN show_keep_up_arrow INTEGER NOT NULL DEFAULT 0;',
      );
    } catch (_) {}

    db.execute('''
      CREATE TABLE IF NOT EXISTS serial_tracker (
        vehicle_model TEXT PRIMARY KEY,
        last_serial INTEGER NOT NULL DEFAULT 0,
        last_date TEXT NOT NULL DEFAULT ''
      );
    ''');

    _migrateSerialTrackerToPerDateCode();

    db.execute('''
      CREATE TABLE IF NOT EXISTS print_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_model TEXT,
        customer_part_no TEXT,
        part_no TEXT,
        date_of_mfg TEXT,
        serial_no TEXT,
        full_qr_data TEXT,
        printed_at TEXT,
        client_ip TEXT,
        company_logo TEXT DEFAULT 'none'
      );
    ''');

    try {
      db.execute("ALTER TABLE print_history ADD COLUMN company_logo TEXT DEFAULT 'none';");
    } catch (_) {}

    db.execute('''
      CREATE TABLE IF NOT EXISTS app_config (
        key TEXT PRIMARY KEY,
        val TEXT
      );
    ''');
  }

  static void _migrateSerialTrackerToPerDateCode() {
    final cols = db.select('PRAGMA table_info(serial_tracker)');
    final hasDateCode = cols.any((c) => c['name']?.toString() == 'date_code');
    if (hasDateCode) return;

    db.execute('''
      CREATE TABLE serial_tracker_v2 (
        vehicle_model TEXT NOT NULL,
        date_code TEXT NOT NULL,
        last_serial INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (vehicle_model, date_code)
      );
    ''');

    try {
      db.execute('''
        INSERT INTO serial_tracker_v2 (vehicle_model, date_code, last_serial)
        SELECT vehicle_model, last_date, last_serial FROM serial_tracker
        WHERE last_date IS NOT NULL AND TRIM(last_date) != '';
      ''');
    } catch (_) {}

    db.execute('DROP TABLE serial_tracker;');
    db.execute('ALTER TABLE serial_tracker_v2 RENAME TO serial_tracker;');
  }

  static List<Map<String, dynamic>> getAllMasters() {
    final res = db.select('SELECT * FROM vehicle_master ORDER BY id DESC');
    return res.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Map<String, dynamic>? findModel(String query) {
    final res = db.select(
      'SELECT * FROM vehicle_master WHERE LOWER(vehicle_model) = ? OR LOWER(customer_part_no) = ? OR LOWER(part_no) = ? LIMIT 1',
      [query.toLowerCase(), query.toLowerCase(), query.toLowerCase()],
    );
    if (res.isNotEmpty) return Map<String, dynamic>.from(res.first);
    return null;
  }

  static bool masterExists(String vehicleModel) {
    final res = db.select(
      'SELECT 1 FROM vehicle_master WHERE LOWER(vehicle_model) = LOWER(?) LIMIT 1',
      [vehicleModel.trim()],
    );
    return res.isNotEmpty;
  }

  static void saveMaster(Map<String, dynamic> data) {
    final stmt = db.prepare('''
      INSERT INTO vehicle_master (vehicle_model, customer_part_no, part_no, date_of_mfg, fixed_qr_code, company_logo, show_keep_up_arrow)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(vehicle_model) DO UPDATE SET
        customer_part_no=excluded.customer_part_no,
        part_no=excluded.part_no,
        date_of_mfg=excluded.date_of_mfg,
        fixed_qr_code=excluded.fixed_qr_code,
        company_logo=excluded.company_logo,
        show_keep_up_arrow=excluded.show_keep_up_arrow;
    ''');
    stmt.execute([
      data['vehicle_model'],
      data['customer_part_no'] ?? '',
      data['part_no'] ?? '',
      data['date_of_mfg'] ?? '',
      data['fixed_qr_code'] ?? '0000ND22211000020365',
      data['company_logo'] ?? 'none',
      data['show_keep_up_arrow'] ?? 0,
    ]);
    stmt.dispose();
  }

  static void deleteMaster(int id) {
    final stmt = db.prepare('DELETE FROM vehicle_master WHERE id = ?');
    stmt.execute([id]);
    stmt.dispose();
  }

  static void resetSerial(String model) {
    final stmt = db.prepare(
      'DELETE FROM serial_tracker WHERE LOWER(vehicle_model) = LOWER(?)',
    );
    stmt.execute([model.trim()]);
    stmt.dispose();
  }

  static const int kDailySerialLimit = 999;

  /// Atomic serial increment (safe if two app instances run on the same DB file).
  static int getNextSerialAndIncrement(String model, String dateCode) {
    final normalizedModel = model.trim();
    db.execute('BEGIN IMMEDIATE');
    try {
      final res = db.select(
        'SELECT last_serial FROM serial_tracker WHERE LOWER(vehicle_model) = LOWER(?) AND date_code = ?',
        [normalizedModel.toLowerCase(), dateCode],
      );

      int nextSerial = 1;
      if (res.isNotEmpty) {
        final lastSerial = res.first['last_serial'] as int? ?? 0;
        nextSerial = lastSerial + 1;
      }

      if (nextSerial > kDailySerialLimit) {
        throw StateError('Daily limit of 999 reached for this model');
      }

      final updateStmt = db.prepare('''
        INSERT INTO serial_tracker (vehicle_model, date_code, last_serial)
        VALUES (?, ?, ?)
        ON CONFLICT(vehicle_model, date_code) DO UPDATE SET
          last_serial=excluded.last_serial;
      ''');
      updateStmt.execute([normalizedModel, dateCode, nextSerial]);
      updateStmt.dispose();

      db.execute('COMMIT');
      return nextSerial;
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  static void logPrint({
    required String model,
    required String custPart,
    required String partNo,
    required String mfgDate,
    required String serial,
    required String qrPayload,
    String clientIp = 'local',
    String companyLogo = 'none',
  }) {
    final stmt = db.prepare('''
      INSERT INTO print_history (vehicle_model, customer_part_no, part_no, date_of_mfg, serial_no, full_qr_data, printed_at, client_ip, company_logo)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    stmt.execute([
      model,
      custPart,
      partNo,
      mfgDate,
      serial,
      qrPayload,
      DateFormat('dd.MM.yyyy HH:mm:ss').format(DateTime.now()),
      clientIp,
      companyLogo,
    ]);
    stmt.dispose();
  }

  static List<Map<String, dynamic>> getAuditLogs({int limit = 200}) {
    final res = db.select('SELECT * FROM print_history ORDER BY id DESC LIMIT ?', [limit]);
    return res.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static String? getConfig(String key) {
    final res = db.select('SELECT val FROM app_config WHERE key = ?', [key]);
    if (res.isNotEmpty) return res.first['val']?.toString();
    return null;
  }

  static void setConfig(String key, String val) {
    final stmt = db.prepare('INSERT OR REPLACE INTO app_config (key, val) VALUES (?, ?)');
    stmt.execute([key, val]);
    stmt.dispose();
  }

  /// Copies [vehicle_master] rows from another SQLite file; skips existing models.
  static ({int imported, int skipped}) importMastersFromDatabaseFile(String filePath) {
    final external = sqlite3.open(filePath);
    try {
      final rows = external.select('SELECT * FROM vehicle_master');
      var imported = 0;
      var skipped = 0;
      for (final row in rows) {
        final model = row['vehicle_model']?.toString().trim() ?? '';
        if (model.isEmpty) continue;
        if (masterExists(model)) {
          skipped++;
          continue;
        }
        saveMaster(Map<String, dynamic>.from(row));
        imported++;
      }
      return (imported: imported, skipped: skipped);
    } finally {
      external.dispose();
    }
  }
}
