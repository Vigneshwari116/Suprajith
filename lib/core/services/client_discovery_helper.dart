import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

class ClientDiscoveryHelper {
  static const int discoveryPort = 8888;
  static const String pingMessage = 'SVENSKA_DISCOVERY_PING';
  static const String ackPrefix = 'SVENSKA_SERVER_ACK:';

  static Future<String?> findServer({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    RawDatagramSocket? socket;
    final completer = Completer<String?>();

    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket?.receive();
          if (datagram == null) return;

          final responseStr = utf8.decode(datagram.data).trim();
          log('📡 UDP Packet Received from ${datagram.address.address}: $responseStr');

          // Check if the reply is our server's handshake
          if (responseStr.startsWith(ackPrefix)) {
            final portStr = responseStr.substring(ackPrefix.length).trim();
            final port = portStr.isNotEmpty ? portStr : '8080';
            final serverIp = datagram.address.address;

            final discoveredUrl = 'http://$serverIp:$port';
            log('✅ Found Svenska Server at: $discoveredUrl');

            if (!completer.isCompleted) {
              completer.complete(discoveredUrl);
            }
          }
        }
      });

      final pingBytes = utf8.encode(pingMessage);

      // 1. General broadcast across standard subnet
      socket.send(
        pingBytes,
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );

      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLoopback: false,
        );

        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            final segments = addr.address.split('.');
            if (segments.length == 4) {
              final subnetBroadcastIp =
                  '${segments[0]}.${segments[1]}.${segments[2]}.255';
              socket.send(
                pingBytes,
                InternetAddress(subnetBroadcastIp),
                discoveryPort,
              );
            }
          }
        }
      } catch (e) {
        log('⚠️ Interface subnet broadcast scan error: $e');
      }

      // Timeout watchdog
      Timer(timeout, () {
        if (!completer.isCompleted) {
          log('⏱️ UDP Server discovery timed out.');
          completer.complete(null);
        }
      });

      final result = await completer.future;
      return result;
    } catch (e) {
      log('❌ UDP Client discovery failed: $e');
      return null;
    } finally {
      socket?.close();
    }
  }
}