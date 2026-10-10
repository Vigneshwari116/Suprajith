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

  /// Grouping label for audit lists: always `dd.MM.yyyy`.
  static final DateFormat _groupLabelFormat = DateFormat('dd.MM.yyyy');

  static String groupDateLabel(String? raw) {
    final parsed = tryParsePrintedAt(raw);
    if (parsed == null) {
      final fallback = raw?.split(' ').first.trim();
      return fallback == null || fallback.isEmpty ? 'Unknown' : fallback;
    }
    return _groupLabelFormat.format(parsed);
  }

  static DateTime? tryParseGroupDateLabel(String label) {
    try {
      return _groupLabelFormat.parseStrict(label);
    } catch (_) {
      return null;
    }
  }

  static String timeOfDayFromRaw(String? raw) {
    final parsed = tryParsePrintedAt(raw);
    if (parsed == null) {
      final parts = raw?.split(' ');
      return parts != null && parts.length > 1 ? parts[1] : '';
    }
    return DateFormat('HH:mm:ss').format(parsed);
  }
}
