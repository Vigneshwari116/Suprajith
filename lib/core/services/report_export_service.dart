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
      final serial = row['serial_no']?.toString() ?? '';
      final line = [
        _excelTextCell(dateStr),
        _excelTextCell(timeStr),
        row['vehicle_model']?.toString() ?? '',
        row['customer_part_no']?.toString() ?? '',
        row['part_no']?.toString() ?? '',
        _excelTextCell(serial),
        _excelTextCell(qr),
      ];
      buffer.writeln(line.map(_escapeCsvField).join(','));
    }

    final utf8Body = utf8.encode(buffer.toString());
    return [0xEF, 0xBB, 0xBF, ...utf8Body];
  }

  /// Excel formula cell so values display as text (dates, times, leading zeros).
  static String _excelTextCell(String value) => value.isEmpty ? '' : '="$value"';

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
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        build: (context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                if (filterSummary != null)
                  pw.Text(filterSummary, style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 6),
                _buildReportTable(rows),
              ],
            ),
          ];
        },
      ),
    );
    return doc.save();
  }

  static pw.Widget _buildReportTable(List<Map<String, dynamic>> rows) {
    const headers = [
      'Date',
      'Time',
      'Model',
      'Cust PN',
      'Part No',
      'Serial',
      'Full QR',
    ];

    final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7);
    final cellStyle = const pw.TextStyle(fontSize: 6.5);
    final qrStyle = const pw.TextStyle(fontSize: 5.8);

    pw.Widget cell(String text, {pw.TextStyle? style, int maxLines = 2}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: pw.Text(
          text,
          style: style ?? cellStyle,
          maxLines: maxLines,
        ),
      );
    }

    return pw.Table(
      border: const pw.TableBorder(
        left: pw.BorderSide(width: 0.4),
        right: pw.BorderSide(width: 0.4),
        top: pw.BorderSide(width: 0.4),
        bottom: pw.BorderSide(width: 0.4),
        horizontalInside: pw.BorderSide(width: 0.25),
        verticalInside: pw.BorderSide(width: 0.25),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(54),
        1: const pw.FixedColumnWidth(40),
        2: const pw.FlexColumnWidth(1.1),
        3: const pw.FlexColumnWidth(1.3),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FixedColumnWidth(32),
        6: const pw.FlexColumnWidth(2.8),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers.map((h) => cell(h, style: headerStyle, maxLines: 1)).toList(),
        ),
        ...rows.map((row) {
          final printed = PrintTimestampFormatter.tryParsePrintedAt(row['printed_at']?.toString());
          return pw.TableRow(
            children: [
              cell(printed != null ? DateFormat('dd-MM-yyyy').format(printed) : '', maxLines: 1),
              cell(printed != null ? DateFormat('HH:mm:ss').format(printed) : '', maxLines: 1),
              cell(row['vehicle_model']?.toString() ?? '', maxLines: 2),
              cell(row['customer_part_no']?.toString() ?? '', maxLines: 2),
              cell(row['part_no']?.toString() ?? '', maxLines: 2),
              cell(row['serial_no']?.toString() ?? '', maxLines: 1),
              cell(row['full_qr_data']?.toString() ?? '', style: qrStyle, maxLines: 3),
            ],
          );
        }),
      ],
    );
  }
}
