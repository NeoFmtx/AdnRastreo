import 'package:flutter_test/flutter_test.dart';
import 'package:onecore_gps_tracker/core/geo/geo_engine.dart';
import 'package:onecore_gps_tracker/domain/models/raw_gps_point.dart';

void main() {
  test('geo engine rejects poor accuracy', () {
    final engine = GeoEngine();
    final result = engine.process(
      RawGpsPoint(
        timestamp: DateTime.now(),
        lat: 19.43,
        lon: -99.13,
        accuracyM: 200,
      ),
    );
    expect(result.accepted, isFalse);
  });
}
