import '../../domain/models/device_protocol.dart';
import '../../domain/models/gps_message.dart';

/// Contexto de codificación: protocolo + transporte + servidor.
class EncodeContext {
  const EncodeContext({
    required this.message,
    required this.host,
    required this.port,
    required this.transport,
  });

  final GpsMessage message;
  final String host;
  final int port;
  final TransportType transport;
}
