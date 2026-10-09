import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DirectFrontendPrinterTest {
  /// Frontend se direct target printer par 50x25mm label print karna
  static Future<void> testPrintDirect({
    required BuildContext context,
    String targetPrinterName = 'TSC TTP-244 Plus',
  }) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Starting direct print to $targetPrinterName...')),
      );

      // 1. Label PDF Document generate karein (Solid White Background)
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            5.0 * PdfPageFormat.cm,
            2.5 * PdfPageFormat.cm,
            marginAll: 0.1 * PdfPageFormat.cm,
          ),
          build: (pw.Context ctx) {
            return pw.Container(
              color: PdfColors.white,
              padding: const pw.EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(
                      errorCorrectLevel: pw.BarcodeQRCorrectionLevel.low,
                    ),
                    data: '0000ND22211000020365TEST0001',
                    width: 48,
                    height: 48,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildRow('Mdl', 'TEST-MODEL'),
                        pw.SizedBox(height: 2),
                        _buildRow('P/N', '12345678'),
                        pw.SizedBox(height: 2),
                        _buildRow('Ser', '#0001'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      // 2. Windows connected printers list me se target printer dhoondo
      final printers = await Printing.listPrinters();
      Printer? matchedPrinter;

      for (final p in printers) {
        if (p.name.toLowerCase().contains(targetPrinterName.toLowerCase())) {
          matchedPrinter = p;
          break;
        }
      }

      if (matchedPrinter == null) {
        // Agar exact name na mile toh print dialog khol do
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Printer "$targetPrinterName" nahi mila! Opening Print Dialog...'),
            backgroundColor: Colors.orange,
          ),
        );
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'Direct_Frontend_Test_Label',
        );
        return;
      }

      // 3. Direct hardware par silently bhej do (Without dialog)
      final isSuccess = await Printing.directPrintPdf(
        printer: matchedPrinter,
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Svenska_Frontend_Direct_Test',
      );

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Direct Print Sent Successfully from Frontend!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Printer driver rejected direct layout.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Frontend Print Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static pw.Widget _buildRow(String label, String val) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 24,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 6.0, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
        ),
        pw.Text(
          ': ',
          style: pw.TextStyle(fontSize: 6.0, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
        ),
        pw.Expanded(
          child: pw.Text(
            val,
            maxLines: 1,
            style: pw.TextStyle(fontSize: 6.0, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
        ),
      ],
    );
  }
}