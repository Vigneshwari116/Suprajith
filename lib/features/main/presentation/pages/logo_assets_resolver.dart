import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

class LogoAssetResolver {
  static Future<pw.MemoryImage?> getLogoImage(String? logoKey) async {
    if (logoKey == null || logoKey.isEmpty || logoKey == 'none') return null;

    String path;
    switch (logoKey.toLowerCase()) {
      case 'suprajit':
        path = 'assets/logos/suprajit.png';
        break;
      case 'birla':
        path = 'assets/logos/birla.png';
        break;
      case 'sansera':
        path = 'assets/logos/sansera.png';
        break;
      case 'dhoot':
        path = 'assets/logos/dhoot.png';
        break;
      default:
        return null;
    }

    try {
      final byteData = await rootBundle.load(path);
      return pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }
}