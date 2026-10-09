import 'package:pdf/pdf.dart';
import 'package:svenska/core/constants/label_config.dart';

/// Absolute layout (millimetres) for the U350 50×25 mm label — shared by PDF and preview.
class U350LabelLayout {
  static const double pageWidthMm = 50;
  static const double pageHeightMm = 25;

  static const double logoLeftMm = 1.5;
  static const double logoTopMm = 1.0;
  static const double logoWidthMm = 11;
  static const double logoHeightMm = 3.7;

  static const double textBlockLeftMm = 16.5;
  static const double textFirstRowTopMm = 2.2;
  static const double textRowPitchMm = 3.5;
  static const double labelColumnWidthMm = 13;
  static const double valueColumnLeftMm = 29.5;
  static const double textMaxRightMm = 43;
  static const double textBaseFontPt = 4.2;
  static const double textMinFontPt = 3.8;

  static const double qrLeftMm = 1.2;
  static const double qrTopMm = 7.0;
  static const double qrSizeMm = 13.8;

  static const double keepUpLeftMm = 17.5;
  static const double keepUpTopMm = 16.7;
  static const double keepUpFontPt = 9.6;

  static const double madeInIndiaCenterXMm = 28.2;
  static const double madeInIndiaTopMm = 21.3;
  static const double madeInIndiaFontPt = 4.8;

  static const double arrowLeftMm = 43.8;
  static const double arrowTopMm = 1.0;
  static const double arrowWidthMm = 5.7;
  static const double arrowHeightMm = 19.5;
  static const double arrowHeadHeightMm = 6.0;
  static const double arrowShaftWidthMm = 2.8;
  static const double arrowShaftLeftMm = 45.25;

  static double mmToPdfPoints(double mm) => mm * PdfPageFormat.mm;

  static double previewPx(double mm) => mm * kLabelPreviewPxPerMm;

  static double previewFontSizeFromPt(double pt) =>
      pt * kLabelPreviewPxPerMm * 25.4 / 72;

  /// Approximate max value width (mm) at [fontPt] for Helvetica-like bold caps/digits.
  static double estimateValueWidthMm(String value, double fontPt) {
    final charWidthPt = fontPt * 0.52;
    return value.length * charWidthPt * 25.4 / 72;
  }

  static double resolveTextBlockFontPt(List<String> values) {
    final maxValueWidthMm = textMaxRightMm - valueColumnLeftMm;
    for (var pt = textBaseFontPt; pt >= textMinFontPt - 0.01; pt -= 0.1) {
      final fits = values.every((v) => estimateValueWidthMm(v, pt) <= maxValueWidthMm);
      if (fits) return double.parse(pt.toStringAsFixed(1));
    }
    return textMinFontPt;
  }

  static List<LabelElementBounds> elementBoundsMm() {
    final rowTops = [
      textFirstRowTopMm,
      textFirstRowTopMm + textRowPitchMm,
      textFirstRowTopMm + 2 * textRowPitchMm,
      textFirstRowTopMm + 3 * textRowPitchMm,
    ];
    final textHeightMm = textRowPitchMm * 4;

    return [
      LabelElementBounds('logo', logoLeftMm, logoTopMm, logoWidthMm, logoHeightMm),
      LabelElementBounds(
        'text_block',
        textBlockLeftMm,
        textFirstRowTopMm,
        textMaxRightMm - textBlockLeftMm,
        textHeightMm,
      ),
      LabelElementBounds('qr', qrLeftMm, qrTopMm, qrSizeMm, qrSizeMm),
      LabelElementBounds(
        'keep_up_right',
        keepUpLeftMm,
        keepUpTopMm,
        textMaxRightMm - keepUpLeftMm,
        3.5,
      ),
      LabelElementBounds(
        'made_in_india',
        madeInIndiaCenterXMm - 8,
        madeInIndiaTopMm,
        16,
        2.5,
      ),
      LabelElementBounds('arrow', arrowLeftMm, arrowTopMm, arrowWidthMm, arrowHeightMm),
      for (var i = 0; i < rowTops.length; i++)
        LabelElementBounds(
          'text_row_$i',
          textBlockLeftMm,
          rowTops[i],
          textMaxRightMm - textBlockLeftMm,
          textRowPitchMm,
        ),
    ];
  }

  static void assertLayoutWithinPage() {
    for (final el in elementBoundsMm()) {
      if (el.left < 0 ||
          el.top < 0 ||
          el.left + el.width > pageWidthMm + 0.01 ||
          el.top + el.height > pageHeightMm + 0.01) {
        throw StateError('${el.id} outside 50×25 mm: $el');
      }
    }
    final arrow = elementBoundsMm().firstWhere((e) => e.id == 'arrow');
    final text = elementBoundsMm().firstWhere((e) => e.id == 'text_block');
    if (arrow.left < text.left + text.width - 0.5) {
      throw StateError('Arrow overlaps text block');
    }
  }
}

class LabelElementBounds {
  final String id;
  final double left;
  final double top;
  final double width;
  final double height;

  const LabelElementBounds(this.id, this.left, this.top, this.width, this.height);

  @override
  String toString() => '$id(${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}, '
      '${width.toStringAsFixed(1)}×${height.toStringAsFixed(1)})';
}
