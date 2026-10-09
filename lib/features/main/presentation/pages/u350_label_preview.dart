import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'u350_label_layout.dart';

/// On-screen 50×25 mm preview (360×180 logical px) matching [U350LabelLayout].
class U350LabelPreview extends StatelessWidget {
  final String model;
  final String customerPartNo;
  final String partNo;
  final String mfgDate;
  final String qrData;
  final String? logoAssetPath;

  /// When true, draws a solid QR placeholder (faster for layout raster tests).
  final bool useQrPlaceholder;

  const U350LabelPreview({
    super.key,
    required this.model,
    required this.customerPartNo,
    required this.partNo,
    required this.mfgDate,
    required this.qrData,
    this.logoAssetPath,
    this.useQrPlaceholder = false,
  });

  static const double widthPx = 360;
  static const double heightPx = 180;

  double _px(double mm) => U350LabelLayout.previewPx(mm);
  double _fontPt(double pt) => U350LabelLayout.previewFontSizeFromPt(pt);

  @override
  Widget build(BuildContext context) {
    final values = [model, customerPartNo, partNo, mfgDate];
    final blockFontPt = U350LabelLayout.resolveTextBlockFontPt(values);
    final labels = [
      'Vehicle Model',
      'Customer Part No',
      'Suprajit Part No',
      'Date of MFG',
    ];

    return SizedBox(
      width: widthPx,
      height: heightPx,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (logoAssetPath != null)
            Positioned(
              left: _px(U350LabelLayout.logoLeftMm),
              top: _px(U350LabelLayout.logoTopMm),
              width: _px(U350LabelLayout.logoWidthMm),
              height: _px(U350LabelLayout.logoHeightMm),
              child: Image.asset(logoAssetPath!, fit: BoxFit.contain),
            ),
          for (var i = 0; i < labels.length; i++) ...[
            Positioned(
              left: _px(U350LabelLayout.textBlockLeftMm),
              top: _px(U350LabelLayout.textFirstRowTopMm + i * U350LabelLayout.textRowPitchMm),
              width: _px(U350LabelLayout.labelColumnWidthMm),
              child: Text(
                '${labels[i]} :',
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _fontPt(blockFontPt),
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
            ),
            Positioned(
              left: _px(U350LabelLayout.valueColumnLeftMm),
              top: _px(U350LabelLayout.textFirstRowTopMm + i * U350LabelLayout.textRowPitchMm),
              right: _px(U350LabelLayout.pageWidthMm - U350LabelLayout.textMaxRightMm),
              child: Text(
                values[i],
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _fontPt(blockFontPt),
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
            ),
          ],
          Positioned(
            left: _px(U350LabelLayout.qrLeftMm),
            top: _px(U350LabelLayout.qrTopMm),
            width: _px(U350LabelLayout.qrSizeMm),
            height: _px(U350LabelLayout.qrSizeMm),
            child: useQrPlaceholder
                ? const ColoredBox(key: Key('u350-qr-placeholder'), color: Colors.black)
                : QrImageView(
                    data: qrData,
                    padding: EdgeInsets.zero,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.L,
                  ),
          ),
          Positioned(
            left: _px(U350LabelLayout.keepUpLeftMm),
            top: _px(U350LabelLayout.keepUpTopMm),
            child: Text(
              'KEEP UP RIGHT',
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: _fontPt(U350LabelLayout.keepUpFontPt),
                color: Colors.black,
                height: 1.0,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: _px(U350LabelLayout.madeInIndiaTopMm),
            width: widthPx,
            child: Align(
              alignment: Alignment(
                (U350LabelLayout.madeInIndiaCenterXMm / U350LabelLayout.pageWidthMm) * 2 - 1,
                -1,
              ),
              child: Text(
                'MADE IN INDIA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _fontPt(U350LabelLayout.madeInIndiaFontPt),
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
            ),
          ),
          Positioned(
            left: _px(U350LabelLayout.arrowLeftMm),
            top: _px(U350LabelLayout.arrowTopMm),
            width: _px(U350LabelLayout.arrowWidthMm),
            height: _px(U350LabelLayout.arrowHeightMm),
            child: CustomPaint(
              key: const Key('u350-up-arrow'),
              painter: _U350ArrowPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _U350ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final headH = size.height * (U350LabelLayout.arrowHeadHeightMm / U350LabelLayout.arrowHeightMm);
    final shaftW = size.width * (U350LabelLayout.arrowShaftWidthMm / U350LabelLayout.arrowWidthMm);
    final shaftLeft = (size.width - shaftW) / 2;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, headH)
      ..lineTo(0, headH)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawRect(Rect.fromLTWH(shaftLeft, headH, shaftW, size.height - headH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
