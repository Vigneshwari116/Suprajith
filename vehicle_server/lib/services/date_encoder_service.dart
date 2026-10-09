class AutomotiveDateEncoder {
  /// Generates 4-digit DDMM + Constant 'AA' = 6 characters
  /// Example: 03 October 2026 -> "0310AA"
  static String encodeDDMMAA(DateTime date, {String shift = 'AA'}) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd$mm$shift';
  }

  // Purana method agar kisi reference me chahiye ho:
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
}