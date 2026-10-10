import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:svenska/core/services/report_export_service.dart';

void main() {
  test('CSV uses UTF-8 BOM and Excel QR formula for leading zeros', () {
    final bytes = ReportExportService.buildCsvUtf8Bom([
      {
        'printed_at': '2026-10-09 12:00:00',
        'vehicle_model': 'U350',
        'customer_part_no': 'N6222510',
        'part_no': 'OFG-SPM-00033',
        'serial_no': '0001',
        'full_qr_data': '0000N822126000203659A26AA0001',
      },
    ]);
    expect(bytes[0], 0xEF);
    expect(bytes[1], 0xBB);
    expect(bytes[2], 0xBF);
    final text = utf8.decode(bytes);
    expect(text, contains('0000N822126000203659A26AA0001'));
    expect(text, contains('=""0000N822126000203659A26AA0001""'));
    expect(text, contains('=""09-10-2026""'));
    expect(text, contains('=""12:00:00""'));
  });
}
