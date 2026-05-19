import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/models/device_protocol.dart';
import '../../core/log/deep_log.dart';

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
      _log.d('Ping $transport: $e');
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
      final response = await _sendAndReadResponse(socket, payload);
      await socket.close();

      final preview = utf8.decode(payload, allowMalformed: true);
      final short =
          preview.length > 120 ? '${preview.substring(0, 120)}...' : preview;
      _log.d('TCP >> $short');

      if (response != null) {
        _log.d('TCP << $response');
        if (response.contains('400')) {
          _log.w(
            'Traccar 400: revisa que el IMEI exista como "Identificador" del dispositivo',
          );
          return false;
        }
        if (response.contains('200')) return true;
      }
      return true;
    } catch (e) {
      _log.w('TCP error: $e');
      return false;
    }
  }

  Future<String?> _sendAndReadResponse(Socket socket, List<int> payload) async {
    final buffer = <int>[];
    final sub = socket.listen((data) => buffer.addAll(data));
    socket.add(payload);
    await socket.flush();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await sub.cancel();
    if (buffer.isEmpty) return null;
    final text = utf8.decode(buffer, allowMalformed: true);
    return text.split('\r\n').first;
  }

  Future<bool> _sendUdp(List<int> payload, String host, int port) async {
    try {
      final address = InternetAddress.tryParse(host) ??
          (await InternetAddress.lookup(host)).first;
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(payload, address, port);
      socket.close();
      _log.d('UDP OK ${payload.length} bytes');
      return true;
    } catch (e) {
      _log.w('UDP error: $e');
      return false;
    }
  }
}
