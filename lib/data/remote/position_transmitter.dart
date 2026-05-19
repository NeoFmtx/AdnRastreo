import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/log/deep_log.dart';
import 'osmand_payload.dart';

class TransmitterConfig {
  const TransmitterConfig({
    required this.host,
    required this.httpPort,
    required this.deviceId,
    this.tcpPort = 5055,
    this.udpPort = 5055,
    this.httpEnabled = true,
    this.tcpEnabled = false,
    this.udpEnabled = false,
  });

  final String host;
  final int httpPort;
  final int tcpPort;
  final int udpPort;
  final String deviceId;
  final bool httpEnabled;
  final bool tcpEnabled;
  final bool udpEnabled;

  String get baseUrl => 'http://$host:$httpPort';

  TransmitterConfig copyWith({
    String? host,
    int? httpPort,
    int? tcpPort,
    int? udpPort,
    String? deviceId,
    bool? httpEnabled,
    bool? tcpEnabled,
    bool? udpEnabled,
  }) =>
      TransmitterConfig(
        host: host ?? this.host,
        httpPort: httpPort ?? this.httpPort,
        tcpPort: tcpPort ?? this.tcpPort,
        udpPort: udpPort ?? this.udpPort,
        deviceId: deviceId ?? this.deviceId,
        httpEnabled: httpEnabled ?? this.httpEnabled,
        tcpEnabled: tcpEnabled ?? this.tcpEnabled,
        udpEnabled: udpEnabled ?? this.udpEnabled,
      );
}

/// Envía el mismo paquete OsmAnd por HTTP, TCP y/o UDP según configuración.
class PositionTransmitter {
  PositionTransmitter({
    required TransmitterConfig config,
    Dio? dio,
    DeepLog? log,
  })  : config = config,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            ),
        _log = log ?? DeepLog.instance;

  TransmitterConfig config;
  final Dio _dio;
  final DeepLog _log;

  void updateConfig(TransmitterConfig newConfig) {
    config = newConfig;
  }

  Future<bool> sendPosition({
    required double lat,
    required double lon,
    required DateTime timestamp,
    double? speedKmh,
    double? bearing,
    double? accuracyM,
    bool valid = true,
  }) async {
    final path = OsmandPayload.buildPath(
      deviceId: config.deviceId,
      lat: lat,
      lon: lon,
      timestamp: timestamp,
      speedKmh: speedKmh,
      bearing: bearing,
      accuracyM: accuracyM,
      valid: valid,
    );

    final results = <Future<bool>>[];
    if (config.httpEnabled) {
      results.add(_sendHttp(path));
    }
    if (config.tcpEnabled) {
      results.add(_sendTcp(path));
    }
    if (config.udpEnabled) {
      results.add(_sendUdp(path));
    }

    if (results.isEmpty) {
      _log.w('Ningún canal de transmisión habilitado');
      return false;
    }

    final ok = await Future.wait(results);
    return ok.any((e) => e);
  }

  Future<bool> ping() async {
    if (config.httpEnabled) {
      try {
        final r = await _dio.get<dynamic>(
          config.baseUrl,
          queryParameters: {
            'id': config.deviceId,
            'lat': 0,
            'lon': 0,
            'timestamp': 0,
            'valid': 0,
          },
          options: Options(validateStatus: (_) => true),
        );
        if (r.statusCode != null) return true;
      } catch (_) {}
    }
    if (config.tcpEnabled) {
      try {
        final socket = await Socket.connect(
          config.host,
          config.tcpPort,
          timeout: const Duration(seconds: 8),
        );
        await socket.close();
        return true;
      } catch (_) {}
    }
    return false;
  }

  Future<bool> _sendHttp(String path) async {
    try {
      final response = await _dio.get<dynamic>('${config.baseUrl}$path');
      final ok = response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
      _log.d('HTTP ${ok ? "OK" : "FAIL"} $path');
      return ok;
    } catch (e) {
      _log.w('HTTP error: $e');
      return false;
    }
  }

  Future<bool> _sendTcp(String path) async {
    try {
      final socket = await Socket.connect(
        config.host,
        config.tcpPort,
        timeout: const Duration(seconds: 15),
      );
      final request = OsmandPayload.buildHttpGet(
        host: config.host,
        path: path,
      );
      socket.add(utf8.encode(request));
      await socket.flush();
      await socket.close().timeout(const Duration(seconds: 5));
      _log.d('TCP OK $path');
      return true;
    } catch (e) {
      _log.w('TCP error: $e');
      return false;
    }
  }

  Future<bool> _sendUdp(String path) async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(
        utf8.encode(path),
        InternetAddress.tryParse(config.host) ??
            (await InternetAddress.lookup(config.host)).first,
        config.udpPort,
      );
      socket.close();
      _log.d('UDP OK $path');
      return true;
    } catch (e) {
      _log.w('UDP error: $e');
      return false;
    }
  }
}
