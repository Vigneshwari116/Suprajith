import 'package:flutter_test/flutter_test.dart';
import 'package:svenska/core/constants/label_config.dart';

void main() {
  group('showKeepUpExtras', () {
    test('U350 exact match', () {
      expect(showKeepUpExtras('U350'), isTrue);
      expect(showKeepUpExtras(' u350 '), isTrue);
    });

    test('other models are false', () {
      expect(showKeepUpExtras('U349C SPORT'), isFalse);
      expect(showKeepUpExtras('U279'), isFalse);
      expect(showKeepUpExtras('U261 SPORT'), isFalse);
    });
  });
}
