import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:svenska/core/constants/label_config.dart';
import 'u350_label_layout.dart';

class FrontendLabelEngine {
  static final pw.Font _helveticaBold = pw.Font.helveticaBold();

  /// 50x25 mm Industrial Layout
  static Future<Uint8List> build50x25Pdf({
    required String model,
    required String customerPartNo,
    required String partNo,
    required String mfgDate,
    required String qrPayload,
    pw.MemoryImage? logoImage,
  }) async {
    if (showKeepUpExtras(model)) {
      return _buildU350_50x25Pdf(
        model: model,
        customerPartNo: customerPartNo,
        partNo: partNo,
        mfgDate: mfgDate,
        qrPayload: qrPayload,
        logoImage: logoImage,
      );
    }

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
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
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

  static Future<Uint8List> _buildU350_50x25Pdf({
    required String model,
    required String customerPartNo,
    required String partNo,
    required String mfgDate,
    required String qrPayload,
    pw.MemoryImage? logoImage,
  }) async {
    final values = [model, customerPartNo, partNo, mfgDate];
    final blockFontPt = U350LabelLayout.resolveTextBlockFontPt(values);
    final labels = [
      'Vehicle Model',
      'Customer Part No',
      'Suprajit Part No',
      'Date of MFG',
    ];

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          U350LabelLayout.mmToPdfPoints(U350LabelLayout.pageWidthMm),
          U350LabelLayout.mmToPdfPoints(U350LabelLayout.pageHeightMm),
          marginAll: 0,
        ),
        build: (pw.Context context) {
          return pw.SizedBox(
            width: U350LabelLayout.mmToPdfPoints(U350LabelLayout.pageWidthMm),
            height: U350LabelLayout.mmToPdfPoints(U350LabelLayout.pageHeightMm),
            child: pw.Stack(
              children: [
                if (logoImage != null)
                  pw.Positioned(
                    left: U350LabelLayout.mmToPdfPoints(U350LabelLayout.logoLeftMm),
                    top: U350LabelLayout.mmToPdfPoints(U350LabelLayout.logoTopMm),
                    child: pw.SizedBox(
                      width: U350LabelLayout.mmToPdfPoints(U350LabelLayout.logoWidthMm),
                      height: U350LabelLayout.mmToPdfPoints(U350LabelLayout.logoHeightMm),
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                  )
                else
                  pw.Positioned(
                    left: U350LabelLayout.mmToPdfPoints(U350LabelLayout.logoLeftMm),
                    top: U350LabelLayout.mmToPdfPoints(U350LabelLayout.logoTopMm),
                    child: pw.SizedBox(
                      width: U350LabelLayout.mmToPdfPoints(U350LabelLayout.logoWidthMm),
                      height: U350LabelLayout.mmToPdfPoints(U350LabelLayout.logoHeightMm),
                      child: pw.Center(
                      child: pw.Text(
                        'SVENSKA',
                        style: pw.TextStyle(
                          font: _helveticaBold,
                          fontSize: 5,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    ),
                  ),
                for (var i = 0; i < labels.length; i++) ...[
                  pw.Positioned(
                    left: U350LabelLayout.mmToPdfPoints(U350LabelLayout.textBlockLeftMm),
                    top: U350LabelLayout.mmToPdfPoints(
                      U350LabelLayout.textFirstRowTopMm + i * U350LabelLayout.textRowPitchMm,
                    ),
                    child: pw.SizedBox(
                      width: U350LabelLayout.mmToPdfPoints(U350LabelLayout.labelColumnWidthMm),
                      child: pw.Text(
                      labels[i],
                      maxLines: 1,
                      style: pw.TextStyle(
                        font: _helveticaBold,
                        fontSize: blockFontPt,
                        color: PdfColors.black,
                      ),
                    ),
                    ),
                  ),
                  pw.Positioned(
                    left: U350LabelLayout.mmToPdfPoints(U350LabelLayout.valueColumnLeftMm),
                    top: U350LabelLayout.mmToPdfPoints(
                      U350LabelLayout.textFirstRowTopMm + i * U350LabelLayout.textRowPitchMm,
                    ),
                    child: pw.SizedBox(
                      width: U350LabelLayout.mmToPdfPoints(
                        U350LabelLayout.textMaxRightMm - U350LabelLayout.valueColumnLeftMm,
                      ),
                      child: pw.Text(
                      values[i],
                      maxLines: 1,
                      style: pw.TextStyle(
                        font: _helveticaBold,
                        fontSize: blockFontPt,
                        color: PdfColors.black,
                      ),
                    ),
                    ),
                  ),
                ],
                pw.Positioned(
                  left: U350LabelLayout.mmToPdfPoints(U350LabelLayout.qrLeftMm),
                  top: U350LabelLayout.mmToPdfPoints(U350LabelLayout.qrTopMm),
                  child: pw.SizedBox(
                    width: U350LabelLayout.mmToPdfPoints(U350LabelLayout.qrSizeMm),
                    height: U350LabelLayout.mmToPdfPoints(U350LabelLayout.qrSizeMm),
                    child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.low),
                    data: qrPayload,
                    width: U350LabelLayout.mmToPdfPoints(U350LabelLayout.qrSizeMm),
                    height: U350LabelLayout.mmToPdfPoints(U350LabelLayout.qrSizeMm),
                    color: PdfColors.black,
                    drawText: false,
                    ),
                  ),
                ),
                pw.Positioned(
                  left: U350LabelLayout.mmToPdfPoints(U350LabelLayout.keepUpLeftMm),
                  top: U350LabelLayout.mmToPdfPoints(U350LabelLayout.keepUpTopMm),
                  child: pw.Text(
                    'KEEP UP RIGHT',
                    style: pw.TextStyle(
                      font: _helveticaBold,
                      fontSize: U350LabelLayout.keepUpFontPt,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.Positioned(
                  left: 0,
                  top: U350LabelLayout.mmToPdfPoints(U350LabelLayout.madeInIndiaTopMm),
                  child: pw.SizedBox(
                    width: U350LabelLayout.mmToPdfPoints(U350LabelLayout.pageWidthMm),
                    child: pw.Align(
                    alignment: pw.Alignment(
                      (U350LabelLayout.madeInIndiaCenterXMm / U350LabelLayout.pageWidthMm) * 2 - 1,
                      -1,
                    ),
                    child: pw.Text(
                      'MADE IN INDIA',
                      style: pw.TextStyle(
                        font: _helveticaBold,
                        fontSize: U350LabelLayout.madeInIndiaFontPt,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  ),
                ),
                pw.Positioned(
                  left: U350LabelLayout.mmToPdfPoints(U350LabelLayout.arrowLeftMm),
                  top: U350LabelLayout.mmToPdfPoints(U350LabelLayout.arrowTopMm),
                  child: pw.SizedBox(
                    width: U350LabelLayout.mmToPdfPoints(U350LabelLayout.arrowWidthMm),
                    height: U350LabelLayout.mmToPdfPoints(U350LabelLayout.arrowHeightMm),
                    child: _buildU350UpArrowPdf(),
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

  static pw.Widget _buildU350UpArrowPdf() {
    final wPt = U350LabelLayout.mmToPdfPoints(U350LabelLayout.arrowWidthMm);
    final hPt = U350LabelLayout.mmToPdfPoints(U350LabelLayout.arrowHeightMm);
    final headPt = U350LabelLayout.mmToPdfPoints(U350LabelLayout.arrowHeadHeightMm);
    final shaftWPt = U350LabelLayout.mmToPdfPoints(U350LabelLayout.arrowShaftWidthMm);
    final shaftLeftPt =
        U350LabelLayout.mmToPdfPoints(U350LabelLayout.arrowShaftLeftMm - U350LabelLayout.arrowLeftMm);

    return pw.CustomPaint(
      size: PdfPoint(wPt, hPt),
      painter: (PdfGraphics canvas, PdfPoint size) {
        canvas.setFillColor(PdfColors.black);
        canvas.moveTo(size.x / 2, 0);
        canvas.lineTo(size.x, headPt);
        canvas.lineTo(0, headPt);
        canvas.closePath();
        canvas.fillPath();
        canvas.drawRect(shaftLeftPt, headPt, shaftWPt, size.y - headPt);
      },
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

  static pw.Widget _buildSpecRow(String label, String val) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: 42,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 4.8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ),
        pw.Text(': ', style: pw.TextStyle(fontSize: 4.8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.Expanded(
          child: pw.Text(val, maxLines: 1, style: pw.TextStyle(fontSize: 5.0, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
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
