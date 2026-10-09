import 'package:flutter_test/flutter_test.dart';
import 'package:svenska/core/services/automotive_date_encoder.dart';

void main() {
  const fixed = '0000N822126000020365';

  String fullQr(DateTime date) {
    return AutomotiveDateEncoder.buildFullQrPayload(
      fixedQr20: fixed,
      date: date,
      serial: 1,
    );
  }

  test('encode day/month/year map (18th=J, 23rd=P)', () {
    expect(
      AutomotiveDateEncoder.encode(DateTime(2026, 10, 18)),
      'JA26AA',
    );
    expect(
      AutomotiveDateEncoder.encode(DateTime(2026, 10, 23)),
      'PA26AA',
    );
  });

  test('full QR test vectors with serial 0001', () {
    expect(
      fullQr(DateTime(2026, 9, 25)),
      '0000N822126000020365S926AA0001',
    );
    expect(
      fullQr(DateTime(2026, 10, 8)),
      '0000N8221260000203658A26AA0001',
    );
    expect(
      fullQr(DateTime(2026, 10, 9)),
      '0000N8221260000203659A26AA0001',
    );
    expect(
      fullQr(DateTime(2026, 8, 31)),
      '0000N822126000020365Y826AA0001',
    );
  });

  test('fixed part is 20 chars and full payload is 30 chars', () {
    final payload = fullQr(DateTime(2026, 10, 9));
    expect(fixed.length, 20);
    expect(payload.length, 30);
  });
}
