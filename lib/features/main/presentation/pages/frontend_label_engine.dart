import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FrontendLabelEngine {
  /// 50x25 mm Industrial Layout
  static Future<Uint8List> build50x25Pdf({
    required String model,
    required String customerPartNo,
    required String partNo,
    required String mfgDate,
    required String qrPayload,
    pw.MemoryImage? logoImage,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          5.0 * PdfPageFormat.cm,
          2.5 * PdfPageFormat.cm,
          marginAll: 0.1 * PdfPageFormat.cm,
        ),
        build: (pw.Context context) {
          return pw.Container(
            // NOTE: color property ko hata kar decoration ke andar rakha gaya hai
            decoration: const pw.BoxDecoration(
              color: PdfColors.white,
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.0),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // LEFT SIDE: Logo & QR Code
                pw.SizedBox(
                  width: 44,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          height: 14,
                          alignment: pw.Alignment.center,
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Container(
                          height: 14,
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            'SVENSKA',
                            style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                          ),
                        ),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.low),
                        data: qrPayload,
                        width: 42,
                        height: 42,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 4),

                // RIGHT SIDE: Details List
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      _buildSpecRow('Vehicle Model', model),
                      pw.SizedBox(height: 1.5),
                      _buildSpecRow('Customer Part No', customerPartNo),
                      pw.SizedBox(height: 1.5),
                      _buildSpecRow('Part No', partNo),
                      pw.SizedBox(height: 1.5),
                      _buildSpecRow('Date of MFG', mfgDate),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return await doc.save();
  }

  /// 100x50 mm Industrial Layout
  static Future<Uint8List> build100x50Pdf({
    required String model,
    required String custPart,
    required String partNo,
    required String mfgDate,
    required String serial,
    required String qrPayload,
    pw.MemoryImage? logoImage,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          10.0 * PdfPageFormat.cm,
          5.0 * PdfPageFormat.cm,
          marginAll: 0.2 * PdfPageFormat.cm,
        ),
        build: (pw.Context context) {
          return pw.Container(
            // NOTE: color property yahan se hata di gayi hai aur BoxDecoration ke andar color set hai
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: PdfColors.black, width: 1.0),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        height: 16,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Text('SVENSKA AUTOMOTIVE',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.Text('#$serial',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  ],
                ),
                pw.Divider(thickness: 0.6, color: PdfColors.black, height: 4),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium),
                      data: qrPayload,
                      width: 70,
                      height: 70,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildWideRow('Model', model),
                          _buildWideRow('Cust PN', custPart),
                          _buildWideRow('Part No', partNo),
                          _buildWideRow('MFG', mfgDate),
                          _buildWideRow('Serial', serial),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.6, color: PdfColors.black, height: 4),
                pw.Center(
                  child: pw.Text(qrPayload,
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                ),
              ],
            ),
          );
        },
      ),
    );
    return await doc.save();
  }

  static pw.Widget _buildSpecRow(String label, String val) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: 48,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 4.8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ),
        pw.Text(': ', style: pw.TextStyle(fontSize: 4.8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.Expanded(
          child: pw.Text(val, maxLines: 1, style: pw.TextStyle(fontSize: 5.2, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ),
      ],
    );
  }

  static pw.Widget _buildWideRow(String label, String val) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 48,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ),
        pw.Text(': ', style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.Expanded(
          child: pw.Text(val, maxLines: 1, style: pw.TextStyle(fontSize: 7.6, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ),
      ],
    );
  }

  static Future<void> directHardwareDispatch({
    required Uint8List pdfBytes,
    required String printerName,
    required String jobName,
  }) async {
    final printers = await Printing.listPrinters();
    Printer? target;

    for (final p in printers) {
      if (p.name.toLowerCase().contains(printerName.toLowerCase())) {
        target = p;
        break;
      }
    }

    if (target != null) {
      final success = await Printing.directPrintPdf(
        printer: target,
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: jobName,
      );
      if (!success) {
        throw Exception('Direct print was rejected by driver for "$printerName".');
      }
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: jobName,
      );
    }
  }
}