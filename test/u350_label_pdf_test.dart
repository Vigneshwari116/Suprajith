import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svenska/features/main/presentation/pages/frontend_label_engine.dart';
import 'package:svenska/features/main/presentation/pages/u350_label_layout.dart';
import 'package:svenska/features/main/presentation/pages/u350_label_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('U350 layout elements are within 50x25 mm and non-overlapping', () {
    U350LabelLayout.assertLayoutWithinPage();
    final bounds = U350LabelLayout.elementBoundsMm();
    expect(bounds.firstWhere((e) => e.id == 'logo').left, U350LabelLayout.logoLeftMm);
    expect(bounds.firstWhere((e) => e.id == 'qr').width, U350LabelLayout.qrSizeMm);
    expect(bounds.firstWhere((e) => e.id == 'arrow').left, U350LabelLayout.arrowLeftMm);
  });

  test('U350 PDF uses 50x25 mm zero-margin page', () async {
    final bytes = await FrontendLabelEngine.build50x25Pdf(
      model: 'U350',
      customerPartNo: 'N6222510',
      partNo: 'OFG-SPM-00033',
      mfgDate: '31.08.2026',
      qrPayload: '0000N82212600020365Y826AA0001',
    );
    expect(bytes, isNotEmpty);

    final widthPt = 50 * 72 / 25.4;
    final heightPt = 25 * 72 / 25.4;
    final pdfText = utf8.decode(bytes, allowMalformed: true);
    expect(pdfText, contains('MediaBox'));
    expect(pdfText, contains(widthPt.toStringAsFixed(1).split('.').first));
    expect(pdfText, contains(heightPt.toStringAsFixed(1).split('.').first));
    // Filled rectangle ops for arrow shaft (standard PDF, widely supported).
    expect(pdfText, contains(' re'));
  });

  testWidgets('U350 preview uses 360x180 and positioned layout coordinates', (tester) async {
    const qr = '0000N82212600020365Y826AA0001';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: U350LabelPreview(
            model: 'U350',
            customerPartNo: 'N6222510',
            partNo: 'OFG-SPM-00033',
            mfgDate: '31.08.2026',
            qrData: qr,
            useQrPlaceholder: true,
          ),
        ),
      ),
    );
    await tester.pump();

    final preview = find.byType(U350LabelPreview);
    expect(tester.getSize(preview), const Size(U350LabelPreview.widthPx, U350LabelPreview.heightPx));

    final arrow = find.byKey(const Key('u350-up-arrow'));
    expect(arrow, findsOneWidget);
    final arrowRect = tester.getRect(arrow);
    expect(arrowRect.left, closeTo(U350LabelLayout.previewPx(U350LabelLayout.arrowLeftMm), 1.5));
    expect(arrowRect.top, closeTo(U350LabelLayout.previewPx(U350LabelLayout.arrowTopMm), 1.5));
    expect(arrowRect.width, closeTo(U350LabelLayout.previewPx(U350LabelLayout.arrowWidthMm), 1.5));
    expect(arrowRect.height, closeTo(U350LabelLayout.previewPx(U350LabelLayout.arrowHeightMm), 1.5));

    final qrBox = find.byKey(const Key('u350-qr-placeholder'));
    expect(qrBox, findsOneWidget);
    final qrRect = tester.getRect(qrBox);
    expect(qrRect.left, closeTo(U350LabelLayout.previewPx(U350LabelLayout.qrLeftMm), 1.5));
    expect(qrRect.top, closeTo(U350LabelLayout.previewPx(U350LabelLayout.qrTopMm), 1.5));

    expect(find.text('KEEP UP RIGHT'), findsOneWidget);
    expect(find.text('MADE IN INDIA'), findsOneWidget);
    expect(find.textContaining('Suprajit Part No'), findsOneWidget);
  });
}
