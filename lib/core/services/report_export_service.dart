import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:svenska/core/utils/print_timestamp_formatter.dart';

class ReportExportService {
  static List<int> buildCsvUtf8Bom(List<Map<String, dynamic>> rows) {
    const header = [
      'Date',
      'Time',
      'Model',
      'Customer Part No',
      'Part No',
      'Serial',
      'Full QR Code',
    ];

    final buffer = StringBuffer();
    buffer.writeln(header.map(_escapeCsvField).join(','));

    for (final row in rows) {
      final printed = PrintTimestampFormatter.tryParsePrintedAt(row['printed_at']?.toString());
      final dateStr = printed != null ? DateFormat('dd-MM-yyyy').format(printed) : '';
      final timeStr = printed != null ? DateFormat('HH:mm:ss').format(printed) : '';
      final qr = row['full_qr_data']?.toString() ?? '';
      final line = [
        dateStr,
        timeStr,
        row['vehicle_model']?.toString() ?? '',
        row['customer_part_no']?.toString() ?? '',
        row['part_no']?.toString() ?? '',
        row['serial_no']?.toString() ?? '',
        _excelQrCell(qr),
      ];
      buffer.writeln(line.map(_escapeCsvField).join(','));
    }

    final utf8Body = utf8.encode(buffer.toString());
    return [0xEF, 0xBB, 0xBF, ...utf8Body];
  }

  /// Excel formula cell so leading zeros are preserved.
  static String _excelQrCell(String qr) => '="$qr"';

  static String _escapeCsvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static Future<List<int>> buildReportPdf({
    required List<Map<String, dynamic>> rows,
    required String title,
    String? filterSummary,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  if (filterSummary != null)
                    pw.Text(filterSummary, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Date',
                'Time',
                'Model',
                'Cust PN',
                'Part No',
                'Serial',
                'Full QR',
              ],
              data: rows.map((row) {
                final printed = PrintTimestampFormatter.tryParsePrintedAt(row['printed_at']?.toString());
                return [
                  printed != null ? DateFormat('dd-MM-yyyy').format(printed) : '',
                  printed != null ? DateFormat('HH:mm:ss').format(printed) : '',
                  row['vehicle_model']?.toString() ?? '',
                  row['customer_part_no']?.toString() ?? '',
                  row['part_no']?.toString() ?? '',
                  row['serial_no']?.toString() ?? '',
                  row['full_qr_data']?.toString() ?? '',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            ),
          ];
        },
      ),
    );
    return doc.save();
  }
}
