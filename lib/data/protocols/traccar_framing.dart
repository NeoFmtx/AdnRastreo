import 'dart:convert';

import '../../domain/models/device_protocol.dart';
import 'encode_context.dart';

/// Traccar OsmAnd usa decodificador HTTP: en TCP el paquete debe ser una petición HTTP.
class TraccarFraming {
  /// Query OsmAnd sin prefijo HTTP (path + query).
  static String osmandQueryPath({
    required String imei,
    required double lat,
    required double lon,
    required DateTime timestamp,
    double? speedKnots,
    double? bearing,
    double? accuracyM,
    bool valid = true,
  }) {
    final tsMs = timestamp.millisecondsSinceEpoch;
    final buf = StringBuffer('/?id=$imei')
      ..write('&lat=${_fmtCoord(lat)}')
      ..write('&lon=${_fmtCoord(lon)}')
      ..write('&timestamp=$tsMs')
      ..write('&valid=${valid ? 1 : 0}');
    if (speedKnots != null && speedKnots >= 0) {
      buf.write('&speed=${speedKnots.toStringAsFixed(2)}');
    }
    if (bearing != null && bearing >= 0) {
      buf.write('&bearing=${bearing.toStringAsFixed(1)}');
    }
    if (accuracyM != null && accuracyM >= 0) {
      buf.write('&accuracy=${accuracyM.toStringAsFixed(1)}');
    }
    return buf.toString();
  }

  /// Petición HTTP GET completa (Traccar OsmAnd sobre TCP).
  static String httpGetRequest({
    required String host,
    required int port,
    required String queryPath,
  }) =>
      'GET $queryPath HTTP/1.1\r\n'
      'Host: $host:$port\r\n'
      'User-Agent: AdnRastreo/1.0\r\n'
      'Connection: close\r\n'
      '\r\n';

  static List<int> encodeOsmandForTraccar(EncodeContext ctx) {
    final m = ctx.message;
    final imei = m.deviceId;
    final speedKn = m.speedKmh != null ? m.speedKmh! / 1.852 : null;
    final path = osmandQueryPath(
      imei: imei,
      lat: m.lat,
      lon: m.lon,
      timestamp: m.timestamp,
      speedKnots: speedKn,
      bearing: m.bearing,
      accuracyM: m.accuracyM,
      valid: m.valid,
    );

    final body = switch (ctx.transport) {
      TransportType.tcp =>
        httpGetRequest(host: ctx.host, port: ctx.port, queryPath: path),
      // UDP: mismo contenido HTTP en datagrama (Traccar oficial = TCP; algunos proxies UDP)
      TransportType.udp =>
        httpGetRequest(host: ctx.host, port: ctx.port, queryPath: path),
    };
    return utf8.encode(body);
  }

  static String _fmtCoord(double v) {
    final s = v.toStringAsFixed(6);
    return s.contains('.') ? s : '$s.0';
  }
}
