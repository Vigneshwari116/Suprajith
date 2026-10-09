import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/server_database.dart';
import '../services/print_controller.dart';

Router configureRoutes() {
  final router = Router();

  // Handshake
  router.get('/api/ping', (Request req) {
    return PrintController.jsonRes({
      'status': 'online',
      'service': 'Svenska Print Server',
      'server_time': DateTime.now().toIso8601String(),
    });
  });

  // Masters
  router.get('/api/masters', (Request req) {
    final list = ServerDatabase.getAllMasters();
    return PrintController.jsonRes({'status': 'success', 'data': list});
  });

  router.post('/api/masters', PrintController.handleSaveMaster);

  // Delete Master by ID
  router.delete('/api/masters/<id>', (Request req, String id) {
    final intId = int.tryParse(id);
    if (intId != null) {
      ServerDatabase.deleteMaster(intId);
      return PrintController.jsonRes({'status': 'success', 'message': 'Master deleted'});
    }
    return PrintController.jsonRes({'status': 'error', 'message': 'Invalid ID'}, statusCode: 400);
  });

  // Reset Serial
  router.post('/api/serial/reset', (Request req) async {
    final payload = await PrintController.parseBody(req);
    final model = payload['model']?.toString() ?? '';
    if (model.isNotEmpty) {
      ServerDatabase.resetSerial(model);
      return PrintController.jsonRes({'status': 'success', 'message': 'Serial reset to 0001'});
    }
    return PrintController.jsonRes({'status': 'error', 'message': 'Model required'}, statusCode: 400);
  });

  // Print execution (Supports 50x25 & 100x50 via label_size field)
  router.post('/api/print', PrintController.handlePrint);

  // History & Audit
  router.get('/api/history', (Request req) {
    final list = ServerDatabase.getAuditLogs();
    return PrintController.jsonRes({'status': 'success', 'data': list});
  });

  // 1. Dual Printer Configuration: GET (Fetch both mapped printers)
  router.get('/api/printer', (Request req) {
    return PrintController.jsonRes({
      'status': 'success',
      'printer_50x25': ServerDatabase.getConfig('printer_50x25') ?? '',
      'printer_100x50': ServerDatabase.getConfig('printer_100x50') ?? '',
    });
  });

  // 2. Dual Printer Configuration: POST (Save both mapped printers)
  router.post('/api/printer', PrintController.handleSetPrinters);

  return router;
}