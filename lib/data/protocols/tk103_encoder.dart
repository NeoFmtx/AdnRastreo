import 'dart:convert';

import 'package:intl/intl.dart';

import '../../domain/models/device_imei.dart';
import 'encode_context.dart';
import 'protocol_encoder.dart';

/// GPS103 / TK103 — formato texto Traccar (puerto 5001 por defecto).
///
/// Ejemplo: `imei:359710041961583,tracker,130305152602,,F,130305,A,5546.0625,N,03737.0900,E,0.00,,0,0,0.00,0,0;`
class Tk103Encoder implements ProtocolEncoder {
  @override
  String get protocolName => 'TK103';

  static final _localDt = DateFormat('yyMMddHHmmss');
  static final _utcTime = DateFormat('HHmmss');

  @override
  List<int> encode(EncodeContext context) {
    final m = context.message;
    final imei = DeviceImei.normalize(m.deviceId);
    final localDt = _localDt.format(m.timestamp.toLocal());
    final utc = _utcTime.format(m.timestamp.toUtc());
    final lat = _toDm(m.lat, isLat: true);
    final lon = _toDm(m.lon, isLat: false);
    final speed = (m.speedKmh ?? 0).toStringAsFixed(2);

    final line =
        'imei:$imei,tracker,$localDt,,F,$utc,A,$lat,$lon,$speed,,0,0,0.00,0,0;';
    return utf8.encode(line);
  }

  /// DDMM.MMMM / DDDMM.MMMM con hemisferio (Traccar Gps103ProtocolDecoder).
  static String _toDm(double decimal, {required bool isLat}) {
    final hem = isLat
        ? (decimal >= 0 ? 'N' : 'S')
        : (decimal >= 0 ? 'E' : 'W');
    final abs = decimal.abs();
    final degrees = abs.floor();
    final minutes = (abs - degrees) * 60;
    if (isLat) {
      return '${degrees.toString().padLeft(2, '0')}'
          '${minutes.toStringAsFixed(4).padLeft(7, '0')},$hem';
    }
    return '${degrees.toString().padLeft(3, '0')}'
        '${minutes.toStringAsFixed(4).padLeft(7, '0')},$hem';
  }
}
