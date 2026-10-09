import 'package:pdf/pdf.dart';

/// When false, the UI only offers the 50x25 mm label; large-label code remains compiled.
const bool kEnableLargeLabel = false;

/// Zero-margin page sizes used when dispatching label PDFs to printers / Save as PDF.
const PdfPageFormat kLabel50x25PageFormat = PdfPageFormat(
  50 * PdfPageFormat.mm,
  25 * PdfPageFormat.mm,
  marginAll: 0,
);

const PdfPageFormat kLabel100x50PageFormat = PdfPageFormat(
  100 * PdfPageFormat.mm,
  50 * PdfPageFormat.mm,
  marginAll: 0,
);

/// U350-only label extras (arrow, KEEP UP RIGHT, MADE IN INDIA). Exact model match.
bool showKeepUpExtras(String vehicleModel) =>
    vehicleModel.trim().toUpperCase() == 'U350';

/// On-screen 50×25 mm preview scale: logical pixels per millimetre.
const double kLabelPreviewPxPerMm = 7.2;
