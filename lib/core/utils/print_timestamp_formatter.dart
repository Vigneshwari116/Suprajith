import 'package:intl/intl.dart';

/// Storage: ISO-like local `yyyy-MM-dd HH:mm:ss`. Display: `dd-MM-yyyy HH:mm:ss`.
class PrintTimestampFormatter {
  static final DateFormat _storageFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _displayFormat = DateFormat('dd-MM-yyyy HH:mm:ss');
  static final DateFormat _legacyDisplay = DateFormat('dd.MM.yyyy HH:mm:ss');

  static String formatForStorage(DateTime dateTime) {
    return _storageFormat.format(dateTime);
  }

  static String formatForDisplay(DateTime dateTime) {
    return _displayFormat.format(dateTime);
  }

  /// Parses stored timestamps (ISO local or legacy `dd.MM.yyyy HH:mm:ss`). Returns null if unknown.
  static DateTime? tryParsePrintedAt(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    try {
      return _storageFormat.parseStrict(value);
    } catch (_) {}
    try {
      return _legacyDisplay.parseStrict(value);
    } catch (_) {}
    try {
      return DateTime.parse(value);
    } catch (_) {}
    return null;
  }

  static String displayFromRaw(String? raw) {
    final parsed = tryParsePrintedAt(raw);
    if (parsed != null) return formatForDisplay(parsed);
    return raw ?? '';
  }

  static bool isSameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isOnLocalDay(String? raw, DateTime day) {
    final parsed = tryParsePrintedAt(raw);
    if (parsed == null) return false;
    return isSameLocalDay(parsed, day);
  }
}
