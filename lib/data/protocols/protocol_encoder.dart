import '../../domain/models/gps_message.dart';

/// Codifica un [GpsMessage] al formato binario/texto del fabricante.
abstract class ProtocolEncoder {
  String get protocolName;

  /// Carga útil lista para enviar por TCP o UDP (sin HTTP).
  List<int> encode(GpsMessage message);
}
