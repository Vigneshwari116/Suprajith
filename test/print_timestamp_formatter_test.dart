import 'package:flutter_test/flutter_test.dart';
import 'package:svenska/core/utils/print_timestamp_formatter.dart';

void main() {
  test('storage format is ISO local yyyy-MM-dd HH:mm:ss', () {
    final dt = DateTime(2026, 10, 9, 15, 30, 45);
    expect(PrintTimestampFormatter.formatForStorage(dt), '2026-10-09 15:30:45');
  });

  test('display format is dd-MM-yyyy HH:mm:ss', () {
    final dt = DateTime(2026, 10, 9, 15, 30, 45);
    expect(PrintTimestampFormatter.formatForDisplay(dt), '09-10-2026 15:30:45');
  });

  test('parses legacy dd.MM.yyyy HH:mm:ss without crashing', () {
    final parsed = PrintTimestampFormatter.tryParsePrintedAt('09.10.2026 15:40:00');
    expect(parsed, isNotNull);
    expect(PrintTimestampFormatter.formatForDisplay(parsed!), '09-10-2026 15:40:00');
  });

  test('unknown timestamp returns raw string for display', () {
    expect(PrintTimestampFormatter.displayFromRaw('not-a-date'), 'not-a-date');
  });
}
