import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

class ServerDatabase {
  static late final Database db;

  static void init() {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '.';
    final dirPath = p.join(localAppData, '.svenska_server_vault');
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final dbPath = p.join(dirPath, 'svenska_vehicle.db');
    db = sqlite3.open(dbPath);

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

    // Safe migration: agar pehle se table bani ho toh column safely add ho jaye
    try {
      db.execute("ALTER TABLE vehicle_master ADD COLUMN company_logo TEXT DEFAULT 'none';");
    } catch (_) {}

    db.execute('''
      CREATE TABLE IF NOT EXISTS serial_tracker (
        vehicle_model TEXT PRIMARY KEY,
        last_serial INTEGER NOT NULL DEFAULT 0,
        last_date TEXT NOT NULL DEFAULT ''
      );
    ''');

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

    print('[DB] Initialized at: $dbPath');
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

  static void saveMaster(Map<String, dynamic> data) {
    final stmt = db.prepare('''
      INSERT INTO vehicle_master (vehicle_model, customer_part_no, part_no, date_of_mfg, fixed_qr_code, company_logo)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(vehicle_model) DO UPDATE SET
        customer_part_no=excluded.customer_part_no,
        part_no=excluded.part_no,
        date_of_mfg=excluded.date_of_mfg,
        fixed_qr_code=excluded.fixed_qr_code,
        company_logo=excluded.company_logo;
    ''');
    stmt.execute([
      data['vehicle_model'],
      data['customer_part_no'] ?? '',
      data['part_no'] ?? '',
      data['date_of_mfg'] ?? '',
      data['fixed_qr_code'] ?? '0000ND22211000020365',
      data['company_logo'] ?? 'none',
    ]);
    stmt.dispose();
  }

  static void deleteMaster(int id) {
    final stmt = db.prepare('DELETE FROM vehicle_master WHERE id = ?');
    stmt.execute([id]);
    stmt.dispose();
  }

  static void resetSerial(String model) {
    final stmt = db.prepare('DELETE FROM serial_tracker WHERE LOWER(vehicle_model) = ?');
    stmt.execute([model.toLowerCase().trim()]);
    stmt.dispose();
  }

  static int getNextSerialAndIncrement(String model, String dateCode) {
    final res = db.select(
      'SELECT last_serial, last_date FROM serial_tracker WHERE LOWER(vehicle_model) = ?',
      [model.toLowerCase()],
    );

    int nextSerial = 1;
    if (res.isNotEmpty) {
      final savedDate = res.first['last_date']?.toString() ?? '';
      final lastSerial = res.first['last_serial'] as int? ?? 0;
      if (savedDate == dateCode) {
        nextSerial = lastSerial + 1;
      }
    }

    final updateStmt = db.prepare('''
      INSERT INTO serial_tracker (vehicle_model, last_serial, last_date)
      VALUES (?, ?, ?)
      ON CONFLICT(vehicle_model) DO UPDATE SET
        last_serial=excluded.last_serial,
        last_date=excluded.last_date;
    ''');
    updateStmt.execute([model, nextSerial, dateCode]);
    updateStmt.dispose();

    return nextSerial;
  }

  static void logPrint({
    required String model,
    required String custPart,
    required String partNo,
    required String mfgDate,
    required String serial,
    required String qrPayload,
    required String clientIp,
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
}