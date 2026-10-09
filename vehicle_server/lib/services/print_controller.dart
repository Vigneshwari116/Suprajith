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

      // Server-side validation: fixed part is 19 or 20 characters (depends on the part)
      if (fixedQr.length != 19 && fixedQr.length != 20) {
        return jsonRes({
          'status': 'error',
          'message': 'fixed_qr_code must be 19 or 20 characters (Received: ${fixedQr.length})'
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
      final dateStr = payload['date']?.toString().trim() ?? '';

      if (modelQuery.isEmpty) {
        return jsonRes({'status': 'error', 'message': 'Model query required'}, statusCode: 400);
      }

      final master = ServerDatabase.findModel(modelQuery);
      if (master == null) {
        return jsonRes({'status': 'error', 'message': 'Model not found in database'}, statusCode: 404);
      }

      // 1. Fixed QR Code check (19 or 20 characters)
      final fixedQr = master['fixed_qr_code']?.toString().trim() ?? '';
      if (fixedQr.length != 19 && fixedQr.length != 20) {
        return jsonRes({
          'status': 'error',
          'message': 'Master fixed_qr_code must be 19 or 20 characters. Please update in Master Management.'
        }, statusCode: 400);
      }

      DateTime activeDate = DateTime.now();
      if (dateStr.isNotEmpty) {
        try {
          final parts = dateStr.split('.');
          if (parts.length == 3) {
            activeDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        } catch (_) {}
      }

      // 2. Date code + Month code + 2-digit Year + Constant 'AA' -> e.g. 08.10.2026 = "8A26AA"
      final dateShiftCode = AutomotiveDateEncoder.encode(activeDate);

      // 3. Serial 4 Digits -> e.g. "0001"
      final nextSerial = ServerDatabase.getNextSerialAndIncrement(master['vehicle_model'], dateShiftCode);
      final serialStr = nextSerial.toString().padLeft(4, '0');

      // 4. Final QR Payload: fixed part (19/20) + date/month/year code + AA + 4-digit serial
      final fullPayload = '$fixedQr$dateShiftCode$serialStr';

      final clientIp = req.headers['x-forwarded-for'] ??
          (req.context['shelf.io.connection_info'] as HttpConnectionInfo?)?.remoteAddress.address ??
          'localhost';

      // Audit Log record karein
      ServerDatabase.logPrint(
        model: master['vehicle_model'],
        custPart: master['customer_part_no'] ?? '',
        partNo: master['part_no'] ?? '',
        mfgDate: master['date_of_mfg'] ?? dateStr,
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
        'mfg_date': master['date_of_mfg'] ?? dateStr,
        'company_logo': master['company_logo'] ?? 'none',
      });
    } catch (e) {
      return jsonRes({'status': 'error', 'message': e.toString()}, statusCode: 500);
    }
  }
}