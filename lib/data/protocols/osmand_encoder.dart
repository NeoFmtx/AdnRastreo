import 'dart:convert';

import '../../domain/models/gps_message.dart';
import 'protocol_encoder.dart';

/// Protocolo OsmAnd: parámetros de posición (no es HTTP).
///
/// Carga enviada por TCP/UDP tal como lo espera Traccar/OsmAnd en socket crudo:
/// `/?id=...&lat=...&lon=...&timestamp=...`
class OsmandEncoder implements ProtocolEncoder {
  @override
  String get protocolName => 'OsmAnd';

  @override
  List<int> encode(GpsMessage message) {
    final buf = StringBuffer('/?id=${Uri.encodeComponent(message.deviceId)}')
      ..write('&lat=${message.lat}')
      ..write('&lon=${message.lon}')
      ..write('&timestamp=${message.timestamp.millisecondsSinceEpoch ~/ 1000}')
      ..write('&valid=${message.valid ? 1 : 0}');
    if (message.speedKmh != null) {
      buf.write('&speed=${message.speedKmh}');
    }
    if (message.bearing != null) {
      buf.write('&bearing=${message.bearing}');
    }
    if (message.accuracyM != null) {
      buf.write('&accuracy=${message.accuracyM}');
    }
    return utf8.encode(buf.toString());
  }
}
