/// Automotive QR date encoding (day letter + month letter + 2-digit year + shift).
class AutomotiveDateEncoder {
  /// Calendar date used for QR encoding and label MFG (local year/month/day only).
  static DateTime calendarDateForPrint([DateTime? moment]) {
    final m = moment ?? DateTime.now();
    return DateTime(m.year, m.month, m.day);
  }

  static const Map<int, String> _dateMap = {
    1: '1', 2: '2', 3: '3', 4: '4', 5: '5', 6: '6', 7: '7', 8: '8', 9: '9',
    10: 'A', 11: 'B', 12: 'C', 13: 'D', 14: 'E', 15: 'F', 16: 'G', 17: 'H',
    18: 'J', 19: 'K', 20: 'L', 21: 'M', 22: 'N', 23: 'P', 24: 'R', 25: 'S',
    26: 'T', 27: 'U', 28: 'V', 29: 'W', 30: 'X', 31: 'Y',
  };

  static const Map<int, String> _monthMap = {
    1: '1', 2: '2', 3: '3', 4: '4', 5: '5', 6: '6',
    7: '7', 8: '8', 9: '9', 10: 'A', 11: 'B', 12: 'C',
  };

  static String encode(DateTime date, {String shift = 'AA'}) {
    final dCode = _dateMap[date.day] ?? '1';
    final mCode = _monthMap[date.month] ?? '1';
    final yCode = (date.year % 100).toString().padLeft(2, '0');
    return '$dCode$mCode$yCode$shift';
  }

  /// Builds the full 29-character QR payload from fixed part, date, and serial.
  static String buildFullQrPayload({
    required String fixedQr,
    required DateTime date,
    required int serial,
  }) {
    final serialStr = serial.toString().padLeft(4, '0');
    return '$fixedQr${encode(date)}$serialStr';
  }
}
