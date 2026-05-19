import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onecore_gps_tracker/data/protocols/encode_context.dart';
import 'package:onecore_gps_tracker/data/protocols/osmand_encoder.dart';
import 'package:onecore_gps_tracker/data/protocols/tk103_encoder.dart';
import 'package:onecore_gps_tracker/data/protocols/traccar_framing.dart';
import 'package:onecore_gps_tracker/domain/models/device_protocol.dart';
import 'package:onecore_gps_tracker/domain/models/gps_message.dart';

EncodeContext _ctx(GpsMessage msg, {TransportType t = TransportType.tcp}) =>
    EncodeContext(
      message: msg,
      host: 'adnvycom.servehttp.com',
      port: 5055,
      transport: t,
    );

void main() {
  final msg = GpsMessage(
    deviceId: '123456789012345',
    lat: 19.432608,
    lon: -99.133209,
    timestamp: DateTime.utc(2026, 5, 19, 12, 0, 0),
    speedKmh: 40.0,
    valid: true,
  );

  test('OsmAnd TCP uses HTTP GET for Traccar', () {
    final bytes = OsmandEncoder().encode(_ctx(msg));
    final text = utf8.decode(bytes);
    expect(text.startsWith('GET /?id=123456789012345'), isTrue);
    expect(text.contains('HTTP/1.1'), isTrue);
    expect(text.contains('Host: adnvycom.servehttp.com:5055'), isTrue);
    expect(text.contains('&speed=21.60'), isTrue); // 40 km/h -> nudos
  });

  test('OsmAnd query uses ms timestamp and id param', () {
    final path = TraccarFraming.osmandQueryPath(
      imei: '123456789012345',
      lat: msg.lat,
      lon: msg.lon,
      timestamp: msg.timestamp,
      speedKnots: 21.62,
    );
    expect(path.contains('id=123456789012345'), isTrue);
    expect(
      path.contains('timestamp=${msg.timestamp.millisecondsSinceEpoch}'),
      isTrue,
    );
  });

  test('TK103 Traccar gps103 line', () {
    final bytes = Tk103Encoder().encode(_ctx(msg));
    final text = utf8.decode(bytes);
    expect(text.startsWith('imei:123456789012345,tracker,'), isTrue);
    expect(text.endsWith(';'), isTrue);
    expect(text.contains(',A,'), isTrue);
  });
}
