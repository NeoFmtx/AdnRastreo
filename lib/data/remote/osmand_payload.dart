/// Construye la ruta/query OsmAnd compartida por HTTP, TCP y UDP.
class OsmandPayload {
  static String buildPath({
    required String deviceId,
    required double lat,
    required double lon,
    required DateTime timestamp,
    double? speedKmh,
    double? bearing,
    double? accuracyM,
    bool valid = true,
  }) {
    final buf = StringBuffer('/?id=${Uri.encodeComponent(deviceId)}')
      ..write('&lat=$lat&lon=$lon')
      ..write('&timestamp=${timestamp.millisecondsSinceEpoch ~/ 1000}')
      ..write('&valid=${valid ? 1 : 0}');
    if (speedKmh != null) buf.write('&speed=$speedKmh');
    if (bearing != null) buf.write('&bearing=$bearing');
    if (accuracyM != null) buf.write('&accuracy=$accuracyM');
    return buf.toString();
  }

  static String buildHttpGet({
    required String host,
    required String path,
  }) =>
      'GET $path HTTP/1.1\r\n'
      'Host: $host\r\n'
      'Connection: close\r\n'
      '\r\n';
}
