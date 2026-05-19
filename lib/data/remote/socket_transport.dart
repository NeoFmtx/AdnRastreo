import 'dart:convert';
import 'dart:io';

import '../../domain/models/device_protocol.dart';
import '../../core/log/deep_log.dart';

/// Envío por socket TCP o UDP (sin HTTP).
class SocketTransport {
  SocketTransport({DeepLog? log}) : _log = log ?? DeepLog.instance;

  final DeepLog _log;

  Future<bool> send({
    required List<int> payload,
    required String host,
    required int port,
    required TransportType transport,
  }) async {
    switch (transport) {
      case TransportType.tcp:
        return _sendTcp(payload, host, port);
      case TransportType.udp:
        return _sendUdp(payload, host, port);
    }
  }

  Future<bool> ping({
    required String host,
    required int port,
    required TransportType transport,
  }) async {
    try {
      switch (transport) {
        case TransportType.tcp:
          final s = await Socket.connect(
            host,
            port,
            timeout: const Duration(seconds: 8),
          );
          await s.close();
          return true;
        case TransportType.udp:
          final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
          socket.close();
          return true;
      }
    } catch (e) {
      _log.d('Ping $transport falló: $e');
      return false;
    }
  }

  Future<bool> _sendTcp(List<int> payload, String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 15),
      );
      socket.add(payload);
      await socket.flush();
      await socket.close().timeout(const Duration(seconds: 5));
      _log.d('TCP OK ${payload.length} bytes: ${_preview(payload)}');
      return true;
    } catch (e) {
      _log.w('TCP error: $e');
      return false;
    }
  }

  Future<bool> _sendUdp(List<int> payload, String host, int port) async {
    try {
      final address = InternetAddress.tryParse(host) ??
          (await InternetAddress.lookup(host)).first;
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(payload, address, port);
      socket.close();
      _log.d('UDP OK ${payload.length} bytes: ${_preview(payload)}');
      return true;
    } catch (e) {
      _log.w('UDP error: $e');
      return false;
    }
  }

  String _preview(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    return text.length > 80 ? '${text.substring(0, 80)}...' : text;
  }
}
