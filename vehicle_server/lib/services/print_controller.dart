import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import '../database/server_database.dart';
import 'date_encoder_service.dart';

class PrintController {
  static Response jsonRes(Map<String, dynamic> data, {int statusCode = 200}) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );
  }

  static Future<Map<String, dynamic>> parseBody(Request req) async {
    final bodyStr = await req.readAsString();
    if (bodyStr.trim().isEmpty) return {};
    return jsonDecode(bodyStr) as Map<String, dynamic>;
  }

  static Future<Response> handleSaveMaster(Request req) async {
    try {
      final data = await parseBody(req);
      final model = data['vehicle_model']?.toString().trim() ?? '';
      final fixedQr = data['fixed_qr_code']?.toString().trim() ?? '';

      if (model.isEmpty) {
        return jsonRes({'status': 'error', 'message': 'vehicle_model required'}, statusCode: 400);
      }

      if (fixedQr.length != 19) {
        return jsonRes({
          'status': 'error',
          'message': 'fixed_qr_code must be exactly 19 characters (Received: ${fixedQr.length})'
        }, statusCode: 400);
      }

      ServerDatabase.saveMaster(data);
      return jsonRes({'status': 'success', 'message': 'Master saved successfully'});
    } catch (e) {
      return jsonRes({'status': 'error', 'message': e.toString()}, statusCode: 500);
    }
  }

  static Future<Response> handleSetPrinters(Request req) async {
    try {
      final data = await parseBody(req);
      if (data.containsKey('printer_50x25')) {
        ServerDatabase.setConfig('printer_50x25', data['printer_50x25'].toString());
      }
      if (data.containsKey('printer_100x50')) {
        ServerDatabase.setConfig('printer_100x50', data['printer_100x50'].toString());
      }
      return jsonRes({'status': 'success', 'message': 'Printers configured'});
    } catch (e) {
      return jsonRes({'status': 'error', 'message': e.toString()}, statusCode: 500);
    }
  }

  static Future<Response> handlePrint(Request req) async {
    try {
      final payload = await parseBody(req);
      final modelQuery = payload['model']?.toString().trim() ?? '';
      final labelSize = payload['label_size']?.toString().trim() ?? '50x25';
      if (modelQuery.isEmpty) {
        return jsonRes({'status': 'error', 'message': 'Model query required'}, statusCode: 400);
      }

      final master = ServerDatabase.findModel(modelQuery);
      if (master == null) {
        return jsonRes({'status': 'error', 'message': 'Model not found in database'}, statusCode: 404);
      }

      // 1. Fixed QR Code check (exactly 19 characters)
      final fixedQr = master['fixed_qr_code']?.toString().trim() ?? '';
      if (fixedQr.length != 19) {
        return jsonRes({
          'status': 'error',
          'message':
              'Master fixed QR code must be exactly 19 characters (current: ${fixedQr.length}). Please update in Master Management.'
        }, statusCode: 400);
      }

      // QR date segment and label MFG use today's calendar date at print time (ignore master MFG).
      final now = DateTime.now();
      final activeDate = DateTime(now.year, now.month, now.day);
      final mfgDateLabel =
          '${activeDate.day.toString().padLeft(2, '0')}.${activeDate.month.toString().padLeft(2, '0')}.${activeDate.year}';

      // 2. Date code + Month code + 2-digit Year + Constant 'AA' -> e.g. 09.10.2026 = "9A26AA"
      final dateShiftCode = AutomotiveDateEncoder.encode(activeDate);

      // 3. Serial 4 Digits -> e.g. "0001" (max 0999 per model per date code)
      int nextSerial;
      try {
        nextSerial = ServerDatabase.getNextSerialAndIncrement(
          master['vehicle_model']?.toString() ?? modelQuery,
          dateShiftCode,
        );
      } on StateError catch (e) {
        return jsonRes({'status': 'error', 'message': e.message}, statusCode: 400);
      }
      final serialStr = nextSerial.toString().padLeft(4, '0');

      // 4. Final QR Payload: 19-char fixed + date/month/year code + AA + 4-digit serial (29 total)
      final fullPayload = '$fixedQr$dateShiftCode$serialStr';

      final clientIp = req.headers['x-forwarded-for'] ??
          (req.context['shelf.io.connection_info'] as HttpConnectionInfo?)?.remoteAddress.address ??
          'localhost';

      // Audit Log record karein
      ServerDatabase.logPrint(
        model: master['vehicle_model'],
        custPart: master['customer_part_no'] ?? '',
        partNo: master['part_no'] ?? '',
        mfgDate: mfgDateLabel,
        serial: serialStr,
        qrPayload: fullPayload,
        clientIp: clientIp,
        companyLogo: master['company_logo'] ?? 'none',
      );

      final targetPrinter = labelSize == '100x50'
          ? (ServerDatabase.getConfig('printer_100x50') ?? 'TSC TTP-244 Plus')
          : (ServerDatabase.getConfig('printer_50x25') ?? 'TSC TTP-244 Plus');

      return jsonRes({
        'status': 'success',
        'serial': serialStr,
        'full_payload': fullPayload,
        'target_printer': targetPrinter,
        'model': master['vehicle_model'],
        'customer_part_no': master['customer_part_no'] ?? '',
        'part_no': master['part_no'] ?? '',
        'mfg_date': mfgDateLabel,
        'company_logo': master['company_logo'] ?? 'none',
      });
    } catch (e) {
      return jsonRes({'status': 'error', 'message': e.toString()}, statusCode: 500);
    }
  }
}