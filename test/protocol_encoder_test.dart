import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onecore_gps_tracker/data/protocols/osmand_encoder.dart';
import 'package:onecore_gps_tracker/data/protocols/tk103_encoder.dart';
import 'package:onecore_gps_tracker/domain/models/gps_message.dart';

void main() {
  final msg = GpsMessage(
    deviceId: '123456789012345',
    lat: 19.4326,
    lon: -99.1332,
    timestamp: DateTime.utc(2026, 5, 19, 12, 0, 0),
    speedKmh: 40.5,
    valid: true,
  );

  test('OsmAnd payload is not HTTP', () {
    final bytes = OsmandEncoder().encode(msg);
    final text = utf8.decode(bytes);
    expect(text.startsWith('/?id='), isTrue);
    expect(text.contains('GET '), isFalse);
    expect(text.contains('HTTP'), isFalse);
  });

  test('TK103 payload is text line', () {
    final bytes = Tk103Encoder().encode(msg);
    final text = utf8.decode(bytes);
    expect(text.startsWith('imei:'), isTrue);
    expect(text.endsWith(';'), isTrue);
  });
}
