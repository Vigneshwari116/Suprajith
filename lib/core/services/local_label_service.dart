import 'package:svenska/core/database/local_vehicle_database.dart';
import 'package:svenska/core/services/automotive_date_encoder.dart';
import 'package:svenska/core/services/print_history_refresh_notifier.dart';

class LocalLabelService {
  LocalLabelService(this._refreshNotifier);

  final PrintHistoryRefreshNotifier _refreshNotifier;
  List<Map<String, dynamic>> listMasters() => LocalVehicleDatabase.getAllMasters();

  Map<String, dynamic> saveMaster(Map<String, dynamic> data) {
    final model = data['vehicle_model']?.toString().trim() ?? '';
    final fixedQr = data['fixed_qr_code']?.toString().trim() ?? '';

    if (model.isEmpty) {
      return {'status': 'error', 'message': 'vehicle_model required'};
    }
    if (fixedQr.length != 19) {
      return {
        'status': 'error',
        'message': 'fixed_qr_code must be exactly 19 characters (Received: ${fixedQr.length})',
      };
    }

    LocalVehicleDatabase.saveMaster(data);
    return {'status': 'success', 'message': 'Master saved successfully'};
  }

  Map<String, dynamic> deleteMaster(int id) {
    LocalVehicleDatabase.deleteMaster(id);
    return {'status': 'success', 'message': 'Master deleted'};
  }

  Map<String, dynamic> resetSerial(String model) {
    if (model.trim().isEmpty) {
      return {'status': 'error', 'message': 'Model required'};
    }
    LocalVehicleDatabase.resetSerial(model);
    return {'status': 'success', 'message': 'Serial reset to 0001'};
  }

  Map<String, dynamic> getPrinterConfig() {
    return {
      'status': 'success',
      'printer_50x25': LocalVehicleDatabase.getConfig('printer_50x25') ?? '',
      'printer_100x50': LocalVehicleDatabase.getConfig('printer_100x50') ?? '',
    };
  }

  Map<String, dynamic> setPrinterConfig({
    String? printer50x25,
    String? printer100x50,
  }) {
    if (printer50x25 != null) {
      LocalVehicleDatabase.setConfig('printer_50x25', printer50x25);
    }
    if (printer100x50 != null) {
      LocalVehicleDatabase.setConfig('printer_100x50', printer100x50);
    }
    return {'status': 'success', 'message': 'Printers configured'};
  }

  List<Map<String, dynamic>> getPrintHistory({int limit = 200}) {
    return LocalVehicleDatabase.getAuditLogs(limit: limit);
  }

  List<Map<String, dynamic>> queryPrintHistory({
    int limit = 5000,
    DateTime? fromLocalDate,
    DateTime? toLocalDate,
    String? vehicleModel,
    String? qrContains,
    bool todayOnly = false,
    DateTime? todayReference,
  }) {
    return LocalVehicleDatabase.queryPrintHistory(
      limit: limit,
      fromLocalDate: fromLocalDate,
      toLocalDate: toLocalDate,
      vehicleModel: vehicleModel,
      qrContains: qrContains,
      todayOnly: todayOnly,
      todayReference: todayReference,
    );
  }

  /// Builds 29-character QR payload and increments serial (same rules as vehicle_server).
  Map<String, dynamic> preparePrint({
    required String modelQuery,
    required String labelSize,
    DateTime? printAt,
  }) {
    final modelQueryTrim = modelQuery.trim();
    if (modelQueryTrim.isEmpty) {
      return {'status': 'error', 'message': 'Model query required'};
    }

    final master = LocalVehicleDatabase.findModel(modelQueryTrim);
    if (master == null) {
      return {'status': 'error', 'message': 'Model not found in database'};
    }

    final fixedQr = master['fixed_qr_code']?.toString().trim() ?? '';
    if (fixedQr.length != 19) {
      return {
        'status': 'error',
        'message':
            'Master fixed QR code must be exactly 19 characters (current: ${fixedQr.length}). Please update in Master Management.',
      };
    }

    final activeDate = printAt ?? DateTime.now();
    final dateShiftCode = AutomotiveDateEncoder.encode(activeDate);

    int nextSerial;
    try {
      nextSerial = LocalVehicleDatabase.getNextSerialAndIncrement(
        master['vehicle_model']?.toString() ?? modelQueryTrim,
        dateShiftCode,
      );
    } on StateError catch (e) {
      return {'status': 'error', 'message': e.message};
    }

    final serialStr = nextSerial.toString().padLeft(4, '0');
    final fullPayload = AutomotiveDateEncoder.buildFullQrPayload(
      fixedQr: fixedQr,
      date: activeDate,
      serial: nextSerial,
    );

    if (fullPayload.length != 29) {
      return {
        'status': 'error',
        'message': 'Generated QR must be exactly 29 characters (got ${fullPayload.length})',
      };
    }

    LocalVehicleDatabase.logPrint(
      model: master['vehicle_model']?.toString() ?? '',
      custPart: master['customer_part_no']?.toString() ?? '',
      partNo: master['part_no']?.toString() ?? '',
      mfgDate: master['date_of_mfg']?.toString() ?? '',
      serial: serialStr,
      qrPayload: fullPayload,
      companyLogo: master['company_logo']?.toString() ?? 'none',
    );
    _refreshNotifier.notifyPrintLogged();

    final targetPrinter = labelSize == '100x50'
        ? (LocalVehicleDatabase.getConfig('printer_100x50') ?? 'TSC TTP-244 Plus')
        : (LocalVehicleDatabase.getConfig('printer_50x25') ?? 'TSC TTP-244 Plus');

    return {
      'status': 'success',
      'serial': serialStr,
      'full_payload': fullPayload,
      'target_printer': targetPrinter,
      'model': master['vehicle_model'],
      'customer_part_no': master['customer_part_no'] ?? '',
      'part_no': master['part_no'] ?? '',
      'mfg_date': master['date_of_mfg'] ?? '',
      'company_logo': master['company_logo'] ?? 'none',
    };
  }

  ({int imported, int skipped}) importMastersFromLegacyDb(String filePath) {
    return LocalVehicleDatabase.importMastersFromDatabaseFile(filePath);
  }
}
