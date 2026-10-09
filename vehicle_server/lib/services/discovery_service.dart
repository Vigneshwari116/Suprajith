import 'dart:convert';
import 'dart:io';

class DiscoveryService {
  static RawDatagramSocket? _socket;
  static const int discoveryPort = 8888;

  static Future<void> start(int serverHttpPort) async {
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
        reusePort: false,
      );
      _socket?.broadcastEnabled = true;

      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram == null) return;

          final message = utf8.decode(datagram.data).trim();

          if (message == 'SVENSKA_DISCOVERY_PING') {
            final reply = utf8.encode('SVENSKA_SERVER_ACK:$serverHttpPort');
            _socket?.send(reply, datagram.address, datagram.port);
            print('[DISCOVERY] Responded to client: ${datagram.address.address}:${datagram.port}');
          }
        }
      });
    } catch (e) {
      print('[DISCOVERY ERROR] $e');
    }
  }

  static void stop() {
    _socket?.close();
    _socket = null;
  }
}