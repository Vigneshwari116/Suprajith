import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:svenska_server/database/server_database.dart';
import 'package:svenska_server/routes/api_routes.dart';
import 'package:svenska_server/services/discovery_service.dart';

void main() async {
  ServerDatabase.init();

  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final pipeline = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(configureRoutes());

  final server = await shelf_io.serve(pipeline, InternetAddress.anyIPv4, port);

  // UDP Auto-Discovery Responder start karein
  await DiscoveryService.start(port);

  String localIp = '127.0.0.1';
  for (var interface in await NetworkInterface.list()) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
        localIp = addr.address;
        break;
      }
    }
  }

  print('================================================================');
  print(' SVENSKA AUTOMOTIVE — INDUSTRIAL BACKEND PRINT SERVER');
  print('================================================================');
  print(' [STATUS]     Running on: http://${server.address.host}:${server.port}');
  print(' [LOCAL IP]   Connect Mobile/Clients to: http://$localIp:$port');
  print(' [DISCOVERY]  UDP Auto-Discovery running on Port 8888');
  print(' [PRINTER]    Configured: ${ServerDatabase.getConfig('printer_name') ?? "[Default OS Dialog]"}');
  print('================================================================');
}