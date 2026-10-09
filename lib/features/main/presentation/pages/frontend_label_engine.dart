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
    bool showKeepUpArrow = false,
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
            decoration: const pw.BoxDecoration(
              color: PdfColors.white,
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 1.2, vertical: 0.8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.SizedBox(
                  width: 44,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          height: 13,
                          alignment: pw.Alignment.center,
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Container(
                          height: 13,
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            'SVENSKA',
                            style: pw.TextStyle(fontSize: 6.2, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                          ),
                        ),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.low),
                        data: qrPayload,
                        width: showKeepUpArrow ? 40 : 42,
                        height: showKeepUpArrow ? 40 : 42,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: showKeepUpArrow ? 2 : 4),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      _buildSpecRow('Vehicle Model', model, compact: showKeepUpArrow),
                      pw.SizedBox(height: showKeepUpArrow ? 0.8 : 1.5),
                      _buildSpecRow('Customer Part No', customerPartNo, compact: showKeepUpArrow),
                      pw.SizedBox(height: showKeepUpArrow ? 0.8 : 1.5),
                      _buildSpecRow('Part No', partNo, compact: showKeepUpArrow),
                      pw.SizedBox(height: showKeepUpArrow ? 0.8 : 1.5),
                      _buildSpecRow('Date of MFG', mfgDate, compact: showKeepUpArrow),
                      if (showKeepUpArrow) ...[
                        pw.SizedBox(height: 1.2),
                        pw.Center(
                          child: pw.Text(
                            'KEEP UP RIGHT',
                            style: pw.TextStyle(
                              fontSize: 5.6,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        pw.Spacer(),
                        pw.Center(
                          child: pw.Text(
                            'MADE IN INDIA',
                            style: pw.TextStyle(
                              fontSize: 4.6,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showKeepUpArrow) ...[
                  pw.SizedBox(width: 2),
                  _buildUpArrow(),
                ],
              ],
            ),
          );
        },
      ),
    );
    return await doc.save();
  }

  static pw.Widget _buildUpArrow() {
    return pw.SizedBox(
      width: 10,
      child: pw.CustomPaint(
        size: const PdfPoint(10, 58),
        painter: (PdfGraphics canvas, PdfPoint size) {
          final w = size.x;
          final h = size.y;
          final headH = h * 0.28;
          final shaftW = w * 0.36;
          final shaftLeft = (w - shaftW) / 2;

          canvas.setFillColor(PdfColors.black);
          canvas.moveTo(w / 2, 0);
          canvas.lineTo(w, headH);
          canvas.lineTo(0, headH);
          canvas.closePath();
          canvas.fillPath();

          canvas.drawRect(shaftLeft, headH, shaftW, h - headH);
        },
      ),
    );
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

  static pw.Widget _buildSpecRow(String label, String val, {bool compact = false}) {
    final labelWidth = compact ? 40.0 : 42.0;
    final fontSize = compact ? 4.6 : 4.8;
    final valueSize = compact ? 4.8 : 5.0;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: labelWidth,
          child: pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ),
        pw.Text(': ', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.Expanded(
          child: pw.Text(val, maxLines: 1, style: pw.TextStyle(fontSize: valueSize, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
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
