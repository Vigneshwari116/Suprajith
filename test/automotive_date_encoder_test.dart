import 'package:flutter_test/flutter_test.dart';
import 'package:svenska/core/services/automotive_date_encoder.dart';

void main() {
  const fixed = '0000N82212600020365';

  String fullQr(DateTime date, {int serial = 1}) {
    return AutomotiveDateEncoder.buildFullQrPayload(
      fixedQr: fixed,
      date: date,
      serial: serial,
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
      '0000N82212600020365S926AA0001',
    );
    expect(
      fullQr(DateTime(2026, 10, 8)),
      '0000N822126000203658A26AA0001',
    );
    expect(
      fullQr(DateTime(2026, 10, 9)),
      '0000N822126000203659A26AA0001',
    );
    expect(
      fullQr(DateTime(2026, 8, 31)),
      '0000N82212600020365Y826AA0001',
    );
  });

  test('full QR with serial 0451 on 21.08.2026', () {
    expect(
      fullQr(DateTime(2026, 8, 21), serial: 451),
      '0000N82212600020365M826AA0451',
    );
  });

  test('fixed part is 19 chars and every full payload is 29 chars', () {
    expect(fixed.length, 19);
    final samples = [
      fullQr(DateTime(2026, 9, 25)),
      fullQr(DateTime(2026, 10, 8)),
      fullQr(DateTime(2026, 10, 9)),
      fullQr(DateTime(2026, 8, 31)),
      fullQr(DateTime(2026, 8, 21), serial: 451),
    ];
    for (final payload in samples) {
      expect(payload.length, 29);
    }
  });
}
