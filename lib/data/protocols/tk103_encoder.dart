import 'dart:convert';

import 'package:intl/intl.dart';

import '../../domain/models/gps_message.dart';
import 'protocol_encoder.dart';

/// TK103 / Suntech texto: `imei,tracker,fecha,hora,lat,lon,vel,...`
class Tk103Encoder implements ProtocolEncoder {
  @override
  String get protocolName => 'TK103';

  static final _dateFmt = DateFormat('ddMMyy');
  static final _timeFmt = DateFormat('HHmmss');

  @override
  List<int> encode(GpsMessage message) {
    final latHem = message.lat >= 0 ? 'N' : 'S';
    final lonHem = message.lon >= 0 ? 'E' : 'W';
    final lat = (message.lat.abs() * 100000).round() / 100000.0;
    final lon = (message.lon.abs() * 100000).round() / 100000.0;
    final speed = (message.speedKmh ?? 0).round();
    final line =
        'imei:${message.deviceId},tracker,${_dateFmt.format(message.timestamp)},'
        '${_timeFmt.format(message.timestamp)},'
        'F,$lat,$latHem,$lon,$lonHem,$speed,0;';
    return utf8.encode(line);
  }
}
