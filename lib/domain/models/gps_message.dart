/// Datos de posición normalizados para cualquier protocolo industrial.
class GpsMessage {
  const GpsMessage({
    required this.deviceId,
    required this.lat,
    required this.lon,
    required this.timestamp,
    this.speedKmh,
    this.bearing,
    this.accuracyM,
    this.valid = true,
  });

  final String deviceId;
  final double lat;
  final double lon;
  final DateTime timestamp;
  final double? speedKmh;
  final double? bearing;
  final double? accuracyM;
  final bool valid;
}
